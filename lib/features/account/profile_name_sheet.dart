import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../l10n/localizations.dart';
import '../workspace/product_widgets.dart';
import 'profile_controller.dart';
import 'redesign_auth_field.dart';

Future<void> editProfileName(BuildContext context, ProfileController profile) =>
    rdSheet<void>(context, child: _NameForm(profile: profile));

class _NameForm extends StatefulWidget {
  const _NameForm({required this.profile});
  final ProfileController profile;
  @override
  State<_NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<_NameForm> {
  late String _name = widget.profile.name ?? '';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.profile,
    builder: (context, _) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        RdText(context.l10n.rdEditName, size: 18, weight: FontWeight.w600),
        RedesignAuthField(
          value: _name,
          label: context.l10n.rdNm,
          onChanged: (v) => setState(() => _name = v),
          enabled: !widget.profile.busy,
          autofillHints: const [AutofillHints.givenName],
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
          action: TextInputAction.done,
        ),
        RdText(context.l10n.rdNameDevice, size: 13, color: context.rd.muted),
        if (widget.profile.failure != null) ProductFailureView(widget.profile.failure!),
        RdButton(
          context.l10n.rdSave,
          loading: widget.profile.busy,
          onPressed: ProfileController.validName(_name)
              ? () async {
                  FocusScope.of(context).unfocus();
                  if (await widget.profile.setName(_name) && context.mounted) Navigator.pop(context);
                }
              : null,
        ),
      ],
    ),
  );
}
