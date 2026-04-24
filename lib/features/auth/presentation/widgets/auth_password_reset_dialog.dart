import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aviso_vital_2/data/repositories/auth_repository.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/utils/validators.dart';

Future<void> showAuthPasswordResetDialog(
  BuildContext context, {
  required AuthRepository authRepository,
  String initialEmail = '',
}) async {
  final strings = context.t;
  final emailCtrl = TextEditingController(text: initialEmail.trim());
  var isSubmitting = false;
  String? errorText;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submit() async {
            final email = emailCtrl.text.trim();
            if (email.isEmpty) {
              setDialogState(() => errorText = strings.enterEmail);
              return;
            }
            if (!AppValidators.isValidEmail(email)) {
              setDialogState(() => errorText = strings.invalidEmail);
              return;
            }

            setDialogState(() {
              isSubmitting = true;
              errorText = null;
            });

            try {
              await authRepository.sendPasswordResetEmail(email: email);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.passwordResetSent)),
              );
            } catch (error) {
              if (!dialogContext.mounted) return;
              setDialogState(() {
                isSubmitting = false;
                errorText = _mapPasswordResetError(error, strings);
              });
            }
          }

          return AlertDialog(
            title: Text(strings.forgotPassword),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.passwordResetDialogDescription,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: strings.email,
                      errorText: errorText,
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(strings.text('Cancelar')),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.passwordResetAction),
              ),
            ],
          );
        },
      );
    },
  );

  emailCtrl.dispose();
}

String _mapPasswordResetError(Object error, AppStrings strings) {
  final message = error.toString().replaceFirst('Bad state: ', '');
  if (error is AuthException && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return strings.passwordResetFailed(message);
}
