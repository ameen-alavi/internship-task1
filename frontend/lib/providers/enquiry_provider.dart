import 'package:flutter/material.dart';
import '../data/models/enquiry_model.dart';
import '../data/models/notification_model.dart';
import '../data/models/user_model.dart';
import '../data/mock/mock_users.dart';
import '../data/repositories/enquiry_repository.dart';

class EnquiryProvider extends ChangeNotifier {
  final IEnquiryRepository _enquiryRepository;
  final Future<void> Function(NotificationItem)? _notifyUser;

  // Data State
  List<Enquiry> _enquiries = [];
  Enquiry? _selectedEnquiry;
  Map<String, int> _stats = {
    'total': 0,
    'open': 0,
    'inProgress': 0,
    'resolved': 0,
    'closed': 0,
  };

  // Pagination State
  int _currentPage = 1;
  int _pageSize = 5;
  int _totalCount = 0;
  int _totalPages = 1;

  // Filter & Search State
  String _searchQuery = '';
  EnquiryStatus? _statusFilter;
  EnquiryCategory? _categoryFilter;
  EnquiryPriority? _priorityFilter;

  // Status & Error State
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  EnquiryProvider({
    required IEnquiryRepository enquiryRepository,
    Future<void> Function(NotificationItem)? notifyUser,
  }) : _enquiryRepository = enquiryRepository,
       _notifyUser = notifyUser {
    fetchEnquiries();
    fetchStats();
  }

  // Getters
  List<Enquiry> get enquiries => _enquiries;
  Enquiry? get selectedEnquiry => _selectedEnquiry;
  Map<String, int> get stats => _stats;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;

  String get searchQuery => _searchQuery;
  EnquiryStatus? get statusFilter => _statusFilter;
  EnquiryCategory? get categoryFilter => _categoryFilter;
  EnquiryPriority? get priorityFilter => _priorityFilter;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty =>
      !_isLoading && _enquiries.isEmpty && _errorMessage == null;
  bool get isSuccess => !_isLoading && _errorMessage == null;

  List<Enquiry> get recentEnquiries {
    final list = List<Enquiry>.from(_enquiries);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(5).toList();
  }

  // Pagination Methods
  void nextPage() {
    if (hasNextPage && !_isLoading) {
      _currentPage++;
      fetchEnquiries();
    }
  }

  void previousPage() {
    if (hasPreviousPage && !_isLoading) {
      _currentPage--;
      fetchEnquiries();
    }
  }

  void goToPage(int page) {
    if (page >= 1 &&
        page <= _totalPages &&
        page != _currentPage &&
        !_isLoading) {
      _currentPage = page;
      fetchEnquiries();
    }
  }

  void setPageSize(int size) {
    if (size > 0 && size != _pageSize) {
      _pageSize = size;
      _currentPage = 1; // Reset to page 1 on page size change
      fetchEnquiries();
    }
  }

