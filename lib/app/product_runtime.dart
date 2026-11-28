import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/product/development/development_auth.dart';
import '../data/product/development/development_knowledge.dart';
import '../data/product/repositories.dart';
import '../features/account/session_controller.dart';
import '../features/workspace/workspace_controller.dart';
import '../features/conversation/conversation_controller.dart';
import '../features/capture/capture_controller.dart';
import '../features/capture/native_capture_device.dart';
import '../features/capture/local_documents.dart';
import 'providers.dart';
import 'app_config.dart' show apiOrigin;
import '../data/product/api/api_client.dart';
import '../data/product/api/api_auth.dart';
import '../data/product/api/api_knowledge.dart';
import '../data/product/secure_session_vault.dart';
import '../data/product/secure_attempt_store.dart';

final productApiOriginProvider = Provider<Uri>((ref) => Uri.parse(apiOrigin));
final productApiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(productApiOriginProvider)));
final productAuthProvider = Provider<AuthRepository>(
  (ref) => ref.watch(appModeProvider) == AppMode.connected
      ? ApiAuthRepository(ref.watch(productApiClientProvider))
      : DevelopmentAuthRepository(),
);
final productKnowledgeProvider = Provider<KnowledgeRepository>(
  (ref) => ref.watch(appModeProvider) == AppMode.connected
      ? ApiKnowledgeRepository(ref.watch(productApiClientProvider))
      : DevelopmentKnowledgeRepository(),
);
final productVaultProvider = Provider<SessionVault>(
  (ref) => ref.watch(appModeProvider) == AppMode.connected
      ? SecureSessionVault(key: 'fikrah_session:${ref.watch(productApiOriginProvider).origin}')
      : MemorySessionVault(),
);
final productAttemptsProvider = Provider<AttemptStore>(
  (ref) => ref.watch(appModeProvider) == AppMode.connected
      ? SecureAttemptStore(namespace: ref.watch(productApiOriginProvider).origin)
      : MemoryAttemptStore(),
);
final productCaptureDeviceProvider = Provider<CaptureDevice>(
  (ref) => NativeCaptureDevice(
    null,
    ref.read(microphonePermissionProvider),
    ref.read(attachmentStoreProvider),
    createRecorder: ref.read(audioRecorderFactoryProvider),
  ),
);

final productDocumentsProvider = Provider<LocalDocuments>((ref) => DeviceLocalDocuments(ref.read(fileOpenerProvider)));

final productRuntimeProvider = Provider<ProductRuntime>((ref) {
  final runtime = ProductRuntime(
    ref.watch(productAuthProvider),
    ref.watch(productVaultProvider),
    ref.watch(productKnowledgeProvider),
    ref.watch(productAttemptsProvider),
    ref.watch(productCaptureDeviceProvider),
    documents: ref.watch(productDocumentsProvider),
  );
  if (ref.watch(appModeProvider) == AppMode.connected) {
    final api = ref.watch(productApiClientProvider);
    api.session = runtime.session;
    ref.onDispose(() {
      if (identical(api.session, runtime.session)) api.session = null;
    });
  }
  ref.onDispose(runtime.dispose);
  unawaited(runtime.session.restore());
  return runtime;
});

class ProductRuntime {
  ProductRuntime(
    AuthRepository auth,
    SessionVault vault,
    this.repository,
    this.attempts,
    CaptureDevice device, {
    LocalDocuments? documents,
  }) {
    session = SessionController(auth, vault);
    workspace = WorkspaceController(repository, attempts, onUnauthorized: () => unawaited(session.expire()));
    chat = ConversationController(repository, onUnauthorized: () => unawaited(session.expire()));
    capture = CaptureController(
      device,
      repository,
      documents: documents,
      onUnauthorized: () => unawaited(session.expire()),
    );
    session.addListener(_sessionChanged);
    workspace.addListener(_projectChanged);
  }
  final KnowledgeRepository repository;
  final AttemptStore attempts;
  late final SessionController session;
  late final WorkspaceController workspace;
  late final ConversationController chat;
  late final CaptureController capture;
  String? _account, _project;
  int _knowledgeRevision = 0;
  bool _foreground = true;
  void _sessionChanged() {
    final id = session.stage == SessionStage.authenticated ? session.account?.id : null;
    if (id == _account) return;
    final old = _account;
    _account = id;
    _project = null;
    workspace.clear();
    chat.reset();
    capture.setAccount(id);
    if (old != null) {
      repository.clearAccount(old);
      if (session.stage != SessionStage.expired) {
        unawaited(attempts.clear(old).catchError((Object _) {}));
      }
    }
    if (id != null) unawaited(workspace.openAccount(id));
  }

  void _projectChanged() {
    if (_knowledgeRevision != workspace.knowledgeRevision) {
      _knowledgeRevision = workspace.knowledgeRevision;
      chat.invalidateNoteReferences(workspace.notes.map((n) => n.id).toSet());
    }
    final project = workspace.selectedProjectId;
    if (project == _project) return;
    _project = project;
    if (project == null || _account == null) {
      chat.reset();
    } else {
      unawaited(chat.selectProject(_account!, project));
    }
  }

  void foreground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    workspace.setForeground(value);
    if (!value) {
      capture.background();
      chat.interrupt();
    } else if (chat.sendState == SendState.uncertain) {
      unawaited(chat.reconcile());
    }
  }

  void dispose() {
    session.removeListener(_sessionChanged);
    workspace.removeListener(_projectChanged);
    session.dispose();
    workspace.dispose();
    chat.dispose();
    capture.dispose();
  }
}

/// Replaces all route-local private widget state on an account boundary.
class ProductBoundary extends StatefulWidget {
  const ProductBoundary({super.key, required this.runtime, required this.child});
  final ProductRuntime runtime;
  final Widget child;
  @override
  State<ProductBoundary> createState() => _ProductBoundaryState();
}

class _ProductBoundaryState extends State<ProductBoundary> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ignore AppLifecycleState.inactive: transient OS overlays (permission
    // dialogs, notification shade, file pickers) are not true backgrounding.
    if (state == AppLifecycleState.resumed) {
      widget.runtime.foreground(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      widget.runtime.foreground(false);
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.runtime.session,
    builder: (_, _) => KeyedSubtree(
      key: ValueKey((widget.runtime.session.epoch, widget.runtime.session.account?.id)),
      child: widget.child,
    ),
  );
}
