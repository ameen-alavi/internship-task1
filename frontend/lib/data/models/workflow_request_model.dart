enum WorkflowCategory {
  leave,
  certificate,
  requisition,
  clearance;

  String get displayName {
    switch (this) {
      case WorkflowCategory.leave:
        return 'Leave Application';
      case WorkflowCategory.certificate:
        return 'Bonafide / NOC Certificate';
      case WorkflowCategory.requisition:
        return 'Equipment & Budget Requisition';
      case WorkflowCategory.clearance:
        return 'Project & Research Clearance';
    }
  }

  String get shortName {
    switch (this) {
      case WorkflowCategory.leave:
        return 'Leave';
      case WorkflowCategory.certificate:
        return 'Certificate';
      case WorkflowCategory.requisition:
        return 'Requisition';
      case WorkflowCategory.clearance:
        return 'Clearance';
    }
  }
}

enum WorkflowStatus {
  pending,
  inReview,
  approved,
  rejected,
  returned,
  draft;

  String get displayName {
    switch (this) {
      case WorkflowStatus.pending:
        return 'Pending';
      case WorkflowStatus.inReview:
        return 'In Review';
      case WorkflowStatus.approved:
        return 'Approved';
      case WorkflowStatus.rejected:
        return 'Rejected';
      case WorkflowStatus.returned:
        return 'Returned for Revision';
      case WorkflowStatus.draft:
        return 'Draft';
    }
  }
}

enum PriorityLevel {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case PriorityLevel.low:
        return 'Low';
      case PriorityLevel.medium:
        return 'Medium';
      case PriorityLevel.high:
        return 'High';
      case PriorityLevel.urgent:
        return 'Urgent';
    }
  }
}

enum StageStatus {
  pending,
  inProgress,
  approved,
  rejected,
  skipped;

  String get displayName {
    switch (this) {
      case StageStatus.pending:
        return 'Waiting';
      case StageStatus.inProgress:
        return 'In Review';
      case StageStatus.approved:
        return 'Approved';
      case StageStatus.rejected:
        return 'Rejected';
      case StageStatus.skipped:
        return 'Skipped';
    }
  }
}

class WorkflowStage {
  final String id;
  final String title;
  final String approverRole;
  final String? approverName;
  final StageStatus status;
  final String? remarks;
  final DateTime? updatedAt;

  const WorkflowStage({
    required this.id,
    required this.title,
    required this.approverRole,
    this.approverName,
    this.status = StageStatus.pending,
    this.remarks,
    this.updatedAt,
  });

  WorkflowStage copyWith({
    String? id,
    String? title,
    String? approverRole,
    String? approverName,
    StageStatus? status,
    String? remarks,
    DateTime? updatedAt,
  }) {
    return WorkflowStage(
      id: id ?? this.id,
      title: title ?? this.title,
      approverRole: approverRole ?? this.approverRole,
      approverName: approverName ?? this.approverName,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'approverRole': approverRole,
    'approverName': approverName,
    'status': status.name,
    'remarks': remarks,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory WorkflowStage.fromJson(Map<String, dynamic> json) {
    return WorkflowStage(
      id: json['id'] as String,
      title: json['title'] as String,
      approverRole: json['approverRole'] as String,
      approverName: json['approverName'] as String?,
      status: StageStatus.values.byName(json['status'] as String),
      remarks: json['remarks'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

class WorkflowComment {
  final String id;
  final String authorName;
  final String authorRole;
  final String content;
  final DateTime createdAt;

  const WorkflowComment({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'authorRole': authorRole,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory WorkflowComment.fromJson(Map<String, dynamic> json) {
    return WorkflowComment(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      authorRole: json['authorRole'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class WorkflowAttachment {
  final String id;
  final String name;
  final int sizeBytes;
  final String mimeType;
  final DateTime uploadedAt;

  const WorkflowAttachment({
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

  factory WorkflowAttachment.fromJson(Map<String, dynamic> json) {
    return WorkflowAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      sizeBytes: json['sizeBytes'] as int,
      mimeType: json['mimeType'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}

class WorkflowRequest {
  final String id;
  final String title;
  final WorkflowCategory category;
  final String description;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String department;
  final PriorityLevel priority;
  final WorkflowStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WorkflowStage> stages;
  final List<WorkflowComment> comments;
  final List<WorkflowAttachment> attachments;
  final Map<String, dynamic> metadata;

  const WorkflowRequest({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.department,
    this.priority = PriorityLevel.medium,
    this.status = WorkflowStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    required this.stages,
    this.comments = const [],
    this.attachments = const [],
    this.metadata = const {},
  });

  int get currentStageIndex {
    for (int i = 0; i < stages.length; i++) {
      if (stages[i].status == StageStatus.inProgress ||
          stages[i].status == StageStatus.pending) {
        return i;
      }
    }
    return stages.length - 1;
  }

  double get progressPercentage {
    if (stages.isEmpty) return 0.0;
    if (status == WorkflowStatus.approved) return 1.0;
    if (status == WorkflowStatus.rejected) return 1.0;

    int completed = stages
        .where((s) => s.status == StageStatus.approved)
        .length;
    return (completed / stages.length).clamp(0.0, 1.0);
  }

  WorkflowRequest copyWith({
    String? id,
    String? title,
    WorkflowCategory? category,
    String? description,
    String? requesterId,
    String? requesterName,
    String? requesterEmail,
    String? department,
    PriorityLevel? priority,
    WorkflowStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<WorkflowStage>? stages,
    List<WorkflowComment>? comments,
    List<WorkflowAttachment>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return WorkflowRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      department: department ?? this.department,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stages: stages ?? this.stages,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.name,
    'description': description,
    'requesterId': requesterId,
    'requesterName': requesterName,
    'requesterEmail': requesterEmail,
    'department': department,
    'priority': priority.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'stages': stages.map((s) => s.toJson()).toList(),
    'comments': comments.map((c) => c.toJson()).toList(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'metadata': metadata,
  };

  factory WorkflowRequest.fromJson(Map<String, dynamic> json) {
    return WorkflowRequest(
      id: json['id'] as String,
      title: json['title'] as String,
      category: WorkflowCategory.values.byName(json['category'] as String),
      description: json['description'] as String,
      requesterId: json['requesterId'] as String,
      requesterName: json['requesterName'] as String,
      requesterEmail: json['requesterEmail'] as String,
      department: json['department'] as String,
      priority: PriorityLevel.values.byName(json['priority'] as String),
      status: WorkflowStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      stages: (json['stages'] as List<dynamic>)
          .map((e) => WorkflowStage.fromJson(e as Map<String, dynamic>))
          .toList(),
      comments:
          (json['comments'] as List<dynamic>?)
              ?.map((e) => WorkflowComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map(
                (e) => WorkflowAttachment.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }
}
