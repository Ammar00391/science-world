import 'package:equatable/equatable.dart';

class SubscriptionModel extends Equatable {
  final String id;
  final String userId;
  final String status;
  final String tier;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final String? activatedByCodeId;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.status,
    this.tier = 'silver',
    this.startsAt,
    this.expiresAt,
    this.activatedByCodeId,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasStarted {
    final now = DateTime.now();
    return startsAt == null || !startsAt!.isAfter(now);
  }

  bool get isPremium {
    final now = DateTime.now();
    return status == 'premium' &&
        (startsAt == null || !startsAt!.isAfter(now)) &&
        (expiresAt == null || expiresAt!.isAfter(now));
  }

  bool get isNotStarted =>
      status == 'premium' && startsAt != null && startsAt!.isAfter(DateTime.now());

  bool get isExpired =>
      status == 'premium' && expiresAt != null && !expiresAt!.isAfter(DateTime.now());

  int get daysRemaining {
    final now = DateTime.now();
    if (!isPremium || expiresAt == null) return 0;
    final remaining = expiresAt!.difference(now).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      status: map['status'] as String,
      tier: (map['tier'] ?? 'silver').toString(),
      startsAt: map['starts_at'] != null ? DateTime.parse(map['starts_at']) : null,
      expiresAt: map['expires_at'] != null ? DateTime.parse(map['expires_at']) : null,
      activatedByCodeId: map['activated_by_code_id'] as String?,
      source: map['source'] as String,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, userId, status, tier, startsAt, expiresAt, activatedByCodeId, source, createdAt, updatedAt];
}