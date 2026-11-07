import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import 'subscription_model.dart';

class SubscriptionService {
  SupabaseClient? get _client =>
      SupabaseConfig.isInitialized ? Supabase.instance.client : null;

  Future<SubscriptionModel?> fetchMySubscription() async {
    final client = _client;
    if (client == null) return null;

    final userId = client.auth.currentSession?.user.id;
    if (userId == null) return null;
    final response = await client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return SubscriptionModel.fromMap(response);
  }

  Future<bool> activateCode(String code) async {
    final client = _client;
    if (client == null) return false;

    final userId = client.auth.currentSession?.user.id;
    if (userId == null) return false;

    try {
      final result = await client.rpc('activate_subscription', params: {
        'p_user_id': userId,
        'p_code': code,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> createPaymentRequest({
    required String name,
    required String phone,
    required String receiptUrl,
  }) async {
    final client = _client;
    if (client == null) return null;

    final userId = client.auth.currentSession?.user.id;
    if (userId == null) return null;
    try {
      final response = await client.from('payment_requests').insert({
        'user_id': userId,
        'name': name,
        'phone': phone,
        'receipt_url': receiptUrl,
      }).select().single();
      return response['id'] as String?;
    } catch (e) {
      return null;
    }
  }
}