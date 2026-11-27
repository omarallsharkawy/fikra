import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/fikra_widgets.dart';
import '../../core/theme/tokens.dart';
import '../workspace/product_widgets.dart';
import 'session_controller.dart';
import 'product_welcome.dart';
import 'product_auth_layout.dart';
import 'product_auth_feedback.dart';

class ProductAccountScreen extends StatefulWidget {
  const ProductAccountScreen({super.key});
  @override
  State<ProductAccountScreen> createState() => _ProductAccountScreenState();
}

class _ProductAccountScreenState extends State<ProductAccountScreen> {
  String _email = '', _password = '', _token = '';
  bool _register = false;
  bool _loginForm = false;
  Future<void> _submit(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    await action();
  }

  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.session],
    builder: (context, runtime) {
      final session = runtime.session;
      final preview = session.repository.isDevelopment;
      final validPassword = preview || (_password.runes.length >= 5 && _password.runes.length <= 128);
      final validCode = preview ? _token.isNotEmpty : RegExp(r'^[0-9]{6}$').hasMatch(_token);
      final signedIn = session.stage == SessionStage.authenticated;
      final verifying = session.stage == SessionStage.awaitingVerification;
      final recovery =
          session.stage == SessionStage.recoveryRequest ||
          session.stage == SessionStage.recoverySent ||
          session.stage == SessionStage.recoveryConfirm;
      final resetForm = session.stage == SessionStage.recoveryConfirm;
      final welcome = !signedIn && !verifying && !recovery && !_loginForm && !_register;
      final title = signedIn
          ? context.l10n.uiProfile
          : welcome
          ? 'FIKRAH'
          : verifying
          ? context.l10n.uxVerifyTitle
          : resetForm
          ? context.l10n.uxResetTitle
          : session.stage == SessionStage.recoverySent
          ? context.l10n.uxRecoverySentTitle
          : recovery
          ? context.l10n.uxRecoveryTitle
          : _register
          ? context.l10n.uiCreateAccount
          : context.l10n.uiWelcomeBack;
      final trailing = signedIn
          ? IconButton(
              tooltip: context.l10n.uiSettings,
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined),
            )
          : null;
      final previewDetails = [
        context.l10n.productUseFixtureAddressesOnlyRegistrationVerificationAndRecovery,
        context.l10n.productThisIsAVolatileDevelopmentWorkspaceExistingLocal,
        context.l10n.productGoogleSignInWaitingForApprovedPlatformConfiguration,
        if (verifying) context.l10n.productAwaitingVerificationUseFixtureVerifyToPreviewSuccess,
        if (resetForm) context.l10n.productUseFixtureResetTheRealPasswordPolicyIs,
      ];
      final children = <Widget>[
        if (session.notice != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(switch (session.notice!) {
              'verified' =>
                preview ? context.l10n.productVerificationPreviewCompleteSignInSeparately : context.l10n.apiVerified,
              'reset' => preview ? context.l10n.productResetPreviewCompleteSignInAgain : context.l10n.apiResetComplete,
              'localLogout' => context.l10n.productLocalPrivateStateClearedServerRevocationIsNot,
              'logout' => context.l10n.apiSignedOut,
              _ =>
                preview
                    ? context.l10n.productDevelopmentAcknowledgmentOnlyNoRealDeliveryOrAccount
                    : context.l10n.apiCodeAcknowledgment,
            }),
          ),
        if (session.failure != null) ProductAuthFeedback(session.failure!),
        if (signedIn) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.brandPurple,
                    border: Border.all(color: context.colors.brandLime, width: 4),
                  ),
                  child: Text(
                    session.account!.email.isEmpty ? 'F' : session.account!.email.characters.first.toUpperCase(),
                    style: context.text.title.copyWith(color: context.colors.onBrandPurple),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(session.account!.email, style: context.text.section)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              title: Text(context.l10n.uiSettings),
              leading: const Icon(Icons.settings_outlined),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings'),
            ),
          ),
          const SizedBox(height: 24),
          FikraButton.secondary(
            label: preview ? context.l10n.productSignOutLocally : context.l10n.apiSignOut,
            onPressed: session.signOut,
            growForText: true,
          ),
        ] else if (welcome) ...[
          if (session.stage == SessionStage.expired) Text(context.l10n.productYourSessionExpiredSignInAgain),
          ProductWelcome(
            busy: session.busy,
            preview: preview,
            onSignup: session.busy ? null : () => setState(() => _register = true),
            onLogin: session.busy ? null : () => setState(() => _loginForm = true),
            onSample: session.busy || session.coolingDown
                ? null
                : () => session.login('reader@example.invalid', 'fixture-only'),
            onEmpty: session.busy || session.coolingDown
                ? null
                : () => session.login('other@example.invalid', 'fixture-only'),
          ),
        ] else ...[
          if (session.stage == SessionStage.expired) Text(context.l10n.productYourSessionExpiredSignInAgain),

          if (!verifying && !resetForm && session.stage != SessionStage.recoverySent)
            ProductTextInput(
              key: const ValueKey('account-email'),
              value: _email,
              onChanged: (v) => setState(() => _email = v),
              enabled: !session.busy,
              label: context.l10n.productEmail,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textInputAction: recovery ? TextInputAction.done : TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
          if ((verifying || resetForm) && !preview) ...[
            Text(session.email, textDirection: TextDirection.ltr, style: context.text.caption),
            const SizedBox(height: 16),
          ],
          if (verifying || resetForm)
            ProductTextInput(
              key: const ValueKey('account-token'),
              value: _token,
              onChanged: (v) => setState(() => _token = v),
              enabled: !session.busy,
              label: preview ? context.l10n.productFixtureActionToken : context.l10n.apiSixDigitCode,
              keyboardType: preview ? null : TextInputType.number,
              autofillHints: preview ? null : const [AutofillHints.oneTimeCode],
              inputFormatters: preview
                  ? null
                  : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              textDirection: TextDirection.ltr,
              textInputAction: resetForm ? TextInputAction.next : TextInputAction.done,
            ),
          if ((!verifying && !recovery) || resetForm)
            ProductTextInput(
              key: const ValueKey('account-password'),
              value: _password,
              onChanged: (v) => setState(() => _password = v),
              obscure: true,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.done,
              autofillHints: [resetForm || _register ? AutofillHints.newPassword : AutofillHints.password],
              enabled: !session.busy,
              label: resetForm
                  ? (preview ? context.l10n.productNewPasswordPreview : context.l10n.apiNewPassword)
                  : context.l10n.productPassword,
            ),
          if (!preview && (_register || resetForm))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(context.l10n.apiPasswordHint, style: context.text.meta),
            ),
          if (!verifying && !recovery && !_register)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: session.busy
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _password = '';
                          _token = '';
                        });
                        session.show(SessionStage.recoveryRequest);
                      },
                child: Text(context.l10n.productForgotPassword),
              ),
            ),
          const SizedBox(height: 12),
          if (verifying) ...[
            FikraButton(
              key: const ValueKey('verify-email'),
              label: preview ? context.l10n.productPreviewVerification : context.l10n.apiVerifyEmail,
              loading: session.busy,
              growForText: true,
              onPressed: session.coolingDown || !validCode
                  ? null
                  : () async {
                      await _submit(() => session.verify(_token));
                      if (mounted && session.stage == SessionStage.unauthenticated) {
                        setState(() {
                          _register = false;
                          _loginForm = true;
                          _password = '';
                          _token = '';
                        });
                      }
                    },
            ),
            TextButton(
              onPressed: (session.busy || session.coolingDown) ? null : session.resend,
              child: Text(preview ? context.l10n.productPreviewResendRequest : context.l10n.apiResendCode),
            ),
          ] else if (recovery) ...[
            if (session.stage == SessionStage.recoverySent) ...[
              Text(
                preview
                    ? context.l10n.productGenericRecoveryAcknowledgmentFixtureNoDeliveryIsClaimed
                    : context.l10n.apiRecoveryAcknowledgment,
              ),
              TextButton(
                onPressed: () => session.show(SessionStage.recoveryConfirm),
                child: Text(preview ? context.l10n.productPreviewResetForm : context.l10n.apiHaveCode),
              ),
            ] else if (resetForm) ...[
              FikraButton(
                label: context.l10n.uxResetPassword,
                loading: session.busy,
                growForText: true,
                onPressed: session.coolingDown || !validCode || _password.isEmpty || !validPassword
                    ? null
                    : () async {
                        await _submit(() => session.confirmRecovery(_token, _password));
                        if (mounted && session.stage == SessionStage.unauthenticated) {
                          setState(() {
                            _password = '';
                            _token = '';
                            _register = false;
                            _loginForm = true;
                          });
                        }
                      },
              ),
              if (!preview)
                TextButton(
                  onPressed: session.busy || session.coolingDown ? null : () => session.recover(session.email),
                  child: Text(context.l10n.apiResendCode),
                ),
            ] else
              FikraButton(
                label: context.l10n.uxRequestReset,
                loading: session.busy,
                growForText: true,
                onPressed: session.coolingDown || _email.trim().isEmpty
                    ? null
                    : () => _submit(() => session.recover(_email)),
              ),
          ] else ...[
            FikraButton(
              key: const ValueKey('account-submit'),
              loading: session.busy,
              growForText: true,
              label: _register ? context.l10n.uiCreateAccount : context.l10n.uiLogIn,
              onPressed: session.coolingDown || _email.trim().isEmpty || _password.isEmpty || !validPassword
                  ? null
                  : () => _submit(
                      () => _register ? session.register(_email, _password) : session.login(_email, _password),
                    ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: session.busy
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _register = !_register;
                        _loginForm = !_register;
                        _password = '';
                        _token = '';
                      });
                      session.show(session.stage);
                    },
              child: Text(_register ? context.l10n.authHaveAccount : context.l10n.authNewAccount),
            ),
          ],
          if (verifying || recovery)
            TextButton(
              onPressed: session.busy
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _register = false;
                        _loginForm = true;
                        _password = '';
                        _token = '';
                      });
                      session.show(SessionStage.unauthenticated);
                    },
              child: Text(context.l10n.productBackToSignIn),
            ),
        ],
      ];
      if (signedIn) {
        return ProductScaffold(title: title, trailing: trailing, previewDetails: previewDetails, children: children);
      }
      return ProductAuthLayout(
        key: ValueKey((welcome, verifying, recovery, resetForm, _register)),
        title: title,
        welcome: welcome,
        subtitle: welcome
            ? null
            : verifying
            ? (preview ? context.l10n.authVerifyHint : context.l10n.apiVerifyHint)
            : resetForm
            ? (preview ? context.l10n.authResetHint : context.l10n.apiResetHint)
            : session.stage == SessionStage.recoverySent
            ? context.l10n.authRecoverySentHint
            : recovery
            ? context.l10n.authRecoveryHint
            : _register
            ? context.l10n.authSignupHint
            : context.l10n.authLoginHint,
        icon: verifying || session.stage == SessionStage.recoverySent
            ? Icons.mark_email_unread_outlined
            : recovery
            ? Icons.lock_reset_rounded
            : _register
            ? Icons.person_add_alt_1_rounded
            : Icons.login_rounded,
        onBack: welcome || session.busy
            ? null
            : () {
                FocusScope.of(context).unfocus();
                setState(() {
                  _register = false;
                  _loginForm = verifying || recovery;
                  _password = '';
                  _token = '';
                });
                if (verifying || recovery) session.show(SessionStage.unauthenticated);
              },
        previewDetails: previewDetails,
        children: children,
      );
    },
  );
}

