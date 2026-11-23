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

final productAuthProvider = Provider<AuthRepository>((ref) => DevelopmentAuthRepository());
final productKnowledgeProvider = Provider<KnowledgeRepository>((ref) => DevelopmentKnowledgeRepository());
final productVaultProvider = Provider<SessionVault>((ref) => MemorySessionVault());
final productAttemptsProvider = Provider<AttemptStore>((ref) => MemoryAttemptStore());
final productCaptureDeviceProvider = Provider<CaptureDevice>(
  (ref) => NativeCaptureDevice(
    ref.read(audioRecorderFactoryProvider)(),
    ref.read(microphonePermissionProvider),
    ref.read(attachmentStoreProvider),
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
    capture = CaptureController(device, repository, documents: documents);
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
      unawaited(attempts.clear(old));
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
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      widget.runtime.foreground(state == AppLifecycleState.resumed);
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
