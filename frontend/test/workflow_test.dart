import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/validators.dart';
import 'package:frontend/data/models/user_model.dart';
import 'package:frontend/data/models/workflow_request_model.dart';
import 'package:frontend/data/models/notification_model.dart';
import 'package:frontend/data/mock/mock_users.dart';
import 'package:frontend/data/repositories/notification_repository.dart';
import 'package:frontend/data/repositories/auth_repository.dart';
import 'package:frontend/data/repositories/workflow_repository.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/workflow_provider.dart';

void main() {
  group('Validators Unit Tests', () {
    test('requiredField validates null and empty strings', () {
      expect(Validators.requiredField(null), isNotNull);
      expect(Validators.requiredField('   '), isNotNull);
      expect(Validators.requiredField('Valid Content'), isNull);
    });

    test('email validator enforces institutional format', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email('test@'), isNotNull);
      expect(Validators.email('student@edusphere.com'), isNull);
    });

    test('minLength validator works accurately', () {
      expect(Validators.minLength('short', 10), isNotNull);
      expect(Validators.minLength('adequate text here', 10), isNull);
    });
  });

  group('MockAuthRepository & AuthProvider Tests', () {
    late MockAuthRepository authRepo;
    late AuthProvider authProvider;

    setUp(() {
      authRepo = MockAuthRepository();
      authProvider = AuthProvider(authRepository: authRepo);
    });

    test('Starts unauthenticated', () async {
      await Future.delayed(const Duration(milliseconds: 200));
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.isApprover, isFalse);
    });

    test('Login identifies the assigned Approver role', () async {
      await authProvider.login('kr.sharma@edusphere.com', 'EduSphere123!');
      expect(authProvider.currentRole, equals(UserRole.approver));
      expect(authProvider.isApprover, isTrue);
      expect(authProvider.currentUser?.name, contains('Sharma'));
    });

    test('Public registration always creates a Requester', () async {
      final registered = await authRepo.register(
        name: 'New User',
        email: 'new@edusphere.com',
        password: 'Password123',
      );
      expect(registered.role, UserRole.requester);
      expect(
        await authRepo.login('new@edusphere.com', 'Password123'),
        registered,
      );
    });

    test('Invalid credentials are rejected', () async {
      expect(authProvider.login('user@edusphere.com', 'wrong'), completes);
      await authProvider.login('user@edusphere.com', 'wrong');
      expect(authProvider.isLoggedIn, isFalse);
    });
  });

  group('MockWorkflowRepository & WorkflowProvider Tests', () {
    late MockWorkflowRepository repo;
    late WorkflowProvider provider;

    setUp(() {
      repo = MockWorkflowRepository();
      provider = WorkflowProvider(workflowRepository: repo);
    });

    test('Repository starts without seeded demo requests', () async {
      final list = await repo.getRequests();
      expect(list, isEmpty);

      await Future.delayed(const Duration(milliseconds: 300));
      expect(provider.requests, isEmpty);
      expect(provider.recentRequests, isEmpty);
      expect(provider.pendingApprovals, isEmpty);
    });

    test('Filter requests by search query', () async {
      await repo.createRequest(
        title: 'IEEE Travel',
        category: WorkflowCategory.leave,
        description: 'Conference request',
        requester: MockUsers.requesterUser,
        priority: PriorityLevel.medium,
        metadata: const {},
      );
      final list = await repo.getRequests(query: 'IEEE');
      expect(list.isNotEmpty, isTrue);
      for (final req in list) {
        final matches =
            req.title.contains('IEEE') ||
            req.description.contains('IEEE') ||
            req.id.contains('IEEE');
        expect(matches, isTrue);
      }
    });

    test('Filter requests by category', () async {
      await repo.createRequest(
        title: 'Leave',
        category: WorkflowCategory.leave,
        description: 'Leave request',
        requester: MockUsers.requesterUser,
        priority: PriorityLevel.medium,
        metadata: const {},
      );
      final list = await repo.getRequests(category: WorkflowCategory.leave);
      expect(list.isNotEmpty, isTrue);
      for (final req in list) {
        expect(req.category, equals(WorkflowCategory.leave));
      }
    });

    test('Create new request adds to repository with correct pipeline', () async {
      const requester = User(
        id: 'USR-REQ-TEST',
        name: 'Test Student',
        email: 'test@edusphere.com',
        role: UserRole.requester,
        department: 'CSE',
        designation: 'Scholar',
      );

      final created = await repo.createRequest(
        title: 'New Grant Requisition for Research',
        category: WorkflowCategory.requisition,
        description:
            'Detailed equipment justification for quantum computing simulator.',
        requester: requester,
        priority: PriorityLevel.high,
        metadata: {'amount': '\$5,000'},
      );

      expect(created.id, startsWith('WF-2026-'));
      expect(created.title, equals('New Grant Requisition for Research'));
      expect(created.stages.isNotEmpty, isTrue);
      expect(created.stages, hasLength(1));
      expect(created.stages.single.approverRole, 'Approver');
      expect(created.status, equals(WorkflowStatus.pending));

      final all = await repo.getRequests();
      expect(all.any((r) => r.id == created.id), isTrue);
    });

    test(
      'All categories create one-approver requests and notify that approver',
      () async {
        final delivered = <NotificationItem>[];
        final categoryProvider = WorkflowProvider(
          workflowRepository: repo,
          notifyUser: (notification) async => delivered.add(notification),
        );
        await Future.delayed(const Duration(milliseconds: 300));
        for (final category in WorkflowCategory.values) {
          final request = await categoryProvider.createRequest(
            title: category.displayName,
            category: category,
            description: 'Category-specific request details',
            requester: MockUsers.requesterUser,
            priority: PriorityLevel.medium,
            metadata: {'categoryField': category.name},
          );
          expect(request, isNotNull);
          expect(request!.stages, hasLength(1));
          expect(
            categoryProvider.canReview(request, MockUsers.approverUser),
            isTrue,
          );
        }
        expect(delivered, hasLength(WorkflowCategory.values.length * 2));
        expect(
          delivered.where(
            (n) => n.recipientUserId == MockUsers.approverUser.id,
          ),
          hasLength(WorkflowCategory.values.length),
        );
        expect(
          delivered.where(
            (n) => n.recipientUserId == MockUsers.requesterUser.id,
          ),
          hasLength(WorkflowCategory.values.length),
        );
      },
    );

    test('Approver decision sends result notification to requester', () async {
      final delivered = <NotificationItem>[];
      final notifiedProvider = WorkflowProvider(
        workflowRepository: repo,
        notifyUser: (notification) async => delivered.add(notification),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      final created = await notifiedProvider.createRequest(
        title: 'Approval target',
        category: WorkflowCategory.clearance,
        description: 'Review details',
        requester: MockUsers.requesterUser,
        priority: PriorityLevel.medium,
        metadata: const {'projectTitle': 'Study'},
      );
      final approved = await notifiedProvider.updateRequestStatus(
        requestId: created!.id,
        status: WorkflowStatus.approved,
        reviewer: MockUsers.approverUser,
      );
      expect(approved, isTrue);
      expect(delivered.last.recipientUserId, MockUsers.requesterUser.id);
      expect(delivered.last.relatedRequestId, created.id);
    });

    test('Update request status updates stage and comments', () async {
      final target = await repo.createRequest(
        title: 'Approval test',
        category: WorkflowCategory.certificate,
        description: 'Test request',
        requester: MockUsers.requesterUser,
        priority: PriorityLevel.medium,
        metadata: const {'certificateType': 'Bonafide'},
      );

      final updated = await repo.updateStatus(
        target.id,
        WorkflowStatus.approved,
        remarks: 'Approved by test suit',
        reviewer: MockUsers.approverUser,
      );

      expect(updated.status, equals(WorkflowStatus.approved));
      expect(
        updated.comments.any((c) => c.content == 'Approved by test suit'),
        isTrue,
      );
    });

    test('Workflow stats computation', () async {
      final stats = await repo.getWorkflowStats();
      expect(stats.containsKey('total'), isTrue);
      expect(stats.containsKey('pending'), isTrue);
      expect(stats.containsKey('approved'), isTrue);
      expect(stats.containsKey('rejected'), isTrue);
      expect(stats['total'], 0);
    });
  });

  test('Notification reads and read states are recipient scoped', () async {
    final notifications = MockNotificationRepository();
    await notifications.addNotification(
      NotificationItem(
        id: 'requester-notice',
        recipientUserId: MockUsers.requesterUser.id,
        title: 'Requester notice',
        message: 'Result',
        type: NotificationType.workflowApproved,
        createdAt: DateTime.now(),
      ),
    );
    await notifications.addNotification(
      NotificationItem(
        id: 'approver-notice',
        recipientUserId: MockUsers.approverUser.id,
        title: 'Approver notice',
        message: 'Action required',
        type: NotificationType.approvalRequired,
        createdAt: DateTime.now(),
      ),
    );
    await notifications.markAllAsRead(MockUsers.requesterUser.id);
    expect(
      await notifications.getNotifications(MockUsers.requesterUser.id),
      hasLength(1),
    );
    expect(
      (await notifications.getNotifications(
        MockUsers.requesterUser.id,
      )).single.isRead,
      isTrue,
    );
    expect(
      (await notifications.getNotifications(
        MockUsers.approverUser.id,
      )).single.isRead,
      isFalse,
    );
  });
}
