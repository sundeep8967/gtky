enum ReferralStatus {
  pending,
  completed,
  expired,
}

class ReferralModel {
  final String id;
  final String referrerId;
  final String referralCode;
  final String? referredUserId;
  final ReferralStatus status;
  final double creditAmount;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime expiresAt;

  ReferralModel({
    required this.id,
    required this.referrerId,
    required this.referralCode,
    this.referredUserId,
    required this.status,
    required this.creditAmount,
    required this.createdAt,
    this.completedAt,
    required this.expiresAt,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: json['id'] ?? '',
      referrerId: json['referrerId'] ?? '',
      referralCode: json['referralCode'] ?? '',
      referredUserId: json['referredUserId'],
      status: ReferralStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReferralStatus.pending,
      ),
      creditAmount: json['creditAmount']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrerId': referrerId,
      'referralCode': referralCode,
      'referredUserId': referredUserId,
      'status': status.name,
      'creditAmount': creditAmount,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isCompleted => status == ReferralStatus.completed;

  ReferralModel copyWith({
    String? id,
    String? referrerId,
    String? referralCode,
    String? referredUserId,
    ReferralStatus? status,
    double? creditAmount,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? expiresAt,
  }) {
    return ReferralModel(
      id: id ?? this.id,
      referrerId: referrerId ?? this.referrerId,
      referralCode: referralCode ?? this.referralCode,
      referredUserId: referredUserId ?? this.referredUserId,
      status: status ?? this.status,
      creditAmount: creditAmount ?? this.creditAmount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}