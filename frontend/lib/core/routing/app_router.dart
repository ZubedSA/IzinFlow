import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/student_dashboard.dart';
import '../../features/dashboard/presentation/pages/teacher_dashboard.dart';
import '../../features/dashboard/presentation/pages/org_admin_dashboard.dart';
import '../../features/dashboard/presentation/pages/super_admin_dashboard.dart';
import '../../features/permission/presentation/pages/new_permission_page.dart';

// Track logged in role for dynamic redirects
final userRoleProvider = StateProvider<String?>((ref) => null);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final role = ref.read(userRoleProvider);
      final isLoggingIn = state.matchedLocation == '/login';

      if (role == null) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        if (role == 'STUDENT') {
          return '/student/dashboard';
        } else if (role == 'TEACHER') {
          return '/teacher/dashboard';
        } else if (role == 'ORG_ADMIN') {
          return '/org-admin/dashboard';
        } else if (role == 'SUPER_ADMIN') {
          return '/super-admin/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/student/dashboard',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/student/new-permission',
        builder: (context, state) => const NewPermissionPage(),
      ),
      GoRoute(
        path: '/teacher/dashboard',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: '/org-admin/dashboard',
        builder: (context, state) => const OrgAdminDashboard(),
      ),
      GoRoute(
        path: '/super-admin/dashboard',
        builder: (context, state) => const SuperAdminDashboard(),
      ),
    ],
  );
});
