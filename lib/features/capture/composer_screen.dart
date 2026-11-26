import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/composer_navigation.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../workspace/product_widgets.dart';
import '../workspace/project_controls.dart';
import '../workspace/color_action.dart';
import 'capture_controller.dart';

class ProductComposerScreen extends StatelessWidget {
  const ProductComposerScreen({super.key});
  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.workspace, r.capture],
    builder: (context, r) {
      final w = r.workspace, capture = r.capture;
      final locked = w.busy || w.pendingAttempt != null;
      return ProductScaffold(
        title: context.l10n.uiNewIdea,
        trailing: IconButton(
          tooltip: context.l10n.productCloseComposer,
          onPressed: () => ComposerNavigation.closeOf(context),
          icon: const Icon(Icons.close),
        ),
        children: [
          ProductProjectControls(runtime: r),
          if (w.pendingAttempt != null) ...[
            Text(context.l10n.productASaveAttemptIsUnresolvedRetryItsOriginal),
            if (w.pendingAttempt!.projectId != w.selectedProjectId)
              TextButton(
                onPressed: () => w.selectProject(w.pendingAttempt!.projectId),
                child: Text(context.l10n.productReturnToThePendingAttemptSProject),
              ),
          ],
          if (w.canReviewFailedAttempt)
            TextButton(
              onPressed: () async {
                final yes = await confirmDestructive(
                  context,
                  title: context.l10n.productReviewFailedSave,
                  message: context.l10n.productNewIntentionalSaveExplanation,
                  confirmLabel: context.l10n.productReviewFailedSave,
                );
                if (yes && context.mounted) await w.reviewFailedAttempt();
              },
              child: Text(context.l10n.productReviewFailedSave),
            ),
          ProductTextInput(
            key: ValueKey('capture-title-${w.selectedProjectId}'),
            value: w.draft.title,
            onChanged: (v) => w.updateDraft(title: v),
            enabled: !locked,
            label: context.l10n.productTitleOptional,
          ),
          ProductTextInput(
            key: ValueKey('capture-content-${w.selectedProjectId}'),
            value: w.draft.content,
            onChanged: (v) => w.updateDraft(content: v),
            lines: 6,
            enabled: !locked,
            label: context.l10n.productYourThought,
          ),
          const Divider(height: 32),
          Text(context.l10n.productVoiceReviewedText, style: context.text.section),
          Text(context.l10n.productAutomaticStopAt60SecondsTranscriptionDoesNot),
          if (capture.failure != null) ProductFailureView(capture.failure!),
          if (capture.state == CaptureState.recording) ...[
            Text('${Fmt.duration(capture.elapsed.inMilliseconds)} / 1:00', key: const ValueKey('recording-time')),
            FikraButton(label: context.l10n.productStopRecording, onPressed: capture.stop),
          ] else if (capture.active)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final voice = ProductColorAction(
                  key: const ValueKey('record-product-voice'),
                  label: context.l10n.uiVoice,
                  icon: Icons.mic_none,
                  color: context.colors.brandPurple,
                  foreground: context.colors.onBrandPurple,
                  onPressed: locked || capture.pickingPdf ? null : capture.start,
                );
                final file = ProductColorAction(
                  label: context.l10n.uiFile,
                  icon: Icons.attach_file,
                  color: context.colors.brandBlue,
                  foreground: context.colors.onBrandBlue,
                  onPressed: capture.pickingPdf ? null : capture.pickPdf,
                );
                return MediaQuery.textScalerOf(context).scale(1) >= 1.5
                    ? Column(children: [voice, const SizedBox(height: 12), file])
                    : Row(
                        children: [
                          Expanded(child: voice),
                          const SizedBox(width: 12),
                          Expanded(child: file),
                        ],
                      );
              },
            ),
          if (capture.clip != null && !capture.active) ...[
            const SizedBox(height: 12),
            FikraButton.secondary(
              key: const ValueKey('transcribe-product-voice'),
              label: context.l10n.productPreviewTranscription,
              onPressed: capture.coolingDown ? null : capture.transcribe,
            ),
          ],
          if (capture.state == CaptureState.review) ...[
            const SizedBox(height: 12),
            ProductTextInput(
              key: const ValueKey('transcript-review'),
              value: capture.transcript,
              onChanged: capture.editTranscript,
              lines: 4,
              label: context.l10n.productReviewAndEditTranscript,
            ),
            FikraButton.secondary(
              key: const ValueKey('use-transcript'),
              label: context.l10n.productUseThisTextInTheDraft,
              onPressed: locked ? null : () => w.updateDraft(content: capture.transcript),
            ),
            Text(context.l10n.productThenPressSaveTextNoteWhenReady),
          ],
          if (capture.clip != null || capture.active)
            TextButton(onPressed: capture.cancel, child: Text(context.l10n.productDiscardRecording)),
          const Divider(height: 32),
          Text(context.l10n.productLocalPDFs, style: context.text.section),
          Text(context.l10n.productPDFsStayOnThisDeviceTheyAreNot),
          for (final pdf in capture.localPdfs)
            ListTile(title: Text(pdf.name), trailing: const Icon(Icons.open_in_new), onTap: () => capture.openPdf(pdf)),
          const SizedBox(height: 24),
          FikraButton(
            key: const ValueKey('save-product-note'),
            growForText: true,
            label: w.pendingAttempt != null
                ? context.l10n.productReconcileTheSameSaveAttempt
                : context.l10n.productSaveTextNote,
            loading: w.busy,
            onPressed: capture.active || w.selected == null || w.coolingDown
                ? null
                : () async {
                    final saved = await w.save();
                    if (saved != null && context.mounted) context.go('/notes');
                  },
          ),
          const SizedBox(height: 12),
          Text(context.l10n.productSavingAndProcessingAreSeparateAMissingTitle, style: context.text.meta),
        ],
      );
    },
  );
}
