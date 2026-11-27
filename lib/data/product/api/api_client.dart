import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode;

import '../../../features/account/session_controller.dart';
import '../models.dart';

class ApiCancellation {
  bool cancelled = false;
  final _callbacks = <void Function()>[];
  void listen(void Function() callback) {
    if (cancelled) {
      callback();
    } else {
      _callbacks.add(callback);
    }
  }

  void cancel() {
    if (cancelled) return;
    cancelled = true;
    for (final callback in _callbacks) {
      callback();
    }
    _callbacks.clear();
  }
}

class ApiBody {
  const ApiBody(this.type, this.length, this.open);
  factory ApiBody.json(Object value) {
    final bytes = utf8.encode(jsonEncode(value));
    return ApiBody('application/json', bytes.length, () => Stream.value(bytes));
  }
  final String type;
  final int length;
  final Stream<List<int>> Function() open;
}

class ApiResponse {
  const ApiResponse(this.status, this.headers, this.body, this.close);
  final int status;
  final Map<String, String> headers;
  final Stream<List<int>> body;
  final void Function() close;
}

abstract interface class ApiTransport {
  Future<ApiResponse> send(String method, Uri uri, Map<String, String> headers, ApiBody? body, ApiCancellation cancel);
}

class NativeApiTransport implements ApiTransport {
  @override
  Future<ApiResponse> send(
    String method,
    Uri uri,
    Map<String, String> headers,
    ApiBody? body,
    ApiCancellation cancel,
  ) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    cancel.listen(() => client.close(force: true));
    try {
      if (cancel.cancelled) throw const ProductFailure(FailureKind.uncertain);
      final request = await client.openUrl(method, uri);
      // Credentials and private data must never follow a redirect.
      request.followRedirects = false;
      headers.forEach(request.headers.set);
      if (body != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, body.type);
        request.contentLength = body.length;
        await request.addStream(body.open());
      }
      final response = await request.close();
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) => responseHeaders[name.toLowerCase()] = values.join(','));
      return ApiResponse(response.statusCode, responseHeaders, response, () => client.close(force: true));
    } catch (_) {
      client.close(force: true);
      rethrow;
    }
  }
}

/// Native JSON/Bearer transport. The only automatic replay follows a rejected
/// protected 401, once, after the session coordinator's single-flight refresh.
class ApiClient {
  ApiClient(this.origin, {ApiTransport? transport, this.timeout = const Duration(seconds: 180)})
    : transport = transport ?? NativeApiTransport() {
    if (origin.scheme != 'https' ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw ArgumentError('FIKRA_API_URL must be an HTTPS origin');
    }
  }
  final Uri origin;
  final ApiTransport transport;
  final Duration timeout;
  SessionController? session;

  bool _valid(SessionController coordinator, String accountId, int epoch) =>
      identical(session, coordinator) &&
      coordinator.epoch == epoch &&
      coordinator.stage == SessionStage.authenticated &&
      coordinator.account?.id == accountId;

  Future<ApiResponse> open(
    String method,
    String path, {
    String? accountId,
    String? accessToken,
    Object? json,
    ApiBody? body,
    Map<String, String> headers = const {},
    String accept = 'application/json',
    ApiCancellation? cancellation,
  }) async {
    final cancel = cancellation ?? ApiCancellation();
    final coordinator = session;
    final epoch = coordinator?.epoch;
    if (accountId != null && (coordinator == null || !_valid(coordinator, accountId, epoch!))) {
      throw const ProductFailure(FailureKind.unauthorized);
    }
    final payload = body ?? (json == null ? null : ApiBody.json(json));
    for (var attempt = 0; attempt < 2; attempt++) {
      if (cancel.cancelled) throw const ProductFailure(FailureKind.uncertain);
      if (accountId != null && !_valid(coordinator!, accountId, epoch!)) {
        throw const ProductFailure(FailureKind.unauthorized);
      }
      final token = accountId == null ? accessToken : coordinator!.tokens?.access;
      if (accountId != null && token == null) throw const ProductFailure(FailureKind.unauthorized);
      ApiResponse response;
      _diagnose(method, path, 'started');
      try {
        response = await transport
            .send(
              method,
              origin.resolve(path),
              {'Accept': accept, if (token != null) 'Authorization': 'Bearer $token', ...headers},
              payload,
              cancel,
            )
            .timeout(
              timeout,
              onTimeout: () {
                cancel.cancel();
                throw const ProductFailure(FailureKind.uncertain, cause: FailureCause.timeout);
              },
            );
      } on ProductFailure catch (error) {
        _diagnose(method, path, error.cause?.name ?? error.kind.name);
        rethrow;
      } catch (error) {
        final failure = _transportFailure(error);
        _diagnose(method, path, failure.cause?.name ?? failure.kind.name);
        throw failure;
      }
      _diagnose(method, path, 'HTTP ${response.status}');
      if (accountId != null && !_valid(coordinator!, accountId, epoch!)) {
        response.close();
        throw const ProductFailure(FailureKind.unauthorized);
      }
      if (response.status == 401 && accountId != null && attempt == 0) {
        response.close();
        await coordinator!.refreshAfterUnauthorized(token!);
        continue;
      }
      if (response.status == 401 && accountId != null) {
        response.close();
        await coordinator!.expire();
        throw const ProductFailure(FailureKind.unauthorized);
      }
      return response;
    }
    throw const ProductFailure(FailureKind.unauthorized);
  }

