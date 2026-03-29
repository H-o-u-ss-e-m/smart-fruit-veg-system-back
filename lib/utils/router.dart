import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/vendor/vendor_main_screen.dart';
import '../screens/vendor/vendor_dashboard_screen.dart';
import '../screens/vendor/inventory_screen.dart';
import '../screens/vendor/alerts_screen.dart';
import '../screens/client/client_main_screen.dart';

// ── Routes nommées ───────────────────────────────────────────────────
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const vendorMain = '/vendor';
  static const inventory = '/vendor/inventory';
  static const vendorAlerts = '/vendor/alerts';
  static const clientMain = '/client';
  static const catalogue = '/client/catalogue';
}

// ── Router Provider ──────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // ── Auth ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (ctx, s) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (ctx, s) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (ctx, s) => const RegisterScreen(),
      ),

      // ── Vendeur Shell ────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, s, child) => VendorMainScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.vendorMain,
            builder: (ctx, s) => const VendorDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.inventory,
            builder: (ctx, s) => const InventoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.vendorAlerts,
            builder: (ctx, s) => const AlertsScreen(),
          ),
        ],
      ),

      // ── Client Shell ─────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, s, child) => ClientMainScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.clientMain,
            builder: (ctx, s) => const ClientDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.catalogue,
            builder: (ctx, s) => const CatalogueScreen(),
          ),
        ],
      ),
    ],
  );
});