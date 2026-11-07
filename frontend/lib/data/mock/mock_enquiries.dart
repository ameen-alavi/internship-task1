import '../models/enquiry_model.dart';

class MockEnquiries {
  /// Start with no seeded enquiries; newly submitted enquiries live in the
  /// mock repository for the current app session.
  static List<Enquiry> get initialEnquiries => <Enquiry>[];
}
