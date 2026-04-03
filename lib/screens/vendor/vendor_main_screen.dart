import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/router.dart';

class VendorMainScreen extends ConsumerWidget {
  final Widget child;
  const VendorMainScreen({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.inventory)) return 1;
    if (location.startsWith(AppRoutes.vendorAlerts)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final unreadCount = ref.watch(unreadAlertsCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) {
            switch (i) {
              case 0: context.go(AppRoutes.vendorMain);
              case 1: context.go(AppRoutes.inventory);
              case 2: context.go(AppRoutes.vendorAlerts);
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Tableau de bord',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventaire',
            ),
            BottomNavigationBarItem(
              icon: unreadCount.when(
                data: (count) => Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                loading: () => const Icon(Icons.notifications_outlined),
                error: (_, __) => const Icon(Icons.notifications_outlined),
              ),
              activeIcon: const Icon(Icons.notifications),
              label: 'Alertes',
            ),
          ],
        ),
      ),
    );
  }
}