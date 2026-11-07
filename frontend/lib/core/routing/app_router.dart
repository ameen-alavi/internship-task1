import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../widgets/responsive_scaffold.dart';
import '../../features/approvals/screens/approvals_queue_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/registration_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/enquiries/screens/create_enquiry_screen.dart';
import '../../features/enquiries/screens/edit_enquiry_screen.dart';
import '../../features/enquiries/screens/enquiry_details_screen.dart';
import '../../features/enquiries/screens/enquiry_list_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/workflow/screens/create_request_screen.dart';
import '../../features/workflow/screens/request_details_screen.dart';
import '../../features/workflow/screens/workflow_list_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static GoRouter create(AuthProvider authProvider) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final auth = authProvider;
      if (!auth.isInitialized) return null;
      final onLogin = state.uri.path == '/login';
      final onRegister = state.uri.path == '/register';
      if (!auth.isLoggedIn && !onLogin && !onRegister) return '/login';
      if (auth.isLoggedIn && (onLogin || onRegister)) return '/dashboard';
      if (state.uri.path.startsWith('/approvals') && !auth.isApprover) {
        return '/dashboard';
      }
      if ((state.uri.path == '/enquiries/new' ||
              state.uri.path.endsWith('/edit')) &&
          !auth.isRequester) {
        return '/dashboard';
      }
      if (state.uri.path == '/workflows/new' && !auth.isRequester) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      // Standalone Login Route
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),

      // Shell Route wrapping all authenticated screens with ResponsiveScaffold
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ResponsiveScaffold(currentRoute: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/enquiries',
            builder: (context, state) => const EnquiryListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CreateEnquiryScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return EnquiryDetailsScreen(enquiryId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return EditEnquiryScreen(enquiryId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/workflows',
            builder: (context, state) => const WorkflowListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) {
                  final category = state.uri.queryParameters['category'];
                  return CreateRequestScreen(initialCategory: category);
                },
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return RequestDetailsScreen(requestId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/approvals',
            builder: (context, state) => const ApprovalsQueueScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
