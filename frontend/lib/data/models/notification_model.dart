enum NotificationType {
  workflowApproved,
  workflowRejected,
  workflowReturned,
  approvalRequired,
  requestSubmitted,
  enquiryResponse,
  enquirySubmitted,
  enquiryNeedsResponse,
  generalNotice;

  String get label {
    switch (this) {
      case NotificationType.workflowApproved:
        return 'Approval Notice';
      case NotificationType.workflowRejected:
        return 'Rejection Alert';
      case NotificationType.workflowReturned:
        return 'Action Required';
      case NotificationType.approvalRequired:
        return 'Pending Review';
      case NotificationType.generalNotice:
        return 'Announcement';
      case NotificationType.requestSubmitted:
        return 'Request Submitted';
      case NotificationType.enquiryResponse:
        return 'Enquiry Response';
      case NotificationType.enquirySubmitted:
        return 'Enquiry Submitted';
      case NotificationType.enquiryNeedsResponse:
        return 'Enquiry Needs Response';
    }
  }
}

class NotificationItem {
  final String id;
  final String? recipientUserId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedRequestId;
  final String? relatedEnquiryId;

  const NotificationItem({
    required this.id,
    this.recipientUserId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.relatedRequestId,
    this.relatedEnquiryId,
  });

  NotificationItem copyWith({
    String? id,
    String? recipientUserId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? relatedRequestId,
    String? relatedEnquiryId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedRequestId: relatedRequestId ?? this.relatedRequestId,
      relatedEnquiryId: relatedEnquiryId ?? this.relatedEnquiryId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipientUserId': recipientUserId,
    'title': title,
    'message': message,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'relatedRequestId': relatedRequestId,
    'relatedEnquiryId': relatedEnquiryId,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      recipientUserId: json['recipientUserId'] as String?,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.byName(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      relatedRequestId: json['relatedRequestId'] as String?,
      relatedEnquiryId: json['relatedEnquiryId'] as String?,
    );
  }
}
