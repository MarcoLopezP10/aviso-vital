import 'package:flutter/material.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_widgets.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';

class AdminHomeShell extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> pages;

  const AdminHomeShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = isAdminWideLayout(context);

    if (isWide) {
      return PremiumScreenScaffold(
        variant: PremiumBackgroundVariant.dashboard,
        primaryGlowColor: AppColors.amber,
        secondaryGlowColor: AppColors.haloBlue,
        primaryGlowAlignment: const Alignment(-1, -0.95),
        secondaryGlowAlignment: const Alignment(1, -0.75),
        intensity: 0.5,
        body: Row(
          children: [
            AdminSidebar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
            Expanded(
              child: IndexedStack(index: selectedIndex, children: pages),
            ),
          ],
        ),
      );
    }

    return PremiumScreenScaffold(
      variant: PremiumBackgroundVariant.dashboard,
      primaryGlowColor: AppColors.amber,
      secondaryGlowColor: AppColors.haloBlue,
      primaryGlowAlignment: const Alignment(0, -0.95),
      secondaryGlowAlignment: const Alignment(1, -0.55),
      intensity: 0.48,
      extendBody: true,
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: AdminBottomNav(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}
