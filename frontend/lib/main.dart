import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/enquiry_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/workflow_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/enquiry_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/workflow_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InstitutionalWorkflowApp());
}

class InstitutionalWorkflowApp extends StatelessWidget {
  const InstitutionalWorkflowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Repositories (Swappable for ApiWorkflowRepository / ApiAuthRepository later)
    final authRepository = MockAuthRepository();
    final authProvider = AuthProvider(authRepository: authRepository);
    final router = AppRouter.create(authProvider);
    final workflowRepository = MockWorkflowRepository();
    final notificationRepository = MockNotificationRepository();
    final notificationProvider = NotificationProvider(
      notificationRepository: notificationRepository,
    );
    authProvider.addListener(
      () => notificationProvider.setRecipient(authProvider.currentUser?.id),
    );
    final enquiryRepository = MockEnquiryRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => WorkflowProvider(
            workflowRepository: workflowRepository,
            notifyUser: notificationProvider.addNotification,
          ),
        ),
        ChangeNotifierProvider.value(value: notificationProvider),
        ChangeNotifierProvider(
          create: (_) => EnquiryProvider(
            enquiryRepository: enquiryRepository,
            notifyUser: notificationProvider.addNotification,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ScreenUtilInit(
            designSize: const Size(1440, 900),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp.router(
                title: AppStrings.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: themeProvider.themeMode,
                routerConfig: router,
              );
            },
          );
        },
      ),
    );
  }
}