  // Filter & Search Methods (Always resets pagination to Page 1)
  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (_searchQuery != trimmed) {
      _searchQuery = trimmed;
      _currentPage = 1;
      fetchEnquiries();
    }
  }

  void setStatusFilter(EnquiryStatus? status) {
    if (_statusFilter != status) {
      _statusFilter = status;
      _currentPage = 1;
      fetchEnquiries();
    }
  }

  void setCategoryFilter(EnquiryCategory? category) {
    if (_categoryFilter != category) {
      _categoryFilter = category;
      _currentPage = 1;
      fetchEnquiries();
    }
  }

  void setPriorityFilter(EnquiryPriority? priority) {
    if (_priorityFilter != priority) {
      _priorityFilter = priority;
      _currentPage = 1;
      fetchEnquiries();
    }
  }

  void clearFilters() {
    bool hasActiveFilters =
        _searchQuery.isNotEmpty ||
        _statusFilter != null ||
        _categoryFilter != null ||
        _priorityFilter != null;

    if (hasActiveFilters) {
      _searchQuery = '';
      _statusFilter = null;
      _categoryFilter = null;
      _priorityFilter = null;
      _currentPage = 1;
      fetchEnquiries();
    }
  }

  // Core Data Fetch with Duplicate Request Guard
  Future<void> fetchEnquiries() async {
    if (_isLoading) return; // Prevent duplicate concurrent requests

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _enquiryRepository.getEnquiries(
        query: _searchQuery,
        status: _statusFilter,
        category: _categoryFilter,
        priority: _priorityFilter,
        page: _currentPage,
        limit: _pageSize,
      );

      _enquiries = result.items;
      _totalCount = result.totalCount;
      _totalPages = result.totalPages;
      _currentPage = result.currentPage;
    } on NetworkTimeoutException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'An error occurred while loading enquiries: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Retry Method (Strictly preserves query, filters, page and page size)
  Future<void> retry() async {
    await fetchEnquiries();
    await fetchStats();
  }

  // Single Item Fetch
  Future<Enquiry?> fetchEnquiryById(
    String id, {
    String? viewerEmail,
    UserRole? viewerRole,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedEnquiry = await _enquiryRepository.getEnquiryById(id);
      if (_selectedEnquiry != null &&
          viewerRole != UserRole.approver &&
          viewerEmail != null &&
          _selectedEnquiry!.senderEmail.toLowerCase() !=
              viewerEmail.toLowerCase()) {
        _selectedEnquiry = null;
        _errorMessage = 'You are not authorized to view this enquiry.';
        return null;
      }
      return _selectedEnquiry;
    } catch (e) {
      _errorMessage = 'Failed to load enquiry #$id: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Aggregated Stats
  Future<void> fetchStats() async {
    try {
      _stats = await _enquiryRepository.getEnquiryStats();
      notifyListeners();
    } catch (_) {}
  }

  // Create Enquiry Action
  Future<Enquiry?> createEnquiry(CreateEnquiryDto dto) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _enquiryRepository.createEnquiry(dto);
      _currentPage = 1; // Return to first page to see the new enquiry
      await fetchEnquiries();
      await fetchStats();
      _selectedEnquiry = created;
      if (_notifyUser != null && created.senderUserId != null) {
        await _notifyUser!(
          NotificationItem(
            id: 'NTF-${DateTime.now().microsecondsSinceEpoch}',
            recipientUserId: MockUsers.approverUser.id,
            title: 'New enquiry needs a response',
            message: 'Enquiry ${created.id}: ${created.title}',
            type: NotificationType.enquiryNeedsResponse,
            createdAt: DateTime.now(),
            relatedEnquiryId: created.id,
          ),
        );
        await _notifyUser!(
          NotificationItem(
            id: 'NTF-${DateTime.now().microsecondsSinceEpoch}',
            recipientUserId: created.senderUserId,
            title: 'Enquiry submitted',
            message: 'Enquiry ${created.id} was submitted successfully.',
            type: NotificationType.enquirySubmitted,
            createdAt: DateTime.now(),
            relatedEnquiryId: created.id,
          ),
        );
      }
      return created;
    } catch (e) {
      _errorMessage = 'Failed to create enquiry: $e';
      return null;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // Update Enquiry Action (Edit Flow)
  Future<Enquiry?> updateEnquiry(String id, UpdateEnquiryDto dto) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _enquiryRepository.updateEnquiry(id, dto);
      _selectedEnquiry = updated;

      // Update in-place in current list if present
      final index = _enquiries.indexWhere((e) => e.id == id);
      if (index != -1) {
        _enquiries[index] = updated;
      }

      await fetchStats();
      return updated;
    } catch (e) {
      _errorMessage = 'Failed to update enquiry: $e';
      return null;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // Update Status Action
  Future<bool> updateStatus(
    String id,
    EnquiryStatus status, {
    String? notes,
    User? staff,
  }) async {
    if (staff?.role != UserRole.approver) {
      _errorMessage = 'Only an approver can change enquiry status.';
      return false;
    }
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _enquiryRepository.updateStatus(
        id,
        status,
        notes: notes,
        staff: staff,
      );

      _selectedEnquiry = updated;

      final index = _enquiries.indexWhere((e) => e.id == id);
      if (index != -1) {
        _enquiries[index] = updated;
      }

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

  // Add Response to Discussion Action
  Future<bool> addResponse(
    String id, {
    required String message,
    required User author,
    bool isInternal = false,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _enquiryRepository.addResponse(
        id,
        message: message,
        author: author,
        isInternal: isInternal,
      );

      _selectedEnquiry = updated;

      if (author.role == UserRole.approver &&
          updated.senderUserId != null &&
          _notifyUser != null) {
        await _notifyUser!(
          NotificationItem(
            id: 'NTF-${DateTime.now().microsecondsSinceEpoch}',
            recipientUserId: updated.senderUserId,
            title: 'Response to your enquiry',
            message: 'A response was added to enquiry ${updated.id}.',
            type: NotificationType.enquiryResponse,
            createdAt: DateTime.now(),
            relatedEnquiryId: updated.id,
          ),
        );
      }

      final index = _enquiries.indexWhere((e) => e.id == id);
      if (index != -1) {
        _enquiries[index] = updated;
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to post response: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