  Future<dynamic> request(
    String method,
    String path, {
    String? accountId,
    String? accessToken,
    Object? json,
    ApiBody? body,
    Map<String, String> headers = const {},
  }) async {
    final cancel = ApiCancellation();
    ApiResponse? response;
    final coordinator = session;
    final epoch = coordinator?.epoch;
    try {
      response = await open(
        method,
        path,
        accountId: accountId,
        accessToken: accessToken,
        json: json,
        body: body,
        headers: headers,
        cancellation: cancel,
      );
      // A body can contain private echoed validation input. Never log it.
      final bytes = await response.body.timeout(timeout).fold<List<int>>(<int>[], (bytes, chunk) {
        if (bytes.length + chunk.length > 16 * 1024 * 1024) throw const ProductFailure(FailureKind.unavailable);
        bytes.addAll(chunk);
        return bytes;
      });
      if (accountId != null && !_valid(coordinator!, accountId, epoch!)) {
        throw const ProductFailure(FailureKind.unauthorized);
      }
      dynamic value;
      if (bytes.isNotEmpty) {
        try {
          value = jsonDecode(utf8.decode(bytes));
        } catch (_) {
          if (response.status >= 200 && response.status < 300) {
            throw const ProductFailure(FailureKind.unavailable, cause: FailureCause.invalidResponse);
          }
        }
      }
      if (response.status < 200 || response.status >= 300) {
        throw failure(response.status, response.headers, value);
      }
      return value;
    } on ProductFailure {
      rethrow;
    } catch (error) {
      throw _transportFailure(error);
    } finally {
      response?.close();
      cancel.cancel();
    }
  }

  static ProductFailure _transportFailure(Object error) => ProductFailure(
    FailureKind.uncertain,
    cause: switch (error) {
      TimeoutException() => FailureCause.timeout,
      HandshakeException() || TlsException() => FailureCause.secureConnection,
      SocketException() || HttpException() => FailureCause.connection,
      _ => null,
    },
  );

  // Profile diagnostics contain only a fixed auth route and a status/category.
  // Never include query strings, bodies, headers, exception text or credentials.
  static void _diagnose(String method, String path, String outcome) {
    if (!kReleaseMode && RegExp(r'^/v1/auth/[a-z/-]+$').hasMatch(path)) {
      debugPrint('FIKRAH_AUTH $method $path $outcome');
    }
  }

  static ProductFailure failure(int status, Map<String, String> headers, dynamic payload) {
    String? field;
    if (payload is Map && payload['detail'] is List) {
      for (final item in payload['detail'] as List) {
        if (item is Map && item['loc'] is List && (item['loc'] as List).length > 1) {
          final value = (item['loc'] as List).last;
          if (const [
            'email',
            'password',
            'new_password',
            'code',
            'token',
            'content',
            'title',
            'name',
          ].contains(value)) {
            field = value as String;
          }
        }
      }
    }
    Duration? retry;
    final raw = headers['retry-after'];
    if (raw != null) {
      final seconds = int.tryParse(raw);
      if (seconds != null) {
        retry = Duration(seconds: seconds.clamp(0, 86400));
      } else {
        try {
          final d = HttpDate.parse(raw).difference(DateTime.now());
          retry = d.isNegative ? Duration.zero : d;
        } catch (_) {}
      }
    }
    return ProductFailure(
      switch (status) {
        400 || 422 => FailureKind.validation,
        401 => FailureKind.unauthorized,
        403 => FailureKind.unverified,
        404 => FailureKind.notFound,
        409 => FailureKind.conflict,
        410 => FailureKind.gone,
        413 => FailureKind.tooLarge,
        415 => FailureKind.mediaType,
        429 => FailureKind.quota,
        >= 500 => FailureKind.unavailable,
        _ => FailureKind.unavailable,
      },
      field: field,
      retryAfter: retry,
      status: status,
    );
  }
}
