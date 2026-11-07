import 'package:uuid/uuid.dart';
import '../mock/mock_enquiries.dart';
import '../models/enquiry_model.dart';
import '../models/user_model.dart';

class NetworkTimeoutException implements Exception {
  final String message;
  NetworkTimeoutException([
    this.message = 'Network connection timed out. Please retry.',
  ]);

  @override
  String toString() => message;
}

abstract class IEnquiryRepository {
  Future<PaginatedResult<Enquiry>> getEnquiries({
    String? query,
    EnquiryStatus? status,
    EnquiryCategory? category,
    EnquiryPriority? priority,
    int page = 1,
    int limit = 10,
    bool simulateError = false,
  });

  Future<Enquiry?> getEnquiryById(String id);

  Future<Enquiry> createEnquiry(CreateEnquiryDto dto);

  Future<Enquiry> updateEnquiry(String id, UpdateEnquiryDto dto);

  Future<Enquiry> updateStatus(
    String id,
    EnquiryStatus status, {
    String? notes,
    User? staff,
  });

  Future<Enquiry> addResponse(
    String id, {
    required String message,
    required User author,
    bool isInternal = false,
  });

  Future<Map<String, int>> getEnquiryStats();
}

class MockEnquiryRepository implements IEnquiryRepository {
  final List<Enquiry> _enquiries;

  MockEnquiryRepository({List<Enquiry>? initialEnquiries})
    : _enquiries = List.from(
        initialEnquiries ?? MockEnquiries.initialEnquiries,
      );
  final Uuid _uuid = const Uuid();
  bool _simulateNetworkFailure = false;

  void setSimulateNetworkFailure(bool fail) {
    _simulateNetworkFailure = fail;
  }

  @override
  Future<PaginatedResult<Enquiry>> getEnquiries({
    String? query,
    EnquiryStatus? status,
    EnquiryCategory? category,
    EnquiryPriority? priority,
    int page = 1,
    int limit = 10,
    bool simulateError = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (simulateError || _simulateNetworkFailure) {
      throw NetworkTimeoutException(
        'Simulated network failure. Could not fetch enquiries from server.',
      );
    }

    final filtered = _enquiries.where((e) {
      if (status != null && e.status != status) return false;
      if (category != null && e.category != category) return false;
      if (priority != null && e.priority != priority) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchTitle = e.title.toLowerCase().contains(q);
        final matchDesc = e.description.toLowerCase().contains(q);
        final matchId = e.id.toLowerCase().contains(q);
        final matchSender = e.senderName.toLowerCase().contains(q);
        final matchDept = e.department.toLowerCase().contains(q);
        if (!matchTitle &&
            !matchDesc &&
            !matchId &&
            !matchSender &&
            !matchDept) {
          return false;
        }
      }
      return true;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final totalCount = filtered.length;
    final totalPages = (totalCount / limit).ceil().clamp(1, 9999);
    final safePage = page.clamp(1, totalPages);

    final startIndex = (safePage - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, totalCount);

    final pagedItems = (startIndex < totalCount)
        ? filtered.sublist(startIndex, endIndex)
        : <Enquiry>[];

    return PaginatedResult<Enquiry>(
      items: pagedItems,
      totalCount: totalCount,
      currentPage: safePage,
      totalPages: totalPages,
      pageSize: limit,
    );
  }

  @override
  Future<Enquiry?> getEnquiryById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _enquiries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Enquiry> createEnquiry(CreateEnquiryDto dto) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final nextNum = _enquiries.length + 1;
    final id = 'ENQ-2026-${nextNum.toString().padLeft(3, '0')}';

    final now = DateTime.now();
    final newEnquiry = Enquiry(
      id: id,
      title: dto.title,
      category: dto.category,
      description: dto.description,
      senderName: dto.senderName,
      senderEmail: dto.senderEmail,
      senderUserId: dto.senderUserId,
      senderPhone: dto.senderPhone,
      department: dto.department,
      priority: dto.priority,
      status: EnquiryStatus.open,
      createdAt: now,
      updatedAt: now,
      attachments: dto.attachments,
      metadata: dto.metadata,
      responses: [
        EnquiryResponse(
          id: _uuid.v4(),
          authorName: dto.senderName,
          authorRole: 'Enquirer',
          message: 'Enquiry submitted to institutional workflow portal.',
          createdAt: now,
        ),
      ],
    );

    _enquiries.insert(0, newEnquiry);
    return newEnquiry;
  }

  @override
  Future<Enquiry> updateEnquiry(String id, UpdateEnquiryDto dto) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _enquiries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw Exception('Enquiry $id not found for update');
    }

    final current = _enquiries[index];
    final now = DateTime.now();

    final updated = current.copyWith(
      title: dto.title ?? current.title,
      category: dto.category ?? current.category,
      description: dto.description ?? current.description,
      senderPhone: dto.senderPhone ?? current.senderPhone,
      department: dto.department ?? current.department,
      priority: dto.priority ?? current.priority,
      assignedTo: dto.assignedTo ?? current.assignedTo,
      metadata: dto.metadata ?? current.metadata,
      updatedAt: now,
    );

    _enquiries[index] = updated;
    return updated;
  }

  @override
  Future<Enquiry> updateStatus(
    String id,
    EnquiryStatus status, {
    String? notes,
    User? staff,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _enquiries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw Exception('Enquiry $id not found');
    }

    final current = _enquiries[index];
    final now = DateTime.now();
    final updatedResponses = List<EnquiryResponse>.from(current.responses);

    if (notes != null && notes.trim().isNotEmpty) {
      updatedResponses.add(
        EnquiryResponse(
          id: _uuid.v4(),
          authorName: staff?.name ?? 'Assigned Officer',
          authorRole: staff?.role.shortLabel ?? 'Staff',
          message: 'Status changed to ${status.displayName}: $notes',
          createdAt: now,
        ),
      );
    }

    final updated = current.copyWith(
      status: status,
      updatedAt: now,
      resolvedAt:
          (status == EnquiryStatus.resolved || status == EnquiryStatus.closed)
          ? now
          : current.resolvedAt,
      responses: updatedResponses,
    );

    _enquiries[index] = updated;
    return updated;
  }

  @override
  Future<Enquiry> addResponse(
    String id, {
    required String message,
    required User author,
    bool isInternal = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _enquiries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw Exception('Enquiry $id not found');
    }

    final current = _enquiries[index];
    final now = DateTime.now();
    final response = EnquiryResponse(
      id: _uuid.v4(),
      authorName: author.name,
      authorRole: author.role.shortLabel,
      message: message,
      createdAt: now,
      isInternal: isInternal,
    );

    final updated = current.copyWith(
      responses: [...current.responses, response],
      updatedAt: now,
    );

    _enquiries[index] = updated;
    return updated;
  }

  @override
  Future<Map<String, int>> getEnquiryStats() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final total = _enquiries.length;
    final open = _enquiries.where((e) => e.status == EnquiryStatus.open).length;
    final inProgress = _enquiries
        .where((e) => e.status == EnquiryStatus.inProgress)
        .length;
    final resolved = _enquiries
        .where((e) => e.status == EnquiryStatus.resolved)
        .length;
    final closed = _enquiries
        .where((e) => e.status == EnquiryStatus.closed)
        .length;

    return {
      'total': total,
      'open': open,
      'inProgress': inProgress,
      'resolved': resolved,
      'closed': closed,
    };
  }
}
