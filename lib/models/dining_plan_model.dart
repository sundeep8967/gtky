enum PlanStatus {
  open,
  matched,
  confirmed,
  completed,
  cancelled,
}

class DiningPlanModel {
  final String id;
  final String creatorId;
  final String restaurantId;
  final DateTime plannedTime;
  final DateTime createdAt;
  final PlanStatus status;
  final List<String> memberIds;
  final int maxMembers;
  final String? description;
  final Map<String, String>? memberCodes; // userId -> unique code
  final DateTime? confirmedAt;
  final List<String>? arrivedMemberIds;

  DiningPlanModel({
    required this.id,
    required this.creatorId,
    required this.restaurantId,
    required this.plannedTime,
    required this.createdAt,
    this.status = PlanStatus.open,
    required this.memberIds,
    this.maxMembers = 4,
    this.description,
    this.memberCodes,
    this.confirmedAt,
    this.arrivedMemberIds,
  });

  factory DiningPlanModel.fromJson(Map<String, dynamic> json) {
    return DiningPlanModel(
      id: json['id'] ?? '',
      creatorId: json['creatorId'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      plannedTime: DateTime.parse(json['plannedTime'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      status: PlanStatus.values.firstWhere(
        (e) => e.toString() == 'PlanStatus.${json['status']}',
        orElse: () => PlanStatus.open,
      ),
      memberIds: List<String>.from(json['memberIds'] ?? []),
      maxMembers: json['maxMembers'] ?? 4,
      description: json['description'],
      memberCodes: json['memberCodes'] != null 
          ? Map<String, String>.from(json['memberCodes'])
          : null,
      confirmedAt: json['confirmedAt'] != null 
          ? DateTime.parse(json['confirmedAt'])
          : null,
      arrivedMemberIds: json['arrivedMemberIds'] != null
          ? List<String>.from(json['arrivedMemberIds'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'restaurantId': restaurantId,
      'plannedTime': plannedTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'memberIds': memberIds,
      'maxMembers': maxMembers,
      'description': description,
      'memberCodes': memberCodes,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'arrivedMemberIds': arrivedMemberIds,
    };
  }

  bool get isFull => memberIds.length >= maxMembers;
  bool get isActive => status == PlanStatus.open || status == PlanStatus.matched;
  bool get canJoin => isActive && !isFull;
  
  int get availableSpots => maxMembers - memberIds.length;
  
  bool hasUser(String userId) => memberIds.contains(userId);
  
  bool get allMembersArrived {
    if (arrivedMemberIds == null || memberCodes == null) return false;
    return arrivedMemberIds!.length == memberIds.length;
  }

  DiningPlanModel copyWith({
    String? id,
    String? creatorId,
    String? restaurantId,
    DateTime? plannedTime,
    DateTime? createdAt,
    PlanStatus? status,
    List<String>? memberIds,
    int? maxMembers,
    String? description,
    Map<String, String>? memberCodes,
    DateTime? confirmedAt,
    List<String>? arrivedMemberIds,
  }) {
    return DiningPlanModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      restaurantId: restaurantId ?? this.restaurantId,
      plannedTime: plannedTime ?? this.plannedTime,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      memberIds: memberIds ?? this.memberIds,
      maxMembers: maxMembers ?? this.maxMembers,
      description: description ?? this.description,
      memberCodes: memberCodes ?? this.memberCodes,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      arrivedMemberIds: arrivedMemberIds ?? this.arrivedMemberIds,
    );
  }
}