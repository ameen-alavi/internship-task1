import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum EnquiryStatus {
  open,
  inProgress,
  resolved,
  closed;

  String get displayName {
    switch (this) {
      case EnquiryStatus.open:
        return 'Open';
      case EnquiryStatus.inProgress:
        return 'In Progress';
      case EnquiryStatus.resolved:
        return 'Resolved';
      case EnquiryStatus.closed:
        return 'Closed';
    }
  }

  Color get color {
    switch (this) {
      case EnquiryStatus.open:
        return AppColors.statusPending;
      case EnquiryStatus.inProgress:
        return AppColors.statusInReview;
      case EnquiryStatus.resolved:
        return AppColors.statusApproved;
      case EnquiryStatus.closed:
        return AppColors.statusDraft;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EnquiryStatus.open:
        return AppColors.statusPendingBg;
      case EnquiryStatus.inProgress:
        return AppColors.statusInReviewBg;
      case EnquiryStatus.resolved:
        return AppColors.statusApprovedBg;
      case EnquiryStatus.closed:
        return AppColors.statusDraftBg;
    }
  }
}

enum EnquiryCategory {
  admissions,
  academic,
  financial,
  hostel,
  general;

  String get displayName {
    switch (this) {
      case EnquiryCategory.admissions:
        return 'Admissions & Enrollment';
      case EnquiryCategory.academic:
        return 'Academic & Coursework';
      case EnquiryCategory.financial:
        return 'Fees, Grants & Scholarships';
      case EnquiryCategory.hostel:
        return 'Campus & Hostel Facilities';
      case EnquiryCategory.general:
        return 'General Institutional Enquiry';
    }
  }

  String get shortName {
    switch (this) {
      case EnquiryCategory.admissions:
        return 'Admissions';
      case EnquiryCategory.academic:
        return 'Academic';
      case EnquiryCategory.financial:
        return 'Financial';
      case EnquiryCategory.hostel:
        return 'Facilities';
      case EnquiryCategory.general:
        return 'General';
    }
  }
}

enum EnquiryPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case EnquiryPriority.low:
        return 'Low';
      case EnquiryPriority.medium:
        return 'Medium';
      case EnquiryPriority.high:
        return 'High';
      case EnquiryPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case EnquiryPriority.low:
        return AppColors.priorityLow;
      case EnquiryPriority.medium:
        return AppColors.priorityMedium;
      case EnquiryPriority.high:
        return AppColors.priorityHigh;
      case EnquiryPriority.urgent:
        return AppColors.priorityUrgent;
    }
  }
}

class EnquiryResponse {
  final String id;
  final String authorName;
  final String authorRole;
  final String message;
  final DateTime createdAt;
  final bool isInternal;

  const EnquiryResponse({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.message,
    required this.createdAt,
    this.isInternal = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'authorRole': authorRole,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'isInternal': isInternal,
  };

  factory EnquiryResponse.fromJson(Map<String, dynamic> json) {
    return EnquiryResponse(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      authorRole: json['authorRole'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isInternal: json['isInternal'] as bool? ?? false,
    );
  }
}

class EnquiryAttachment {
  final String id;
  final String name;
  final int sizeBytes;
  final String mimeType;
  final DateTime uploadedAt;

  const EnquiryAttachment({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.uploadedAt,
  });

  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sizeBytes': sizeBytes,
    'mimeType': mimeType,
    'uploadedAt': uploadedAt.toIso8601String(),
  };

  factory EnquiryAttachment.fromJson(Map<String, dynamic> json) {
    return EnquiryAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      sizeBytes: json['sizeBytes'] as int,
      mimeType: json['mimeType'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}

class Enquiry {
  final String id;
  final String title;
  final EnquiryCategory category;
  final String description;
  final String senderName;
  final String senderEmail;
  final String? senderUserId;
  final String? senderPhone;
  final String department;
  final EnquiryPriority priority;
  final EnquiryStatus status;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final List<EnquiryResponse> responses;
  final List<EnquiryAttachment> attachments;
  final Map<String, dynamic> metadata;

  const Enquiry({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.senderName,
    required this.senderEmail,
    this.senderUserId,
    this.senderPhone,
    required this.department,
    this.priority = EnquiryPriority.medium,
    this.status = EnquiryStatus.open,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.responses = const [],
    this.attachments = const [],
    this.metadata = const {},
  });

  bool get isOpen => status == EnquiryStatus.open;
  bool get isInProgress => status == EnquiryStatus.inProgress;
  bool get isResolved => status == EnquiryStatus.resolved;
  bool get isClosed => status == EnquiryStatus.closed;

  Enquiry copyWith({
    String? id,
    String? title,
    EnquiryCategory? category,
    String? description,
    String? senderName,
    String? senderEmail,
    String? senderUserId,
    String? senderPhone,
    String? department,
    EnquiryPriority? priority,
    EnquiryStatus? status,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    List<EnquiryResponse>? responses,
    List<EnquiryAttachment>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return Enquiry(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderUserId: senderUserId ?? this.senderUserId,
      senderPhone: senderPhone ?? this.senderPhone,
      department: department ?? this.department,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      responses: responses ?? this.responses,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.name,
    'description': description,
    'senderName': senderName,
    'senderEmail': senderEmail,
    'senderUserId': senderUserId,
    'senderPhone': senderPhone,
    'department': department,
    'priority': priority.name,
    'status': status.name,
    'assignedTo': assignedTo,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'responses': responses.map((r) => r.toJson()).toList(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'metadata': metadata,
  };

  factory Enquiry.fromJson(Map<String, dynamic> json) {
    return Enquiry(
      id: json['id'] as String,
      title: json['title'] as String,
      category: EnquiryCategory.values.byName(json['category'] as String),
      description: json['description'] as String,
      senderName: json['senderName'] as String,
      senderEmail: json['senderEmail'] as String,
      senderUserId: json['senderUserId'] as String?,
      senderPhone: json['senderPhone'] as String?,
      department: json['department'] as String,
      priority: EnquiryPriority.values.byName(json['priority'] as String),
      status: EnquiryStatus.values.byName(json['status'] as String),
      assignedTo: json['assignedTo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      responses:
          (json['responses'] as List<dynamic>?)
              ?.map((e) => EnquiryResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map(
                (e) => EnquiryAttachment.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final int pageSize;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
  });

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}

class CreateEnquiryDto {
  final String title;
  final EnquiryCategory category;
  final String description;
  final String senderName;
  final String senderEmail;
  final String? senderUserId;
  final String? senderPhone;
  final String department;
  final EnquiryPriority priority;
  final List<EnquiryAttachment> attachments;
  final Map<String, dynamic> metadata;

  const CreateEnquiryDto({
    required this.title,
    required this.category,
    required this.description,
    required this.senderName,
    required this.senderEmail,
    this.senderUserId,
    this.senderPhone,
    required this.department,
    this.priority = EnquiryPriority.medium,
    this.attachments = const [],
    this.metadata = const {},
  });
}

class UpdateEnquiryDto {
  final String? title;
  final EnquiryCategory? category;
  final String? description;
  final String? senderPhone;
  final String? department;
  final EnquiryPriority? priority;
  final String? assignedTo;
  final Map<String, dynamic>? metadata;

  const UpdateEnquiryDto({
    this.title,
    this.category,
    this.description,
    this.senderPhone,
    this.department,
    this.priority,
    this.assignedTo,
    this.metadata,
  });
}
