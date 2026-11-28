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

  void removeListener(void Function() callback) {
    _callbacks.remove(callback);
  }

  void cancel() {
    if (cancelled) return;
    cancelled = true;
    final list = List<void Function()>.of(_callbacks);
    _callbacks.clear();
    for (final callback in list) {
      callback();
    }
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
  HttpClient? _client;
  bool _closed = false;

  HttpClient _ensureClient() {
    if (_closed) throw const ProductFailure(FailureKind.unavailable);
    return _client ??= HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..idleTimeout = const Duration(seconds: 30);
  }

  void close() {
    _closed = true;
    _client?.close(force: true);
    _client = null;
  }

  @override
  Future<ApiResponse> send(
    String method,
    Uri uri,
    Map<String, String> headers,
    ApiBody? body,
    ApiCancellation cancel,
  ) async {
    final client = _ensureClient();
    HttpClientRequest? activeRequest;
    HttpClientResponse? activeResponse;
    StreamSubscription<List<int>>? activeResponseSub;
    StreamController<List<int>>? activeController;
    var responseListened = false;
    var responseClosed = false;

    void abortInFlight() {
      responseClosed = true;
      final req = activeRequest;
      activeRequest = null;
      if (req != null) {
        try {
          req.abort();
        } catch (_) {}
      }
      final sub = activeResponseSub;
      activeResponseSub = null;
      if (sub != null) {
        unawaited(sub.cancel().catchError((Object _) {}));
      }
      final res = activeResponse;
      activeResponse = null;
      if (res != null && !responseListened) {
        responseListened = true;
        // Release the underlying socket in the shared HttpClient pool without
        // hanging on large or infinite response bodies.
        unawaited(res.listen((_) {}, onError: (Object _) {}).cancel().catchError((Object _) {}));
      }
      final ctrl = activeController;
      activeController = null;
      if (ctrl != null && !ctrl.isClosed) {
        unawaited(ctrl.close().catchError((Object _) {}));
      }
    }

    cancel.listen(abortInFlight);
    try {
      if (cancel.cancelled) throw const ProductFailure(FailureKind.uncertain);
      final request = await client.openUrl(method, uri);
      activeRequest = request;
      if (cancel.cancelled || responseClosed) {
        abortInFlight();
        throw const ProductFailure(FailureKind.uncertain);
      }
      // Credentials and private data must never follow a redirect.
      request.followRedirects = false;
      headers.forEach(request.headers.set);
      if (body != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, body.type);
        request.contentLength = body.length;
        await request.addStream(body.open());
      }
      final response = await request.close();
      activeRequest = null;
      activeResponse = response;
      if (cancel.cancelled || responseClosed) {
        abortInFlight();
        throw const ProductFailure(FailureKind.uncertain);
      }
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) => responseHeaders[name.toLowerCase()] = values.join(','));
      final controller = StreamController<List<int>>();
      activeController = controller;
      controller.onListen = () {
        if (responseClosed || activeResponse == null) {
          abortInFlight();
          return;
        }
        final res = activeResponse!;
        activeResponse = null;
        responseListened = true;
        activeResponseSub = res.listen(
          controller.add,
          onError: (Object error, StackTrace stack) {
            activeResponseSub = null;
            cancel.removeListener(abortInFlight);
            if (!controller.isClosed) {
              controller.addError(error, stack);
              unawaited(controller.close().catchError((Object _) {}));
            }
          },
          onDone: () {
            activeResponseSub = null;
            cancel.removeListener(abortInFlight);
            if (!controller.isClosed) unawaited(controller.close().catchError((Object _) {}));
          },
          cancelOnError: true,
        );
      };
      void closeResponse() {
        cancel.removeListener(abortInFlight);
        abortInFlight();
      }

      controller.onCancel = closeResponse;
      return ApiResponse(response.statusCode, responseHeaders, controller.stream, closeResponse);
    } catch (_) {
      cancel.removeListener(abortInFlight);
      abortInFlight();
      rethrow;
    }
  }
}

/// Native JSON/Bearer transport. The only automatic replay follows a rejected
/// protected 401, once, after the session coordinator's single-flight refresh.
class ApiClient {
  static const defaultTimeout = Duration(seconds: 25);

  ApiClient(this.origin, {ApiTransport? transport, Duration? timeout})
    : transport = transport ?? NativeApiTransport(),
      timeout = timeout ?? defaultTimeout,
      _hasCustomTimeout = timeout != null {
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
  final bool _hasCustomTimeout;
  SessionController? session;

  Duration resolveTimeout([Duration? override]) => _hasCustomTimeout ? timeout : (override ?? timeout);

  void close() {
    final t = transport;
    if (t is NativeApiTransport) t.close();
  }

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
    Duration? timeout,
  }) async {
    final cancel = cancellation ?? ApiCancellation();
    final totalBudget = resolveTimeout(timeout);
    final elapsed = Stopwatch()..start();
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
      final remaining = totalBudget - elapsed.elapsed;
      if (remaining <= Duration.zero) {
        cancel.cancel();
        throw const ProductFailure(FailureKind.uncertain, cause: FailureCause.timeout);
      }
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
              remaining,
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
    Duration? timeout,
  }) async {
    final cancel = ApiCancellation();
    final totalTimeout = resolveTimeout(timeout);
    final elapsed = Stopwatch()..start();
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
        timeout: totalTimeout,
      );
      final remaining = totalTimeout - elapsed.elapsed;
      final bodyTimeout = remaining > Duration.zero ? remaining : const Duration(seconds: 2);
      // A body can contain private echoed validation input. Never log it.
      final bytes = await response.body
          .fold<List<int>>(<int>[], (bytes, chunk) {
            if (bytes.length + chunk.length > 16 * 1024 * 1024) throw const ProductFailure(FailureKind.unavailable);
            bytes.addAll(chunk);
            return bytes;
          })
          .timeout(
            bodyTimeout,
            onTimeout: () {
              cancel.cancel();
              throw const ProductFailure(FailureKind.uncertain, cause: FailureCause.timeout);
            },
          );
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
        throw failure(response.status, response.headers, value, allowUnverified: path == '/v1/auth/login');
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

  static const _maxRetryAfter = Duration(minutes: 15);

  static ProductFailure failure(
    int status,
    Map<String, String> headers,
    dynamic payload, {
    bool allowUnverified = false,
  }) {
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
            break;
          }
        }
      }
    }
    Duration? retry;
    final raw = headers['retry-after'];
    if (raw != null) {
      final seconds = int.tryParse(raw.trim());
      if (seconds != null) {
        retry = Duration(seconds: seconds.clamp(0, _maxRetryAfter.inSeconds));
      } else {
        try {
          final d = HttpDate.parse(raw).difference(DateTime.now());
          if (d.isNegative) {
            retry = Duration.zero;
          } else {
            retry = d > _maxRetryAfter ? _maxRetryAfter : d;
          }
        } catch (_) {}
      }
    }
    return ProductFailure(
      switch (status) {
        400 || 422 => FailureKind.validation,
        401 => FailureKind.unauthorized,
        403 => allowUnverified ? FailureKind.unverified : FailureKind.forbidden,
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
