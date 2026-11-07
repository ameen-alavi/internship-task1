import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/repositories/auth_repository.dart';
import 'package:frontend/data/repositories/enquiry_repository.dart';
import 'package:frontend/data/repositories/notification_repository.dart';
import 'package:frontend/data/repositories/workflow_repository.dart';
import 'package:frontend/features/enquiries/screens/create_enquiry_screen.dart';
import 'package:frontend/features/enquiries/screens/enquiry_details_screen.dart';
import 'package:frontend/features/enquiries/screens/enquiry_list_screen.dart';
import 'package:frontend/features/enquiries/widgets/enquiry_pagination_bar.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/enquiry_provider.dart';
import 'package:frontend/providers/notification_provider.dart';
import 'package:frontend/providers/workflow_provider.dart';
import 'package:provider/provider.dart';
import 'helpers/enquiry_fixtures.dart';

Widget _buildTestApp({
  required Widget child,
  required MockEnquiryRepository enquiryRepo,
  Size screenSize = const Size(1440, 900),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthProvider(authRepository: MockAuthRepository()),
      ),
      ChangeNotifierProvider(
        create: (_) =>
            WorkflowProvider(workflowRepository: MockWorkflowRepository()),
      ),
      ChangeNotifierProvider(
        create: (_) => NotificationProvider(
          notificationRepository: MockNotificationRepository(),
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => EnquiryProvider(enquiryRepository: enquiryRepo),
      ),
    ],
    child: ScreenUtilInit(
      designSize: screenSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp(home: child),
    ),
  );
}

void main() {
  group('Enquiry Screens Widget & Interaction Tests', () {
    late MockEnquiryRepository enquiryRepo;

    setUp(() {
      enquiryRepo = MockEnquiryRepository(
        initialEnquiries: enquiryTestFixtures(),
      );
    });

    testWidgets(
      'EnquiryListScreen renders header, search, list, and pagination controls',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _buildTestApp(
            child: const EnquiryListScreen(),
            enquiryRepo: enquiryRepo,
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Header & Action
        expect(find.text('Institutional Enquiries'), findsOneWidget);
        expect(find.text('New Enquiry'), findsOneWidget);

        // Search & Filters
        expect(find.byType(TextField), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'All Statuses'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'Open'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'In Progress'), findsOneWidget);

        // Pagination Bar
        expect(find.byType(EnquiryPaginationBar), findsOneWidget);
        expect(find.text('Prev'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
        expect(find.textContaining('Page 1 of'), findsOneWidget);
      },
    );

    testWidgets('EnquiryPaginationBar Next button advances page', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const EnquiryListScreen(),
          enquiryRepo: enquiryRepo,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Page 1 of 2'), findsOneWidget);

      // Tap Next button
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Page 2 of 2'), findsOneWidget);
    });

    testWidgets(
      'Error card renders when network fails and retry triggers reload',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        enquiryRepo.setSimulateNetworkFailure(true);

        await tester.pumpWidget(
          _buildTestApp(
            child: const EnquiryListScreen(),
            enquiryRepo: enquiryRepo,
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Unable to load enquiries'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Clear error and tap Retry
        enquiryRepo.setSimulateNetworkFailure(false);
        await tester.tap(find.text('Retry'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Unable to load enquiries'), findsNothing);
        expect(find.text('Institutional Enquiries'), findsOneWidget);
      },
    );

    testWidgets('CreateEnquiryScreen validates mandatory fields and formats', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const CreateEnquiryScreen(),
          enquiryRepo: enquiryRepo,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Submit New Enquiry'), findsOneWidget);
      expect(find.text('Submit Enquiry'), findsOneWidget);

      // Scroll submit button into view and tap with empty subject and description
      await tester.ensureVisible(find.text('Submit Enquiry'));
      await tester.tap(find.text('Submit Enquiry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please provide a clear subject (at least 6 characters)'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Please provide sufficient description (minimum 15 characters)',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'EnquiryDetailsScreen displays enquiry data and reply thread without requester lifecycle actions',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _buildTestApp(
            child: const EnquiryDetailsScreen(enquiryId: 'ENQ-2026-001'),
            enquiryRepo: enquiryRepo,
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('ENQ-2026-001'), findsOneWidget);
        expect(find.text('Edit Enquiry'), findsOneWidget);
        expect(find.text('ENQUIRY DESCRIPTION'), findsOneWidget);
        expect(find.text('LIFECYCLE STATUS & TRANSITIONS'), findsNothing);
        expect(find.text('RESPONSE & REMARKS THREAD'), findsOneWidget);
        expect(find.text('Resolve'), findsNothing);
      },
    );

    testWidgets(
      'Responsive Layout: Mobile viewport rendering without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _buildTestApp(
            child: const EnquiryListScreen(),
            enquiryRepo: enquiryRepo,
            screenSize: const Size(375, 812),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Institutional Enquiries'), findsOneWidget);
        expect(find.byType(EnquiryPaginationBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
