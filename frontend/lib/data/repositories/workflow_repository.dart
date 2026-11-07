import 'package:uuid/uuid.dart';
import '../mock/mock_users.dart';
import '../mock/mock_workflow_requests.dart';
import '../models/user_model.dart';
import '../models/workflow_request_model.dart';

abstract class IWorkflowRepository {
  Future<List<WorkflowRequest>> getRequests({
    String? query,
    WorkflowStatus? status,
    WorkflowCategory? category,
    PriorityLevel? priority,
  });

  Future<WorkflowRequest?> getRequestById(String id);

  Future<WorkflowRequest> createRequest({
    required String title,
    required WorkflowCategory category,
    required String description,
    required User requester,
    required PriorityLevel priority,
    required Map<String, dynamic> metadata,
    List<WorkflowAttachment> attachments,
    bool isDraft = false,
  });

  Future<WorkflowRequest> updateStatus(
    String requestId,
    WorkflowStatus newStatus, {
    String? remarks,
    User? reviewer,
  });

  Future<WorkflowRequest> addComment({
    required String requestId,
    required String content,
    required User author,
  });

  Future<Map<String, int>> getWorkflowStats();
}

class MockWorkflowRepository implements IWorkflowRepository {
  final List<WorkflowRequest> _requests = List.from(
    MockWorkflowRequests.initialRequests,
  );
  final Uuid _uuid = const Uuid();

  @override
  Future<List<WorkflowRequest>> getRequests({
    String? query,
    WorkflowStatus? status,
    WorkflowCategory? category,
    PriorityLevel? priority,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _requests.where((r) {
      if (status != null && r.status != status) return false;
      if (category != null && r.category != category) return false;
      if (priority != null && r.priority != priority) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchTitle = r.title.toLowerCase().contains(q);
        final matchDesc = r.description.toLowerCase().contains(q);
        final matchId = r.id.toLowerCase().contains(q);
        final matchRequester = r.requesterName.toLowerCase().contains(q);
        final matchDept = r.department.toLowerCase().contains(q);
        if (!matchTitle &&
            !matchDesc &&
            !matchId &&
            !matchRequester &&
            !matchDept) {
          return false;
        }
      }
      return true;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<WorkflowRequest?> getRequestById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WorkflowRequest> createRequest({
    required String title,
    required WorkflowCategory category,
    required String description,
    required User requester,
    required PriorityLevel priority,
    required Map<String, dynamic> metadata,
    List<WorkflowAttachment> attachments = const [],
    bool isDraft = false,
  }) async {
    if (requester.role != UserRole.requester) {
      throw Exception('Only Requesters can submit workflow applications.');
    }
    await Future.delayed(const Duration(milliseconds: 400));
    final randomIdNum = 100 + _requests.length + 1;
    final id = 'WF-2026-$randomIdNum';

    final defaultStages = [
      WorkflowStage(
        id: 'STG-1',
        title: 'Approver Review',
        approverRole: 'Approver',
        approverName: MockUsers.approverUser.name,
        status: isDraft ? StageStatus.pending : StageStatus.inProgress,
      ),
    ];

    final now = DateTime.now();
    final newRequest = WorkflowRequest(
      id: id,
      title: title,
      category: category,
      description: description,
      requesterId: requester.id,
      requesterName: requester.name,
      requesterEmail: requester.email,
      department: requester.department,
      priority: priority,
      status: isDraft ? WorkflowStatus.draft : WorkflowStatus.pending,
      createdAt: now,
      updatedAt: now,
      stages: defaultStages,
      attachments: attachments,
      metadata: metadata,
      comments: [
        WorkflowComment(
          id: _uuid.v4(),
          authorName: requester.name,
          authorRole: requester.role.shortLabel,
          content: 'Application submitted for institutional processing.',
          createdAt: now,
        ),
      ],
    );

    _requests.insert(0, newRequest);
    return newRequest;
  }

  @override
  Future<WorkflowRequest> updateStatus(
    String requestId,
    WorkflowStatus newStatus, {
    String? remarks,
    User? reviewer,
  }) async {
    if (reviewer == null || reviewer.role != UserRole.approver) {
      throw Exception('Only authenticated approvers can process requests.');
    }
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) throw Exception('Request $requestId not found');

    final current = _requests[index];
    if (current.requesterId == reviewer.id) {
      throw Exception('Approvers cannot process their own requests.');
    }
    final stage = current.stages[current.currentStageIndex];
    if (stage.approverRole != 'Approver' ||
        (stage.approverName != null && stage.approverName != reviewer.name)) {
      throw Exception('This approval is not assigned to your role.');
    }
    final now = DateTime.now();

    List<WorkflowStage> updatedStages = List.from(current.stages);
    int activeIdx = current.currentStageIndex;

    if (activeIdx >= 0 && activeIdx < updatedStages.length) {
      StageStatus stageStat = StageStatus.approved;
      if (newStatus == WorkflowStatus.rejected) {
        stageStat = StageStatus.rejected;
      }
      if (newStatus == WorkflowStatus.returned) {
        stageStat = StageStatus.rejected;
      }

      updatedStages[activeIdx] = updatedStages[activeIdx].copyWith(
        status: stageStat,
        remarks: remarks,
        approverName: reviewer?.name ?? 'Assigned Reviewer',
        updatedAt: now,
      );
    }

    List<WorkflowComment> updatedComments = List.from(current.comments);
    if (remarks != null && remarks.trim().isNotEmpty) {
      updatedComments.add(
        WorkflowComment(
          id: _uuid.v4(),
          authorName: reviewer?.name ?? 'Reviewer',
          authorRole: reviewer?.role.shortLabel ?? 'Staff',
          content: remarks,
          createdAt: now,
        ),
      );
    }

    final updated = current.copyWith(
      status: newStatus,
      updatedAt: now,
      stages: updatedStages,
      comments: updatedComments,
    );

    _requests[index] = updated;
    return updated;
  }

  @override
  Future<WorkflowRequest> addComment({
    required String requestId,
    required String content,
    required User author,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) throw Exception('Request $requestId not found');

    final current = _requests[index];
    final comment = WorkflowComment(
      id: _uuid.v4(),
      authorName: author.name,
      authorRole: author.role.shortLabel,
      content: content,
      createdAt: DateTime.now(),
    );

    final updated = current.copyWith(
      comments: [...current.comments, comment],
      updatedAt: DateTime.now(),
    );

    _requests[index] = updated;
    return updated;
  }

  @override
  Future<Map<String, int>> getWorkflowStats() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final total = _requests.length;
    final pending = _requests
        .where(
          (r) =>
              r.status == WorkflowStatus.pending ||
              r.status == WorkflowStatus.inReview,
        )
        .length;
    final approved = _requests
        .where((r) => r.status == WorkflowStatus.approved)
        .length;
    final rejected = _requests
        .where(
          (r) =>
              r.status == WorkflowStatus.rejected ||
              r.status == WorkflowStatus.returned,
        )
        .length;

    return {
      'total': total,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }
}