class _ProductPreferences extends ConsumerWidget {
  const _ProductPreferences();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider).value ?? AppTheme.system;
    final language = ref.watch(appLanguageProvider).value ?? AppLanguage.en;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<AppTheme>(
          key: ValueKey(theme),
          initialValue: theme,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.appearance),
          items: [
            DropdownMenuItem(value: AppTheme.system, child: Text(context.l10n.themeSystem)),
            DropdownMenuItem(value: AppTheme.light, child: Text(context.l10n.themeLight)),
            DropdownMenuItem(value: AppTheme.dark, child: Text(context.l10n.themeDark)),
          ],
          onChanged: (value) {
            if (value != null) runAction(context, () => ref.read(settingsRepoProvider).setTheme(value));
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<AppLanguage>(
          key: ValueKey(language),
          initialValue: language,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.languageSection),
          items: [
            DropdownMenuItem(value: AppLanguage.system, child: Text(context.l10n.languageSystem)),
            DropdownMenuItem(value: AppLanguage.ar, child: Text(context.l10n.languageArabic)),
            DropdownMenuItem(value: AppLanguage.en, child: Text(context.l10n.languageEnglish)),
          ],
          onChanged: (value) {
            if (value != null) runAction(context, () => ref.read(settingsRepoProvider).setLanguage(value));
          },
        ),
      ],
    );
  }
}

class ProductSettingsScreen extends StatelessWidget {
  const ProductSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => ProductScaffold(
    title: context.l10n.uiSettings,
    back: true,
    children: [
      Card(
        child: ListTile(
          key: const ValueKey('manage-product-projects'),
          leading: const Icon(Icons.folder_outlined),
          title: Text(context.l10n.projectsTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/projects'),
        ),
      ),
      const SizedBox(height: 20),
      const _ProductPreferences(),
    ],
  );
}
