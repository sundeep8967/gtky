enum NotificationType {
  matchFound,
  planUpdate,
  arrivalReminder,
  ratingReminder,
  newRestaurant,
  premiumOffer,
  referralUpdate,
  systemUpdate,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isRead;
  final bool isSent;
  final String? actionUrl;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
    this.scheduledFor,
    this.isRead = false,
    this.isSent = false,
    this.actionUrl,
    this.imageUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.systemUpdate,
      ),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor']) : null,
      isRead: json['isRead'] ?? false,
      isSent: json['isSent'] ?? false,
      actionUrl: json['actionUrl'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'isRead': isRead,
      'isSent': isSent,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
    };
  }

  bool get isScheduled => scheduledFor != null && scheduledFor!.isAfter(DateTime.now());
  bool get isOverdue => scheduledFor != null && scheduledFor!.isBefore(DateTime.now()) && !isSent;

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? scheduledFor,
    bool? isRead,
    bool? isSent,
    String? actionUrl,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isRead: isRead ?? this.isRead,
      isSent: isSent ?? this.isSent,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}