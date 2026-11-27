import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../l10n/localizations.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../core/theme/redesign_tokens.dart';
import '../workspace/product_widgets.dart';
import 'session_controller.dart';
import 'profile_controller.dart';
import 'product_welcome.dart';
import 'product_auth_layout.dart';
import 'product_auth_feedback.dart';
import 'redesign_auth_field.dart';
import 'redesign_me_screen.dart';

class ProductAccountScreen extends StatefulWidget {
  const ProductAccountScreen({super.key});
  @override
  State<ProductAccountScreen> createState() => _ProductAccountScreenState();
}

class _ProductAccountScreenState extends State<ProductAccountScreen> {
  String _email = '', _password = '', _token = '', _name = '';
  bool _register = false, _loginForm = false;
  bool get _validEmail => RegExp(r'^\S+@\S+\.\S+$').hasMatch(_email.trim());
  void _screen({required bool register, bool login = true}) {
    FocusScope.of(context).unfocus();
    setState(() {
      _register = register;
      _loginForm = login;
      _password = '';
      _token = '';
    });
  }

  Future<void> _submit(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    await action();
  }

  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.session, r.profile],
    builder: (context, r) {
      final s = r.session, l = context.l10n;
      if (s.stage == SessionStage.authenticated) return ProductMeScreen(runtime: r);
      final preview = s.repository.isDevelopment;
      final verifying = s.stage == SessionStage.awaitingVerification;
      final recovery = [
        SessionStage.recoveryRequest,
        SessionStage.recoverySent,
        SessionStage.recoveryConfirm,
      ].contains(s.stage);
      final sent = s.stage == SessionStage.recoverySent, reset = s.stage == SessionStage.recoveryConfirm;
      final welcome = !verifying && !recovery && !_loginForm && !_register;
      final validCode = preview ? _token.isNotEmpty : RegExp(r'^[0-9]{6}$').hasMatch(_token);
      final passwordLength = _password.runes.length;
      final validPassword = passwordLength >= ((_register || reset) ? 5 : 1) && passwordLength <= 128;
      final enabled = !s.busy && !s.coolingDown;
      final title = verifying
          ? l.uxVerifyTitle
          : reset
          ? l.uxResetTitle
          : sent
          ? l.uxRecoverySentTitle
          : recovery
          ? l.uxRecoveryTitle
          : _register
          ? l.rdMk
          : l.rdWb;
      final subtitle = verifying
          ? l.apiVerifyHint
          : reset
          ? l.apiResetHint
          : sent
          ? l.authRecoverySentHint
          : recovery
          ? l.authRecoveryHint
          : _register
          ? l.rdMks
          : l.rdWbs;
      final notice = switch (s.notice) {
        'verified' => l.apiVerified,
        'reset' => l.apiResetComplete,
        'localLogout' || 'logout' => l.apiSignedOut,
        'verificationRequested' => verifying ? null : l.apiCodeAcknowledgment,
        _ => null,
      };
      Future<void> authenticate() => _submit(() async {
        if (_register) {
          // The public registration schema remains email/password. A successful
          // registration stages the device-owned name until verified sign-in.
          final address = _email, name = _name;
          await s.register(address, _password);
          if (s.stage == SessionStage.awaitingVerification && s.failure == null) {
            await r.profile.stageRegistration(address, name);
          }
        } else {
          await s.login(_email, _password);
        }
      });
      final children = <Widget>[
        if (notice != null) Semantics(liveRegion: true, child: RdText(notice, size: 13, color: context.rd.muted)),
        if (s.stage == SessionStage.expired) RdText(l.productYourSessionExpiredSignInAgain, color: context.rd.muted),
        if (welcome)
          ProductWelcome(
            busy: s.busy,
            preview: preview,
            onSignup: enabled ? () => _screen(register: true) : null,
            onLogin: enabled ? () => _screen(register: false) : null,
            onSample: enabled ? () => s.login('reader@example.invalid', 'fixture-only') : null,
            onEmpty: enabled ? () => s.login('other@example.invalid', 'fixture-only') : null,
          )
        else ...[
          if (_register && !verifying && !recovery)
            RedesignAuthField(
              key: const ValueKey('account-name'),
              value: _name,
              label: l.rdNm,
              onChanged: (v) => setState(() => _name = v),
              enabled: !s.busy,
              autofillHints: const [AutofillHints.givenName],
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
            ),
          if (!verifying && !reset && !sent)
            RedesignAuthField(
              key: const ValueKey('account-email'),
              value: _email,
              label: l.rdEm,
              onChanged: (v) => setState(() => _email = v),
              enabled: !s.busy,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              action: recovery ? TextInputAction.done : TextInputAction.next,
            ),
          if (verifying || reset) ...[
            RdText(s.email, size: 13, color: context.rd.muted, direction: TextDirection.ltr),
            RedesignAuthField(
              key: const ValueKey('account-token'),
              value: _token,
              label: preview ? l.productFixtureActionToken : l.apiSixDigitCode,
              onChanged: (v) => setState(() => _token = v),
              enabled: !s.busy,
              keyboardType: preview ? null : TextInputType.number,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: preview
                  ? null
                  : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              action: reset ? TextInputAction.next : TextInputAction.done,
            ),
          ],
          if ((!verifying && !recovery) || reset)
            RedesignAuthField(
              key: const ValueKey('account-password'),
              value: _password,
              label: reset ? l.apiNewPassword : l.rdPw,
              password: true,
              onChanged: (v) => setState(() => _password = v),
              enabled: !s.busy,
              textDirection: TextDirection.ltr,
              action: TextInputAction.done,
              autofillHints: [reset || _register ? AutofillHints.newPassword : AutofillHints.password],
            ),
          if (_register && !verifying && !recovery) ...[_PasswordStrength(value: _password)],
          if (!verifying && !recovery && !_register)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _AuthLink(
                l.rdFg,
                onPressed: enabled
                    ? () {
                        _screen(register: false);
                        s.show(SessionStage.recoveryRequest);
                      }
                    : null,
              ),
            ),
          if (s.failure != null)
            ProductAuthFeedback(s.failure!)
          else if (r.profile.failure != null)
            ProductFailureView(r.profile.failure!)
          else if (!verifying && !recovery)
            SizedBox(
              height: 20,
              child: _register && _email.isNotEmpty && !_validEmail
                  ? RdText(l.rdEmerr, size: 13, color: context.rd.red)
                  : null,
            ),
          if (verifying) ...[
            RdButton(
              l.apiVerifyEmail,
              key: const ValueKey('verify-email'),
              loading: s.busy,
              onPressed: enabled && validCode
                  ? () => _submit(() async {
                      await s.verify(_token);
                      if (mounted && s.stage == SessionStage.unauthenticated) _screen(register: false);
                    })
                  : null,
            ),
            _AuthLink(l.apiResendCode, onPressed: enabled ? s.resend : null),
          ] else if (recovery) ...[
            if (sent) ...[
              RdText(l.apiRecoveryAcknowledgment, color: context.rd.muted),
              RdButton(l.apiHaveCode, onPressed: enabled ? () => s.show(SessionStage.recoveryConfirm) : null),
            ] else if (reset) ...[
              RdButton(
                l.uxResetPassword,
                loading: s.busy,
                onPressed: enabled && validCode && validPassword
                    ? () => _submit(() async {
                        await s.confirmRecovery(_token, _password);
                        if (mounted && s.stage == SessionStage.unauthenticated) _screen(register: false);
                      })
                    : null,
              ),
              _AuthLink(l.apiResendCode, onPressed: enabled ? () => s.recover(s.email) : null),
            ] else
              RdButton(
                l.uxRequestReset,
                loading: s.busy,
                onPressed: enabled && _validEmail ? () => _submit(() => s.recover(_email)) : null,
              ),
            _AuthLink(
              l.productBackToSignIn,
              onPressed: enabled
                  ? () {
                      _screen(register: false);
                      s.show(SessionStage.unauthenticated);
                    }
                  : null,
            ),
          ] else ...[
            RdButton(
              _register ? l.rdMk : l.rdLi,
              key: const ValueKey('account-submit'),
              loading: s.busy,
              onPressed: enabled && _validEmail && validPassword && (!_register || ProfileController.validName(_name))
                  ? authenticate
                  : null,
            ),
            if (_register) RdText(l.rdTerms, size: 12.5, color: context.rd.muted, align: TextAlign.center),
            _AuthLink(
              _register ? l.rdAh : l.rdNw,
              onPressed: enabled
                  ? () {
                      _screen(register: !_register);
                      s.show(s.stage);
                    }
                  : null,
            ),
          ],
        ],
      ];
      return ProductAuthLayout(
        key: ValueKey((welcome, verifying, recovery, reset, _register)),
        title: title,
        subtitle: welcome ? null : subtitle,
        welcome: welcome,
        onBack: enabled
            ? () {
                _screen(register: false, login: verifying || recovery);
                if (verifying || recovery) s.show(SessionStage.unauthenticated);
              }
            : null,
        children: children,
      );
    },
  );
}

class _AuthLink extends StatelessWidget {
  const _AuthLink(this.label, {this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: context.rd.blue,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: const Size(44, 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: RdTokens.style(context),
    ),
    onPressed: onPressed,
    child: Text(label, textAlign: TextAlign.center),
  );
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    final n = value.runes.length;
    final s = n < 5
        ? 0
        : n >= 8 && RegExp(r'\d').hasMatch(value)
        ? 3
        : n >= 8
        ? 2
        : 1;
    final c = [context.rd.surface2, context.rd.red, context.rd.orange, const Color(0xff3fb868)][s];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Row(
          spacing: 4,
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < s ? c : context.rd.surface2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
        RdText(
          [context.l10n.rdPwh, context.l10n.rdS1, context.l10n.rdS2, context.l10n.rdS3][s],
          size: 13,
          color: context.rd.muted,
        ),
      ],
    );
  }
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
