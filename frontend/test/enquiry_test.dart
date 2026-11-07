import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/enquiry_model.dart';
import 'package:frontend/data/models/user_model.dart';
import 'package:frontend/data/repositories/enquiry_repository.dart';
import 'helpers/enquiry_fixtures.dart';

void main() {
  group('IEnquiryRepository & MockEnquiryRepository Tests', () {
    late MockEnquiryRepository repo;

    setUp(() {
      repo = MockEnquiryRepository(initialEnquiries: enquiryTestFixtures());
    });

    test('Loads initial seeded enquiries with pagination', () async {
      final page1 = await repo.getEnquiries(page: 1, limit: 4);
      expect(page1.items.length, equals(4));
      expect(page1.totalCount, greaterThanOrEqualTo(8));
      expect(page1.currentPage, equals(1));
      expect(page1.totalPages, greaterThanOrEqualTo(2));
      expect(page1.hasNextPage, isTrue);
      expect(page1.hasPreviousPage, isFalse);

      final page2 = await repo.getEnquiries(page: 2, limit: 4);
      expect(page2.items.length, equals(4));
      expect(page2.currentPage, equals(2));
      expect(page2.hasPreviousPage, isTrue);
    });

    test('Search filtering by keyword', () async {
      final res = await repo.getEnquiries(query: 'Scholarship');
      expect(res.items.isNotEmpty, isTrue);
      for (final e in res.items) {
        final matches =
            e.title.toLowerCase().contains('scholarship') ||
            e.description.toLowerCase().contains('scholarship') ||
            e.id.toLowerCase().contains('scholarship');
        expect(matches, isTrue);
      }
    });

    test('Category filtering', () async {
      final res = await repo.getEnquiries(category: EnquiryCategory.admissions);
      expect(res.items.isNotEmpty, isTrue);
      for (final e in res.items) {
        expect(e.category, equals(EnquiryCategory.admissions));
      }
    });

    test('Status filtering', () async {
      final res = await repo.getEnquiries(status: EnquiryStatus.resolved);
      expect(res.items.isNotEmpty, isTrue);
      for (final e in res.items) {
        expect(e.status, equals(EnquiryStatus.resolved));
      }
    });

    test('Create new enquiry adds to top of list with open status', () async {
      const dto = CreateEnquiryDto(
        title: 'New Admission Query on Computer Science Honours',
        category: EnquiryCategory.admissions,
        description:
            'Candidate asking for course fee breakdown and hostel allotment process.',
        senderName: 'Deepak Sharma',
        senderEmail: 'deepak.sharma@gmail.com',
        senderPhone: '+91 99887 76655',
        department: 'Admissions Office',
        priority: EnquiryPriority.high,
      );

      final created = await repo.createEnquiry(dto);
      expect(created.id, startsWith('ENQ-2026-'));
      expect(created.title, equals(dto.title));
      expect(created.status, equals(EnquiryStatus.open));
      expect(created.responses.isNotEmpty, isTrue);

      final fetched = await repo.getEnquiryById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, equals(dto.title));
    });

    test('Update existing enquiry (Edit flow)', () async {
      final list = await repo.getEnquiries();
      final target = list.items.first;

      const updateDto = UpdateEnquiryDto(
        title: 'Revised Subject: Urgent Course Fee Clarification',
        priority: EnquiryPriority.urgent,
        department: 'Executive Finance Committee',
      );

      final updated = await repo.updateEnquiry(target.id, updateDto);
      expect(
        updated.title,
        equals('Revised Subject: Urgent Course Fee Clarification'),
      );
      expect(updated.priority, equals(EnquiryPriority.urgent));
      expect(updated.department, equals('Executive Finance Committee'));
    });

    test('Update status and records resolution timestamp', () async {
      final list = await repo.getEnquiries(status: EnquiryStatus.open);
      expect(list.items.isNotEmpty, isTrue);
      final target = list.items.first;

      const staff = User(
        id: 'STAFF-01',
        name: 'Dr. Officer',
        email: 'officer@edusphere.com',
        role: UserRole.approver,
        department: 'Admissions',
        designation: 'Officer',
      );

      final updated = await repo.updateStatus(
        target.id,
        EnquiryStatus.resolved,
        notes: 'Document issued and query resolved via telephone.',
        staff: staff,
      );

      expect(updated.status, equals(EnquiryStatus.resolved));
      expect(updated.resolvedAt, isNotNull);
      expect(
        updated.responses.any((r) => r.message.contains('Document issued')),
        isTrue,
      );
    });

    test('Add response to enquiry discussion thread', () async {
      final list = await repo.getEnquiries();
      final target = list.items.first;

      const author = User(
        id: 'STAFF-02',
        name: 'Prof. Advisor',
        email: 'advisor@edusphere.com',
        role: UserRole.approver,
        department: 'Admissions',
        designation: 'Advisor',
      );

      final updated = await repo.addResponse(
        target.id,
        message: 'Please provide certified marksheets for credit evaluation.',
        author: author,
      );

      expect(
        updated.responses.any(
          (r) => r.message.contains('certified marksheets'),
        ),
        isTrue,
      );
    });

    test(
      'Simulated network failure throws retryable NetworkTimeoutException',
      () async {
        repo.setSimulateNetworkFailure(true);
        await expectLater(
          repo.getEnquiries(),
          throwsA(isA<NetworkTimeoutException>()),
        );

        repo.setSimulateNetworkFailure(false);
        final res = await repo.getEnquiries();
        expect(res.items.isNotEmpty, isTrue);
      },
    );

    test('Enquiry stats computation aggregates status counts', () async {
      final stats = await repo.getEnquiryStats();
      expect(stats.containsKey('total'), isTrue);
      expect(stats.containsKey('open'), isTrue);
      expect(stats.containsKey('inProgress'), isTrue);
      expect(stats.containsKey('resolved'), isTrue);
      expect(stats.containsKey('closed'), isTrue);
      expect(stats['total'], greaterThanOrEqualTo(8));
      expect(
        stats['open']! +
            stats['inProgress']! +
            stats['resolved']! +
            stats['closed']!,
        equals(stats['total']),
      );
    });
  });
}
