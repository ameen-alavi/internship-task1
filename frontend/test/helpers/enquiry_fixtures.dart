import 'package:frontend/data/models/enquiry_model.dart';

List<Enquiry> enquiryTestFixtures() => List.generate(9, (index) {
  final titles = [
    'M.Tech admissions eligibility query',
    'Merit scholarship disbursement query',
    'Campus WiFi access issue',
    'Compiler Design grade verification',
    'Academic calendar clarification',
    'Open hostel maintenance enquiry',
    'Financial aid status request',
    'Admissions document checklist',
    'General student services query',
  ];
  final categories = [
    EnquiryCategory.admissions,
    EnquiryCategory.financial,
    EnquiryCategory.hostel,
    EnquiryCategory.academic,
    EnquiryCategory.general,
    EnquiryCategory.academic,
    EnquiryCategory.financial,
    EnquiryCategory.admissions,
    EnquiryCategory.general,
  ];
  final statuses = EnquiryStatus.values;
  return Enquiry(
    id: index == 0 ? 'ENQ-2026-001' : 'ENQ-TEST-${index + 1}',
    title: titles[index],
    category: categories[index % categories.length],
    description: 'Test enquiry details for ${titles[index]}.',
    senderName: 'Test Requester',
    senderEmail: 'requester@example.edu',
    department: 'Student Services',
    status: statuses[index % statuses.length],
    createdAt: DateTime(2026, 1, index + 1),
    updatedAt: DateTime(2026, 1, index + 1),
  );
});
