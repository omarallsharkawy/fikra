import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/fikra_widgets.dart';
import '../../core/theme/tokens.dart';
import '../workspace/product_widgets.dart';
import 'session_controller.dart';
import 'product_welcome.dart';

class ProductAccountScreen extends StatefulWidget {
  const ProductAccountScreen({super.key});
  @override
  State<ProductAccountScreen> createState() => _ProductAccountScreenState();
}

class _ProductAccountScreenState extends State<ProductAccountScreen> {
  String _email = '', _password = '', _token = '';
  bool _register = false;
  bool _loginForm = false;
  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.session],
    builder: (context, runtime) {
      final session = runtime.session;
      final signedIn = session.stage == SessionStage.authenticated;
      final verifying = session.stage == SessionStage.awaitingVerification;
      final recovery =
          session.stage == SessionStage.recoveryRequest ||
          session.stage == SessionStage.recoverySent ||
          session.stage == SessionStage.recoveryConfirm;
      final resetForm = session.stage == SessionStage.recoveryConfirm;
      final welcome = !signedIn && !verifying && !recovery && !_loginForm && !_register;
      return ProductScaffold(
        title: signedIn
            ? context.l10n.uiProfile
            : welcome
            ? 'FIKRAH'
            : _register
            ? context.l10n.uiCreateAccount
            : context.l10n.uiWelcomeBack,
        trailing: signedIn
            ? IconButton(
                tooltip: context.l10n.uiSettings,
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_outlined),
              )
            : null,
        children: [
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
                      session.account!.email.substring(0, 1).toUpperCase(),
                      style: context.text.title.copyWith(color: context.colors.onBrandPurple),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(session.account!.email, style: context.text.section)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(context.l10n.productThisIsAVolatileDevelopmentWorkspaceExistingLocal),
            const SizedBox(height: 16),
            FikraButton.secondary(label: context.l10n.productSignOutLocally, onPressed: session.signOut),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                title: Text(context.l10n.uiSettings),
                leading: const Icon(Icons.settings_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings'),
              ),
            ),
          ] else if (welcome) ...[
            if (session.stage == SessionStage.expired) Text(context.l10n.productYourSessionExpiredSignInAgain),
            ProductWelcome(
              busy: session.busy,
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
            Text(context.l10n.productPreviewAccountJourneys, style: context.text.title),
            const SizedBox(height: 12),
            Text(context.l10n.productUseFixtureAddressesOnlyRegistrationVerificationAndRecovery),
            const SizedBox(height: 20),
            if (!verifying && !resetForm)
              ProductTextInput(
                key: const ValueKey('account-email'),
                value: _email,
                onChanged: (v) => setState(() => _email = v),
                enabled: !session.busy,
                label: context.l10n.productEmail,
                keyboardType: TextInputType.emailAddress,
              ),
            if ((!verifying && !recovery) || resetForm)
              ProductTextInput(
                key: const ValueKey('account-password'),
                value: _password,
                onChanged: (v) => setState(() => _password = v),
                obscure: true,
                enabled: !session.busy,
                label: resetForm ? context.l10n.productNewPasswordPreview : context.l10n.productPassword,
              ),
            if (verifying || resetForm)
              ProductTextInput(
                key: const ValueKey('account-token'),
                value: _token,
                onChanged: (v) => setState(() => _token = v),
                enabled: !session.busy,
                label: context.l10n.productFixtureActionToken,
              ),
            if (verifying) ...[
              Text(context.l10n.productAwaitingVerificationUseFixtureVerifyToPreviewSuccess),
              const SizedBox(height: 12),
              FikraButton(
                key: const ValueKey('verify-email'),
                label: context.l10n.productPreviewVerification,
                loading: session.busy,
                onPressed: session.coolingDown || _token.isEmpty
                    ? null
                    : () async {
                        await session.verify(_token);
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
                child: Text(context.l10n.productPreviewResendRequest),
              ),
            ] else if (recovery) ...[
              if (session.stage == SessionStage.recoverySent) ...[
                Text(context.l10n.productGenericRecoveryAcknowledgmentFixtureNoDeliveryIsClaimed),
                TextButton(
                  onPressed: () => session.show(SessionStage.recoveryConfirm),
                  child: Text(context.l10n.productPreviewResetForm),
                ),
              ] else if (resetForm) ...[
                Text(context.l10n.productUseFixtureResetTheRealPasswordPolicyIs),
                FikraButton(
                  label: context.l10n.productPreviewPasswordReset,
                  loading: session.busy,
                  onPressed: session.coolingDown || _token.isEmpty || _password.isEmpty
                      ? null
                      : () => session.confirmRecovery(_token, _password),
                ),
              ] else
                FikraButton(
                  label: context.l10n.productPreviewRecoveryRequest,
                  loading: session.busy,
                  onPressed: session.coolingDown || _email.trim().isEmpty ? null : () => session.recover(_email),
                ),
            ] else ...[
              FikraButton(
                key: const ValueKey('account-submit'),
                loading: session.busy,
                label: _register ? context.l10n.productPreviewRegistration : context.l10n.productOpenFixtureSession,
                onPressed: session.coolingDown || _email.trim().isEmpty || _password.isEmpty
                    ? null
                    : () => _register ? session.register(_email, _password) : session.login(_email, _password),
              ),
              TextButton(
                onPressed: session.busy
                    ? null
                    : () => setState(() {
                        _register = !_register;
                        _loginForm = !_register;
                      }),
                child: Text(_register ? context.l10n.productBackToSignIn : context.l10n.productPreviewNewAccount),
              ),
              TextButton(
                onPressed: session.busy ? null : () => session.show(SessionStage.recoveryRequest),
                child: Text(context.l10n.productForgotPassword),
              ),
              Text(context.l10n.productGoogleSignInWaitingForApprovedPlatformConfiguration),
              const SizedBox(height: 20),
              FikraButton.secondary(
                key: const ValueKey('fixture-reader'),
                label: context.l10n.productPreviewSampleWorkspace,
                onPressed: (session.busy || session.coolingDown)
                    ? null
                    : () => session.login('reader@example.invalid', 'fixture-only'),
              ),
              const SizedBox(height: 10),
              FikraButton.secondary(
                key: const ValueKey('fixture-other'),
                label: context.l10n.productPreviewSeparateEmptyAccount,
                onPressed: (session.busy || session.coolingDown)
                    ? null
                    : () => session.login('other@example.invalid', 'fixture-only'),
              ),
            ],
            if (verifying || recovery)
              TextButton(
                onPressed: session.busy
                    ? null
                    : () {
                        setState(() {
                          _register = false;
                          _loginForm = true;
                        });
                        session.show(SessionStage.unauthenticated);
                      },
                child: Text(context.l10n.productBackToSignIn),
              ),
          ],
          if (session.notice != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(switch (session.notice!) {
                'verified' => context.l10n.productVerificationPreviewCompleteSignInSeparately,
                'reset' => context.l10n.productResetPreviewCompleteSignInAgain,
                'localLogout' => context.l10n.productLocalPrivateStateClearedServerRevocationIsNot,
                _ => context.l10n.productDevelopmentAcknowledgmentOnlyNoRealDeliveryOrAccount,
              }),
            ),
          if (session.failure != null) ProductFailureView(session.failure!),
        ],
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
