enum MatchStatus {
  pending,
  confirmed,
  arrived,
  completed,
  cancelled,
}

class MatchModel {
  final String id;
  final String planId;
  final List<String> memberIds;
  final String restaurantId;
  final DateTime plannedTime;
  final DateTime createdAt;
  final MatchStatus status;
  final Map<String, String> memberCodes; // userId -> unique code
  final List<String> arrivedMemberIds;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final double? totalBill;
  final double? discountAmount;

  MatchModel({
    required this.id,
    required this.planId,
    required this.memberIds,
    required this.restaurantId,
    required this.plannedTime,
    required this.createdAt,
    this.status = MatchStatus.pending,
    required this.memberCodes,
    this.arrivedMemberIds = const [],
    this.confirmedAt,
    this.completedAt,
    this.totalBill,
    this.discountAmount,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] ?? '',
      planId: json['planId'] ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      restaurantId: json['restaurantId'] ?? '',
      plannedTime: DateTime.parse(json['plannedTime'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      status: MatchStatus.values.firstWhere(
        (e) => e.toString() == 'MatchStatus.${json['status']}',
        orElse: () => MatchStatus.pending,
      ),
      memberCodes: Map<String, String>.from(json['memberCodes'] ?? {}),
      arrivedMemberIds: List<String>.from(json['arrivedMemberIds'] ?? []),
      confirmedAt: json['confirmedAt'] != null 
          ? DateTime.parse(json['confirmedAt'])
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
      totalBill: json['totalBill']?.toDouble(),
      discountAmount: json['discountAmount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'memberIds': memberIds,
      'restaurantId': restaurantId,
      'plannedTime': plannedTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'memberCodes': memberCodes,
      'arrivedMemberIds': arrivedMemberIds,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'totalBill': totalBill,
      'discountAmount': discountAmount,
    };
  }

  bool get allMembersArrived => arrivedMemberIds.length == memberIds.length;
  bool get isActive => status == MatchStatus.confirmed || status == MatchStatus.arrived;
  
  String getCodeForUser(String userId) => memberCodes[userId] ?? '';
  
  bool hasUserArrived(String userId) => arrivedMemberIds.contains(userId);

  MatchModel copyWith({
    String? id,
    String? planId,
    List<String>? memberIds,
    String? restaurantId,
    DateTime? plannedTime,
    DateTime? createdAt,
    MatchStatus? status,
    Map<String, String>? memberCodes,
    List<String>? arrivedMemberIds,
    DateTime? confirmedAt,
    DateTime? completedAt,
    double? totalBill,
    double? discountAmount,
  }) {
    return MatchModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      memberIds: memberIds ?? this.memberIds,
      restaurantId: restaurantId ?? this.restaurantId,
      plannedTime: plannedTime ?? this.plannedTime,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      memberCodes: memberCodes ?? this.memberCodes,
      arrivedMemberIds: arrivedMemberIds ?? this.arrivedMemberIds,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      totalBill: totalBill ?? this.totalBill,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}