import 'package:flutter/material.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class AppDetailScaffold extends StatelessWidget {
  final String? title;
  final Widget? header;
  final Widget content;
  final Widget? bottomAction;
  final List<Widget>? actions;
  final EdgeInsetsGeometry contentPadding;
  final bool scrollable;

  const AppDetailScaffold({
    super.key,
    this.title,
    this.header,
    required this.content,
    this.bottomAction,
    this.actions,
    this.contentPadding = const EdgeInsets.all(AppSpacing.xl),
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final bodyContent = Padding(
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            header!,
            const SizedBox(height: AppSpacing.xxl),
          ],
          content,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: const AppBackButton(),
        title: title != null ? Text(context.t.text(title!)) : null,
        actions: actions,
      ),
      body: Column(
        children: [
          Expanded(
            child: scrollable
                ? SingleChildScrollView(child: bodyContent)
                : bodyContent,
          ),
          if (bottomAction != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: bottomAction!,
              ),
            ),
        ],
      ),
    );
  }
}
