import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/models/notification_model.dart';
import '../data/models/workflow_request_model.dart';
import '../data/repositories/workflow_repository.dart';
import '../data/mock/mock_users.dart';

class WorkflowProvider extends ChangeNotifier {
  final IWorkflowRepository _workflowRepository;
  final Future<void> Function(NotificationItem)? _notifyUser;

  List<WorkflowRequest> _requests = [];
  WorkflowRequest? _selectedRequest;
  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
  };

  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  // Filters
  String _searchQuery = '';
  WorkflowStatus? _statusFilter;
  WorkflowCategory? _categoryFilter;
  PriorityLevel? _priorityFilter;

  WorkflowProvider({
    required IWorkflowRepository workflowRepository,
    Future<void> Function(NotificationItem)? notifyUser,
  }) : _workflowRepository = workflowRepository,
       _notifyUser = notifyUser {
    fetchRequests();
    fetchStats();
  }

  List<WorkflowRequest> get requests => _requests;
  WorkflowRequest? get selectedRequest => _selectedRequest;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  WorkflowStatus? get statusFilter => _statusFilter;
  WorkflowCategory? get categoryFilter => _categoryFilter;
  PriorityLevel? get priorityFilter => _priorityFilter;

  List<WorkflowRequest> get pendingApprovals {
    return _requests
        .where(
          (r) =>
              r.status == WorkflowStatus.pending ||
              r.status == WorkflowStatus.inReview,
        )
        .toList();
  }

  bool canReview(WorkflowRequest request, User? reviewer) {
    if (reviewer == null ||
        reviewer.role != UserRole.approver ||
        request.requesterId == reviewer.id)
      return false;
    final index = request.currentStageIndex;
    if (index < 0 || index >= request.stages.length) return false;
    final stage = request.stages[index];
    return stage.approverRole == 'Approver' &&
        (stage.approverName == null || stage.approverName == reviewer.name);
  }

  List<WorkflowRequest> get recentRequests {
    final list = List<WorkflowRequest>.from(_requests);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(5).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchRequests();
  }

  void setStatusFilter(WorkflowStatus? status) {
    _statusFilter = status;
    fetchRequests();
  }

  void setCategoryFilter(WorkflowCategory? category) {
    _categoryFilter = category;
    fetchRequests();
  }

  void setPriorityFilter(PriorityLevel? priority) {
    _priorityFilter = priority;
    fetchRequests();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _categoryFilter = null;
    _priorityFilter = null;
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _requests = await _workflowRepository.getRequests(
        query: _searchQuery,
        status: _statusFilter,
        category: _categoryFilter,
        priority: _priorityFilter,
      );
    } catch (e) {
      _errorMessage = 'Failed to load workflow requests: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats() async {
    try {
      _stats = await _workflowRepository.getWorkflowStats();
      notifyListeners();
    } catch (_) {}
  }

  Future<WorkflowRequest?> fetchRequestById(String id, {User? viewer}) async {
    _selectedRequest = null;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      _selectedRequest = await _workflowRepository.getRequestById(id);
      if (_selectedRequest != null && viewer != null) {
        final isOwner = _selectedRequest!.requesterId == viewer.id;
        if (!isOwner && !canReview(_selectedRequest!, viewer)) {
          _selectedRequest = null;
          _errorMessage = 'You are not authorized to view this request.';
          return null;
        }
      }
      return _selectedRequest;
    } catch (e) {
      _errorMessage = 'Failed to load request details: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<WorkflowRequest?> createRequest({
    required String title,
    required WorkflowCategory category,
    required String description,
    required User requester,
    required PriorityLevel priority,
    required Map<String, dynamic> metadata,
    List<WorkflowAttachment> attachments = const [],
    bool isDraft = false,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newRequest = await _workflowRepository.createRequest(
        title: title,
        category: category,
        description: description,
        requester: requester,
        priority: priority,
        metadata: metadata,
        attachments: attachments,
        isDraft: isDraft,
      );
      await fetchRequests();
      await fetchStats();
      _selectedRequest = newRequest;
      if (!isDraft && _notifyUser != null) {
        await _notifyUser!(
          NotificationItem(
            id: 'NTF-${DateTime.now().microsecondsSinceEpoch}',
            recipientUserId: MockUsers.approverUser.id,
            title: 'New ${newRequest.category.displayName} awaiting approval',
            message:
                '${newRequest.id} — ${newRequest.title} requires your review.',
            type: NotificationType.approvalRequired,
            createdAt: DateTime.now(),
            relatedRequestId: newRequest.id,
          ),
        );
        await _notifyUser!(
          NotificationItem(
            id: 'NTF-${DateTime.now().microsecondsSinceEpoch}',
            recipientUserId: requester.id,
            title: '${newRequest.category.displayName} submitted',
            message:
                'Request ${newRequest.id} was submitted and is awaiting approval.',
            type: NotificationType.requestSubmitted,
            createdAt: DateTime.now(),
            relatedRequestId: newRequest.id,
          ),
        );
      }
      return newRequest;
    } catch (e) {
      _errorMessage = 'Failed to submit request: $e';
      return null;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRequestStatus({
    required String requestId,
    required WorkflowStatus status,
    String? remarks,
    User? reviewer,
  }) async {
    if (reviewer == null || reviewer.role != UserRole.approver) {
      _errorMessage = 'Only authenticated approvers can process requests.';
      notifyListeners();
      return false;
    }
    final target = _requests
        .where((request) => request.id == requestId)
        .firstOrNull;
    if (target != null && target.requesterId == reviewer.id) {
      _errorMessage = 'Approvers cannot process their own requests.';
      notifyListeners();
      return false;
    }
    if (target != null) {
      if (!canReview(target, reviewer)) {
        _errorMessage = 'This approval is not assigned to your role.';
        notifyListeners();
        return false;
      }
    }
    if (target != null &&
        !(target.status == WorkflowStatus.pending ||
            target.status == WorkflowStatus.inReview)) {
      _errorMessage = 'This request is no longer awaiting review.';
      notifyListeners();
      return false;
    }
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _workflowRepository.updateStatus(
        requestId,
        status,
        remarks: remarks,
        reviewer: reviewer,
      );
      _selectedRequest = updated;
      if (_notifyUser != null &&
          (status == WorkflowStatus.approved ||
              status == WorkflowStatus.rejected ||
              status == WorkflowStatus.returned)) {
        final type = status == WorkflowStatus.approved
            ? NotificationType.workflowApproved
            : status == WorkflowStatus.returned
            ? NotificationType.workflowReturned
            : NotificationType.workflowRejected;
        await _notifyUser!(
          NotificationItem(
            id: 'NTF-${DateTime.now().microsecondsSinceEpoch}',
            recipientUserId: updated.requesterId,
            title:
                '${updated.category.displayName} ${status.displayName.toLowerCase()}',
            message:
                'Request ${updated.id} was ${status.displayName.toLowerCase()} by ${reviewer!.name}.',
            type: type,
            createdAt: DateTime.now(),
            relatedRequestId: updated.id,
          ),
        );
      }
      await fetchRequests();
      await fetchStats();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update status: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addComment({
    required String requestId,
    required String content,
    required User author,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final updated = await _workflowRepository.addComment(
        requestId: requestId,
        content: content,
        author: author,
      );
      _selectedRequest = updated;
      final idx = _requests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        _requests[idx] = updated;
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to post comment: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
