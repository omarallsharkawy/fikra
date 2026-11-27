import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/product_runtime.dart';
import '../../app/providers.dart';
import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../core/widgets/redesign_segments.dart';
import '../../data/product/models.dart';
import '../../l10n/localizations.dart';
import '../workspace/note_share.dart';
import '../workspace/product_widgets.dart';
import 'profile_name_sheet.dart';

class ProductMeScreen extends ConsumerStatefulWidget {
  const ProductMeScreen({super.key, required this.runtime});
  final ProductRuntime runtime;
  @override
  ConsumerState<ProductMeScreen> createState() => _MeState();
}

class _MeState extends ConsumerState<ProductMeScreen> {
  String? _scope;
  bool _exporting = false, _preferencesBusy = false;
  ProductFailure? _failure;
  void _loadStats() {
    final w = widget.runtime.workspace;
    final scope = '${w.accountId}:${w.selectedProjectId}';
    if (!TickerMode.valuesOf(context).enabled || w.accountId == null || w.selectedProjectId == null || scope == _scope)
      return;
    _scope = scope;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) {
        _scope = null;
        return;
      }
      unawaited(w.loadGraph());
    });
  }

  Future<void> _preference(Future<void> Function() action) async {
    if (_preferencesBusy) return;
    setState(() {
      _preferencesBusy = true;
      _failure = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _failure = const ProductFailure(FailureKind.unavailable));
    } finally {
      if (mounted) setState(() => _preferencesBusy = false);
    }
  }

  Future<void> _export() async {
    if (_exporting) return;
    final r = widget.runtime, w = widget.runtime.workspace;
    final account = w.accountId, project = w.selected;
    if (account == null || project == null) return;
    setState(() {
      _exporting = true;
      _failure = null;
    });
    try {
      final notes = await r.repository.notes(account, project.id);
      if (!mounted || account != w.accountId || project.id != w.selectedProjectId) return;
      final json = {
        'format': 'fikrah-notes-v1',
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'scope': 'selected_project',
        'project': {'id': project.id, 'name': project.name},
        'notes': [
          for (final n in notes.where((n) => !r.undo.hiddenIds.contains(n.id)))
            {
              'id': n.id,
              'title': n.title,
              'content': n.content,
              'created_at': n.createdAt.toIso8601String(),
              'updated_at': n.updatedAt.toIso8601String(),
              'processing_status': n.processing.name,
              'concepts': n.concepts,
              'is_favorite': n.isFavorite,
              'device_tags': [for (final tag in r.tags.forNote(n.id)) tag.label],
            },
        ],
      };
      await ref
          .read(noteSharingProvider)
          .share(
            Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(json))),
            filename: 'FIKRAH-notes-${DateTime.now().millisecondsSinceEpoch}.json',
            mime: 'application/json',
          );
    } catch (_) {
      if (mounted && account == w.accountId) setState(() => _failure = const ProductFailure(FailureKind.unavailable));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.runtime.workspace, widget.runtime.profile, widget.runtime.undo]),
    builder: (context, _) {
      _loadStats();
      final r = widget.runtime, w = r.workspace, p = r.profile, l = context.l10n;
      final theme = ref.watch(appThemeProvider).value ?? AppTheme.system;
      final language = ref.watch(appLanguageProvider).value ?? AppLanguage.en;
      final notes = w.notes.where((n) => !r.undo.hiddenIds.contains(n.id));
      final edges = w.graph.edges.where(
        (e) => !r.undo.hiddenIds.contains(e.source) && !r.undo.hiddenIds.contains(e.target),
      );
      final sharing = ref.watch(noteSharingProvider);
      return RdPage(
        title: l.rdMe,
        header: SizedBox(
          height: 60,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 14, 44, 10),
                child: Row(
                  spacing: 8,
                  children: [
                    const RdLogo(),
                    Expanded(child: RdText(l.rdMe, size: 22, weight: FontWeight.w600)),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 8,
                end: 0,
                child: IconButton(
                  tooltip: l.uiSettings,
                  onPressed: () => context.push('/settings'),
                  icon: Icon(Icons.settings_outlined, size: 22, color: context.rd.text),
                ),
              ),
            ],
          ),
        ),
        children: [
          if (_failure != null) ProductFailureView(_failure!),
          if (p.failure != null)
            ProductFailureView(
              p.failure!,
              onRetry: () => p.bind(r.session.account?.id, r.session.account?.email ?? ''),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              spacing: 14,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.rd.purple,
                    border: Border.all(color: context.rd.lime, width: 3),
                  ),
                  child: RdText(p.initial, size: 28, color: Colors.white, weight: FontWeight.w600),
                ),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: l.rdEditName,
                    child: InkWell(
                      onTap: p.loading || p.busy ? null : () => editProfileName(context, p),
                      borderRadius: BorderRadius.circular(10),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (p.loading)
                              const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            else
                              RdText(p.name ?? l.rdAddName, size: 19, weight: FontWeight.w700),
                            RdText(
                              r.session.account?.email ?? '',
                              size: 13,
                              color: context.rd.muted,
                              direction: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (w.projects.any((p) => !p.isGeneral))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RdText(l.uxProjectContext(rdIsolate(w.selected?.name ?? '')), size: 13, color: context.rd.muted),
            ),
          if (w.failure != null) ProductFailureView(w.failure!, onRetry: w.retryWorkspace),
          if (w.graphFailure != null) ProductFailureView(w.graphFailure!, onRetry: w.loadGraph),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Expanded(
                    child: _Stat(l.rdStat1, value: w.failure == null ? '${notes.length}' : '—', loading: w.loading),
                  ),
                  Expanded(
                    child: _Stat(
                      l.rdStat2,
                      value: w.graphFailure == null ? '${edges.length}' : '—',
                      loading: w.graphLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
          RdCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RdText(l.rdLang, weight: FontWeight.w600),
                RdSegments<AppLanguage>(
                  values: {AppLanguage.ar: l.languageArabic, AppLanguage.en: l.languageEnglish},
                  selected: language,
                  onChanged: _preferencesBusy
                      ? null
                      : (v) => _preference(() => ref.read(settingsRepoProvider).setLanguage(v)),
                ),
                RdText(l.rdTheme, weight: FontWeight.w600),
                RdSegments<AppTheme>(
                  values: {AppTheme.light: l.rdLight, AppTheme.dark: l.rdDark, AppTheme.system: l.rdSys},
                  selected: theme,
                  onChanged: _preferencesBusy
                      ? null
                      : (v) => _preference(() => ref.read(settingsRepoProvider).setTheme(v)),
                ),
                if (sharing.available)
                  TextButton(
                    onPressed: _exporting || w.selected == null ? null : _export,
                    style: TextButton.styleFrom(
                      foregroundColor: context.rd.text,
                      alignment: AlignmentDirectional.centerStart,
                      minimumSize: const Size(44, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Row(
                      spacing: 12,
                      children: [
                        if (_exporting)
                          const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          const RdIcon('share'),
                        Expanded(child: RdText(l.rdExp)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          RdButton(
            l.rdOut,
            danger: true,
            onPressed: () async {
              final account = r.session.account?.id;
              if (await rdConfirm(context, title: l.rdOutq, message: l.rdOutb, confirm: l.rdOut)) {
                if (context.mounted && account == r.session.account?.id) {
                  await w.flushDraft();
                  await r.session.signOut();
                }
              }
            },
          ),
        ],
      );
    },
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, {required this.value, required this.loading});
  final String label, value;
  final bool loading;
  @override
  Widget build(BuildContext context) => RdCard(
    margin: 0,
    child: Column(
      children: [
        if (loading)
          const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2))
        else
          RdText(value, size: 22, weight: FontWeight.w700),
        RdText(label, size: 13, color: context.rd.muted),
      ],
    ),
  );
}
