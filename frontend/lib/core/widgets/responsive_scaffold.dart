import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../theme/theme_provider.dart';
import '../utils/responsive_helper.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/workflow_provider.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const ResponsiveScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  int _calculateSelectedIndex() {
    if (currentRoute.startsWith('/dashboard')) {
      return 0;
    }
    if (currentRoute.startsWith('/workflows/new')) {
      return 2;
    }
    if (currentRoute.startsWith('/enquiries/new')) return 6;
    if (currentRoute.startsWith('/enquiries')) return 7;
    if (currentRoute.startsWith('/workflows')) return 1;
    if (currentRoute.startsWith('/approvals')) {
      return 3;
    }
    if (currentRoute.startsWith('/notifications')) {
      return 4;
    }
    if (currentRoute.startsWith('/profile')) {
      return 5;
    }
    return 0;
  }

  void _onNavigationItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/workflows');
        break;
      case 2:
        context.go('/workflows/new');
        break;
      case 3:
        context.go('/approvals');
        break;
      case 4:
        context.go('/notifications');
        break;
      case 5:
        context.go('/profile');
        break;
      case 6:
        context.go('/enquiries/new');
        break;
      case 7:
        context.go('/enquiries');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final workflowProvider = context.watch<WorkflowProvider>();

    final selectedIndex = _calculateSelectedIndex();
    final user = authProvider.currentUser;
    final unreadNotifications = notificationProvider.unreadCount;
    final pendingApprovalsCount = workflowProvider.pendingApprovals
        .where((request) => workflowProvider.canReview(request, user))
        .length;

    // Mobile layout: BottomNavigationBar + top AppBar + Drawer
    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppDimensions.roundedSmall,
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              const Expanded(
                child: Text(
                  AppStrings.appName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            Text(
              authProvider.currentRole.shortLabel,
              style: const TextStyle(fontSize: 11),
            ),
            IconButton(
              icon: Badge(
                isLabelVisible: unreadNotifications > 0,
                label: Text('$unreadNotifications'),
                child: const Icon(Icons.notifications_outlined, size: 22),
              ),
              onPressed: () => context.go('/notifications'),
            ),
          ],
        ),
        drawer: _buildAppDrawer(context, authProvider, selectedIndex),
        body: child,
      );
    }

    // Desktop & Tablet Layout with NavigationRail / Sidebar
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar / Rail
          _buildSidebar(
            context,
            isDesktop: isDesktop,
            isTablet: isTablet,
            selectedIndex: selectedIndex,
            unreadNotifications: unreadNotifications,
            pendingApprovalsCount: pendingApprovalsCount,
            authProvider: authProvider,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Main Content Area with Header
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(
                  context,
                  user: user,
                  authProvider: authProvider,
                  unreadNotifications: unreadNotifications,
                  isDark: isDark,
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context, {
    required bool isDesktop,
    required bool isTablet,
    required int selectedIndex,
    required int unreadNotifications,
    required int pendingApprovalsCount,
    required AuthProvider authProvider,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final width = isDesktop
        ? AppDimensions.navigationRailWidth
        : AppDimensions.navigationRailCompactWidth;

    return Container(
      width: width,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding
          Container(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.topBarHeight,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 16,
              vertical: 8,
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppDimensions.roundedMedium,
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: AppDimensions.space12),
                  const Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EduSphere',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          'Workflow Platform',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.space12),

          // Primary Navigation Links
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 8),
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: AppStrings.navDashboard,
                  isSelected: selectedIndex == 0,
                  isDesktop: isDesktop,
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder_rounded,
                  label: AppStrings.navWorkflows,
                  isSelected: selectedIndex == 1,
                  isDesktop: isDesktop,
                ),
                if (authProvider.isRequester)
                  _buildNavItem(
                    context,
                    index: 2,
                    icon: Icons.add_circle_outline_rounded,
                    activeIcon: Icons.add_circle_rounded,
                    label: AppStrings.navNewRequest,
                    isSelected: selectedIndex == 2,
                    isDesktop: isDesktop,
                  ),
                if (authProvider.isApprover)
                  _buildNavItem(
                    context,
                    index: 3,
                    icon: Icons.fact_check_outlined,
                    activeIcon: Icons.fact_check_rounded,
                    label: AppStrings.navApprovals,
                    isSelected: selectedIndex == 3,
                    isDesktop: isDesktop,
                    badgeCount: pendingApprovalsCount,
                    badgeColor: AppColors.statusPending,
                  ),
                if (authProvider.isApprover)
                  _buildNavItem(
                    context,
                    index: 7,
                    icon: Icons.question_answer_outlined,
                    activeIcon: Icons.question_answer,
                    label: 'Enquiries',
                    isSelected: selectedIndex == 7,
                    isDesktop: isDesktop,
                  ),
                if (authProvider.isRequester)
                  _buildNavItem(
                    context,
                    index: 6,
                    icon: Icons.add_circle_outline_rounded,
                    activeIcon: Icons.add_circle_rounded,
                    label: 'New Enquiry',
                    isSelected: currentRoute.startsWith('/enquiries/new'),
                    isDesktop: isDesktop,
                  ),
                _buildNavItem(
                  context,
                  index: 4,
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications_rounded,
                  label: AppStrings.navNotifications,
                  isSelected: selectedIndex == 4,
                  isDesktop: isDesktop,
                  badgeCount: unreadNotifications,
                  badgeColor: AppColors.primaryLight,
                ),
                _buildNavItem(
                  context,
                  index: 5,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: AppStrings.navProfile,
                  isSelected: selectedIndex == 5,
                  isDesktop: isDesktop,
                ),
              ],
            ),
          ),

          // Active role and logout
          if (isDesktop) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIVE ROLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondaryLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    authProvider.currentRole.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await authProvider.logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Log out'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required bool isDesktop,
    int badgeCount = 0,
    Color? badgeColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeBg = (isDark ? AppColors.primaryLight : AppColors.primary)
        .withValues(alpha: 0.12);
    final activeFg = isDark ? AppColors.primaryLight : AppColors.primary;
    final inactiveFg = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: AppDimensions.roundedMedium,
        child: InkWell(
          onTap: () => _onNavigationItemTapped(context, index),
          borderRadius: AppDimensions.roundedMedium,
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 0),
            alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
            child: Row(
              mainAxisAlignment: isDesktop
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? activeFg : inactiveFg,
                ),
                if (isDesktop) ...[
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected ? activeFg : inactiveFg,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor ?? AppColors.primary,
                        borderRadius: AppDimensions.roundedFull,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(
    BuildContext context, {
    required User? user,
    required AuthProvider authProvider,
    required int unreadNotifications,
    required bool isDark,
  }) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      height: AppDimensions.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Row(
        children: [
          // Current Page Title or Breadcrumb
          Text(
            _getRouteTitle(currentRoute),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),

          // Dark Mode Toggle
          IconButton(
            tooltip: themeProvider.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          const SizedBox(width: AppDimensions.space8),

          // Notifications Bell
          IconButton(
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              child: const Icon(Icons.notifications_outlined, size: 22),
            ),
            onPressed: () => context.go('/notifications'),
          ),
          const SizedBox(width: AppDimensions.space16),

          // User Info & Avatar
          if (user != null)
            InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: AppDimensions.roundedMedium,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        user.name.split(' ').map((e) => e[0]).take(2).join(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user.role.shortLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleSwitcherDropdown(
    BuildContext context,
    AuthProvider authProvider, {
    required bool compact,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppDimensions.roundedMedium,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.swap_horiz_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                authProvider.currentRole.shortLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildAppDrawer(
    BuildContext context,
    AuthProvider authProvider,
    int selectedIndex,
  ) {
    final user = authProvider.currentUser;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            if (user != null)
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: AppColors.primary),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    user.name.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                accountName: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                accountEmail: Text(user.email),
              ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text(AppStrings.navDashboard),
              selected: selectedIndex == 0,
              onTap: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text(AppStrings.navWorkflows),
              selected: selectedIndex == 1,
              onTap: () {
                Navigator.pop(context);
                context.go('/workflows');
              },
            ),
            if (authProvider.isRequester)
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text(AppStrings.navNewRequest),
                selected: selectedIndex == 2,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/workflows/new');
                },
              ),
            if (authProvider.isApprover)
              ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text(AppStrings.navApprovals),
                selected: selectedIndex == 3,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/approvals');
                },
              ),
            if (authProvider.isApprover)
              ListTile(
                leading: const Icon(Icons.question_answer_outlined),
                title: const Text('Enquiries'),
                selected: selectedIndex == 7,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/enquiries');
                },
              ),
            if (authProvider.isRequester)
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('New Enquiry'),
                selected: currentRoute.startsWith('/enquiries/new'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/enquiries/new');
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text(AppStrings.navNotifications),
              selected: selectedIndex == 4,
              onTap: () {
                Navigator.pop(context);
                context.go('/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text(AppStrings.navProfile),
              selected: selectedIndex == 5,
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () async {
                await authProvider.logout();
                if (context.mounted) context.go('/login');
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.brightness_medium_outlined),
              title: const Text('Toggle Dark Mode'),
              onTap: () => context.read<ThemeProvider>().toggleTheme(),
            ),
          ],
        ),
      ),
    );
  }

  String _getRouteTitle(String route) {
    if (route.startsWith('/dashboard')) {
      return 'Executive Dashboard';
    }
    if (route.startsWith('/enquiries/new')) {
      return 'New Enquiry';
    }
    if (route.endsWith('/edit')) {
      return 'Edit Enquiry';
    }
    if (route.startsWith('/enquiries/')) {
      return 'Enquiry Details';
    }
    if (route.startsWith('/enquiries')) {
      return 'Institutional Enquiries';
    }
    if (route.startsWith('/workflows/new')) {
      return 'New Workflow Application';
    }
    if (route.startsWith('/workflows/')) {
      return 'Workflow Details';
    }
    if (route.startsWith('/workflows')) {
      return 'Workflow Requests';
    }
    if (route.startsWith('/approvals')) {
      return 'Approval Queue';
    }
    if (route.startsWith('/notifications')) {
      return 'Institutional Notifications';
    }
    if (route.startsWith('/profile')) {
      return 'Profile & Settings';
    }
    return AppStrings.appName;
  }
}
