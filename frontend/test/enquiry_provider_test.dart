import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/enquiry_model.dart';
import 'package:frontend/data/models/user_model.dart';
import 'package:frontend/data/repositories/enquiry_repository.dart';
import 'package:frontend/providers/enquiry_provider.dart';
import 'helpers/enquiry_fixtures.dart';

void main() {
  group('EnquiryProvider Comprehensive Unit Tests', () {
    late MockEnquiryRepository repository;
    late EnquiryProvider provider;

    setUp(() async {
      repository = MockEnquiryRepository(
        initialEnquiries: enquiryTestFixtures(),
      );
      provider = EnquiryProvider(enquiryRepository: repository);
      // Allow initial async fetch to complete
      await Future.delayed(const Duration(milliseconds: 300));
    });

    test('Initial state loads first page of seeded enquiries and stats', () {
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.isSuccess, isTrue);
      expect(provider.currentPage, equals(1));
      expect(provider.pageSize, equals(5));
      expect(provider.totalCount, greaterThanOrEqualTo(8));
      expect(provider.totalPages, greaterThanOrEqualTo(2));
      expect(provider.enquiries.length, equals(5));
      expect(provider.hasNextPage, isTrue);
      expect(provider.hasPreviousPage, isFalse);
      expect(provider.stats['total'], greaterThanOrEqualTo(8));
    });

    test('Pagination: nextPage and previousPage navigation', () async {
      expect(provider.currentPage, equals(1));
      expect(provider.hasNextPage, isTrue);

      provider.nextPage();
      expect(provider.isLoading, isTrue);
      await Future.delayed(const Duration(milliseconds: 300));

      expect(provider.currentPage, equals(2));
      expect(provider.hasPreviousPage, isTrue);
      expect(provider.enquiries.isNotEmpty, isTrue);

      provider.previousPage();
      expect(provider.isLoading, isTrue);
      await Future.delayed(const Duration(milliseconds: 300));

      expect(provider.currentPage, equals(1));
      expect(provider.hasPreviousPage, isFalse);
    });

    test('Pagination: goToPage and setPageSize', () async {
      provider.goToPage(2);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(provider.currentPage, equals(2));

      // Attempting to go to invalid page is ignored
      provider.goToPage(999);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.currentPage, equals(2));

      // Change page size resets to page 1
      provider.setPageSize(3);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(provider.pageSize, equals(3));
      expect(provider.currentPage, equals(1));
      expect(provider.enquiries.length, equals(3));
    });

    test('Search query resets pagination to page 1', () async {
      // Navigate to page 2 first
      provider.goToPage(2);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(provider.currentPage, equals(2));

      // Applying search query resets to page 1
      provider.setSearchQuery('WiFi');
      await Future.delayed(const Duration(milliseconds: 300));

      expect(provider.currentPage, equals(1));
      expect(provider.searchQuery, equals('WiFi'));
      expect(provider.enquiries.isNotEmpty, isTrue);
      for (final e in provider.enquiries) {
        final matches =
            e.title.toLowerCase().contains('wifi') ||
            e.description.toLowerCase().contains('wifi');
        expect(matches, isTrue);
      }
    });

    test('Category and Status filters reset pagination to page 1', () async {
      provider.goToPage(2);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(provider.currentPage, equals(2));

      // Filter by category
      provider.setCategoryFilter(EnquiryCategory.admissions);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(provider.currentPage, equals(1));
      expect(provider.categoryFilter, equals(EnquiryCategory.admissions));

      // Filter by status
      provider.setStatusFilter(EnquiryStatus.open);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(provider.currentPage, equals(1));
      expect(provider.statusFilter, equals(EnquiryStatus.open));

      // Filter by priority
      provider.setPriorityFilter(EnquiryPriority.high);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(provider.currentPage, equals(1));
      expect(provider.priorityFilter, equals(EnquiryPriority.high));

      // Clear filters
      provider.clearFilters();
      await Future.delayed(const Duration(milliseconds: 300));
      expect(provider.searchQuery, isEmpty);
      expect(provider.categoryFilter, isNull);
      expect(provider.statusFilter, isNull);
      expect(provider.priorityFilter, isNull);
      expect(provider.currentPage, equals(1));
    });

    test(
      'Error handling and retry strictly preserves search, filter and pagination state',
      () async {
        // Set up specific state: page 2, specific category filter
        provider.setCategoryFilter(EnquiryCategory.academic);
        await Future.delayed(const Duration(milliseconds: 300));
        provider.setSearchQuery('Compiler');
        await Future.delayed(const Duration(milliseconds: 300));

        expect(provider.categoryFilter, equals(EnquiryCategory.academic));
        expect(provider.searchQuery, equals('Compiler'));

        // Simulate network failure
        repository.setSimulateNetworkFailure(true);
        await provider.fetchEnquiries();

        expect(provider.isLoading, isFalse);
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains('Simulated network failure'));

        // State must be strictly preserved
        expect(provider.categoryFilter, equals(EnquiryCategory.academic));
        expect(provider.searchQuery, equals('Compiler'));
        expect(provider.currentPage, equals(1));

        // Restore network and retry
        repository.setSimulateNetworkFailure(false);
        await provider.retry();

        expect(provider.hasError, isFalse);
        expect(provider.isSuccess, isTrue);
        expect(provider.enquiries.isNotEmpty, isTrue);
        expect(provider.categoryFilter, equals(EnquiryCategory.academic));
        expect(provider.searchQuery, equals('Compiler'));
      },
    );

    test('Duplicate concurrent requests are safely ignored', () async {
      repository.setSimulateNetworkFailure(false);

      // Trigger first fetch
      final future1 = provider.fetchEnquiries();
      expect(provider.isLoading, isTrue);

      // Trigger second fetch while first is in-flight
      final future2 = provider.fetchEnquiries();

      await Future.wait([future1, future2]);
      expect(provider.isLoading, isFalse);
      expect(provider.isSuccess, isTrue);
    });

    test(
      'CRUD: createEnquiry adds to list, updates selected, and resets to page 1',
      () async {
        const dto = CreateEnquiryDto(
          title: 'New Student Orientation Schedule Query',
          category: EnquiryCategory.general,
          description:
              'Where can incoming students find the confirmed auditorium reporting times?',
          senderName: 'Sanjay Kumar',
          senderEmail: 'sanjay.k@gmail.com',
          department: 'Student Affairs',
          priority: EnquiryPriority.medium,
        );

        final created = await provider.createEnquiry(dto);

        expect(created, isNotNull);
        expect(created!.id, startsWith('ENQ-2026-'));
        expect(provider.selectedEnquiry?.id, equals(created.id));
        expect(provider.currentPage, equals(1));
        expect(provider.enquiries.any((e) => e.id == created.id), isTrue);
      },
    );

    test(
      'CRUD: updateEnquiry edits fields in-place and in selectedEnquiry',
      () async {
        final initial = provider.enquiries.first;
        expect(initial, isNotNull);

        const updateDto = UpdateEnquiryDto(
          title: 'Updated Subject: Critical Infrastructure Support Needed',
          priority: EnquiryPriority.urgent,
          department: 'Central Facilities Command',
        );

        final updated = await provider.updateEnquiry(initial.id, updateDto);

        expect(updated, isNotNull);
        expect(
          updated!.title,
          equals('Updated Subject: Critical Infrastructure Support Needed'),
        );
        expect(updated.priority, equals(EnquiryPriority.urgent));
        expect(provider.selectedEnquiry?.title, equals(updated.title));

        final refreshedInList = provider.enquiries.firstWhere(
          (e) => e.id == initial.id,
        );
        expect(
          refreshedInList.title,
          equals('Updated Subject: Critical Infrastructure Support Needed'),
        );
      },
    );

    test(
      'CRUD: updateStatus transitions state and records resolution',
      () async {
        final target = provider.enquiries.first;

        const staff = User(
          id: 'STAFF-ADM-01',
          name: 'HOD Sharma',
          email: 'sharma@edusphere.com',
          role: UserRole.approver,
          department: 'CSE',
          designation: 'Professor',
        );

        final success = await provider.updateStatus(
          target.id,
          EnquiryStatus.resolved,
          notes: 'Handled and closed with candidate.',
          staff: staff,
        );

        expect(success, isTrue);
        expect(
          provider.selectedEnquiry?.status,
          equals(EnquiryStatus.resolved),
        );
        expect(provider.selectedEnquiry?.resolvedAt, isNotNull);
        expect(provider.stats['resolved'], greaterThan(0));
      },
    );

    test('CRUD: addResponse appends to conversation thread', () async {
      final target = provider.enquiries.first;

      const author = User(
        id: 'STAFF-ADM-02',
        name: 'Admissions Officer',
        email: 'admissions@edusphere.com',
        role: UserRole.approver,
        department: 'Admissions',
        designation: 'Officer',
      );

      final ok = await provider.addResponse(
        target.id,
        message: 'Your documents have been verified successfully.',
        author: author,
      );

      expect(ok, isTrue);
      expect(
        provider.selectedEnquiry?.responses.any(
          (r) => r.message.contains('verified successfully'),
        ),
        isTrue,
      );
    });
  });
}
