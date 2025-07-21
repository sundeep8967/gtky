class BlockedUserModel {
  final String id;
  final String blockerId;
  final String blockedUserId;
  final DateTime createdAt;
  final String? reason;

  BlockedUserModel({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    required this.createdAt,
    this.reason,
  });

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      id: json['id'] ?? '',
      blockerId: json['blockerId'] ?? '',
      blockedUserId: json['blockedUserId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'createdAt': createdAt.toIso8601String(),
      'reason': reason,
    };
  }

  BlockedUserModel copyWith({
    String? id,
    String? blockerId,
    String? blockedUserId,
    DateTime? createdAt,
    String? reason,
  }) {
    return BlockedUserModel(
      id: id ?? this.id,
      blockerId: blockerId ?? this.blockerId,
      blockedUserId: blockedUserId ?? this.blockedUserId,
      createdAt: createdAt ?? this.createdAt,
      reason: reason ?? this.reason,
    );
  }
}