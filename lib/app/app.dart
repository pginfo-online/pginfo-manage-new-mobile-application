import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/theme.dart';
import 'di/providers.dart';
import '../shared/components/common.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/property/presentation/property_screens.dart';
import '../features/property/presentation/property_dashboard_screen.dart';
import '../features/property/presentation/room_form_screen.dart';
import '../features/people/presentation/people_screen.dart';
import '../features/money/presentation/money_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/tenants/presentation/tenant_screens.dart';
import '../features/tenants/presentation/add_tenant_screen.dart';
import '../features/all/presentation/all_screen.dart';
import '../features/all/presentation/action_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider).value;
      if (session == null && state.uri.path != '/login') return '/login';
      if (session != null && state.uri.path == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/money',
                builder: (context, state) => const MoneyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/all',
                builder: (context, state) => const AllScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/people',
                builder: (context, state) => const PeopleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/property',
                builder: (context, state) => const PropertyDashboardScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/properties/select',
        builder: (context, state) => const PropertySelectScreen(),
      ),
      GoRoute(
        path: '/organizations/select',
        builder: (context, state) => const OrganizationSelectScreen(),
      ),
      GoRoute(
        path: '/properties/new',
        builder: (context, state) => const PropertyFormScreen(),
      ),
      GoRoute(
        path: '/rooms/new',
        builder: (context, state) => const RedesignedRoomFormScreen(),
      ),
      GoRoute(
        path: '/rooms/:id/edit',
        builder: (context, state) =>
            RedesignedRoomFormScreen(id: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/rooms/filter',
        builder: (context, state) => const RoomFilterScreen(),
      ),
      GoRoute(
        path: '/rooms/:id',
        builder: (context, state) =>
            RoomDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tenants/new',
        builder: (context, state) => AddTenantScreen(
          initialRoomId: state.uri.queryParameters['roomId'],
          initialBedId: state.uri.queryParameters['bedId'],
        ),
      ),
      GoRoute(
        path: '/tenants/:id',
        builder: (context, state) =>
            TenantDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: '/action/:name',
        builder: (context, state) => ActionScreen(
          name: state.pathParameters['name']!,
          query: state.uri.queryParameters,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class PgInfoApp extends ConsumerWidget {
  const PgInfoApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if ((!session.hasValue && session.isLoading) || session.hasError) {
      return MaterialApp(
        theme: PgTheme.build(Brightness.light),
        darkTheme: PgTheme.build(Brightness.dark),
        home: Scaffold(
          body: Center(
            child: session.hasError
                ? FilledButton(
                    onPressed: () => ref.invalidate(sessionProvider),
                    child: const Text('Retry opening PgInfo'),
                  )
                : const PgLogo(size: 94),
          ),
        ),
      );
    }
    return MaterialApp.router(
      title: 'PgInfo',
      theme: PgTheme.build(Brightness.light),
      darkTheme: PgTheme.build(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) =>
          shell.goBranch(index, initialLocation: index == shell.currentIndex),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Money',
        ),
        NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'All'),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'People',
        ),
        NavigationDestination(
          icon: Icon(Icons.apartment_outlined),
          selectedIcon: Icon(Icons.apartment),
          label: 'Property',
        ),
      ],
    ),
  );
}
