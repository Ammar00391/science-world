import '../features/subscription/data/subscription_service.dart' as feature;

/// Backwards-compatible adapter for the older `lib/screens` activation flow.
/// All activation requests are delegated to the single secure RPC service.
class SubscriptionService {
  final feature.SubscriptionService _delegate = feature.SubscriptionService();

  Future<Map<String, dynamic>> redeemCode(String codeText) async {
    final result = await _delegate.activateSubscriptionCode(codeText);
    return {
      'success': result.success,
      'message': result.message,
    };
  }

  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    final subscription = await _delegate.fetchMySubscription();
    if (subscription == null) return null;
    return {
      'id': subscription.id,
      'user_id': subscription.userId,
      'status': subscription.status,
      'tier': subscription.tier,
      'starts_at': subscription.startsAt?.toIso8601String(),
      'expires_at': subscription.expiresAt?.toIso8601String(),
      'activated_by_code_id': subscription.activatedByCodeId,
      'source': subscription.source,
      'created_at': subscription.createdAt.toIso8601String(),
      'updated_at': subscription.updatedAt.toIso8601String(),
    };
  }
}
