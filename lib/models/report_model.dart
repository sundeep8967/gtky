class ReportModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String? description;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved', 'dismissed'
  final String? adminNotes;
  final DateTime? resolvedAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.description,
    required this.createdAt,
    this.status = 'pending',
    this.adminNotes,
    this.resolvedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      reporterId: json['reporterId'] ?? '',
      reportedUserId: json['reportedUserId'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      adminNotes: json['adminNotes'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'adminNotes': adminNotes,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? reason,
    String? description,
    DateTime? createdAt,
    String? status,
    String? adminNotes,
    DateTime? resolvedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}