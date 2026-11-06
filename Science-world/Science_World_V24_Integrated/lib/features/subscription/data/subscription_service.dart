import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import 'subscription_model.dart';

/// A user-facing result returned by the activation RPC.
class ActivationResult {
  final bool success;
  final String message;

  const ActivationResult({required this.success, required this.message});
}

class SubscriptionService {
  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

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

  /// Activates a one-time code through the secure Supabase RPC.
  ///
  /// The current `supabase/schema.sql` declares the RPC as
  /// `activate_subscription(p_user_id uuid, p_code text)`. The SQL function
  /// independently verifies that p_user_id equals auth.uid(), so the app
  /// supplies the ID from the authenticated Supabase session, never from UI
  /// input. Keep these parameter names in sync with the deployed SQL function.
  Future<ActivationResult> activateSubscriptionCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      return const ActivationResult(
        success: false,
        message: 'الرجاء إدخال كود التفعيل.',
      );
    }

    final client = _client;
    if (client == null) {
      return const ActivationResult(
        success: false,
        message: 'خدمة التفعيل غير مهيأة. تحقق من إعدادات الاتصال بـ Supabase.',
      );
    }

    final userId = client.auth.currentSession?.user.id;
    if (userId == null) {
      return const ActivationResult(
        success: false,
        message: 'يجب تسجيل الدخول أولًا قبل تفعيل الاشتراك.',
      );
    }

    try {
      final response = await client.rpc(
        'activate_subscription',
        params: {
          'p_user_id': userId,
          'p_code': normalizedCode,
        },
      );

      if (response == true) {
        return const ActivationResult(
          success: true,
          message: 'تم تفعيل الاشتراك بنجاح! أصبحت المزايا المدفوعة متاحة.',
        );
      }

      return const ActivationResult(
        success: false,
        message: 'لم يتم قبول الكود. قد يكون غير صحيح أو منتهي الصلاحية أو مستخدمًا من قبل، أو تجاوزت عدد المحاولات المسموح.',
      );
    } on PostgrestException {
      return const ActivationResult(
        success: false,
        message: 'تعذر إكمال التفعيل من الخادم. تحقق من إعداد دالة activate_subscription وصلاحياتها ثم أعد المحاولة.',
      );
    } catch (_) {
      return const ActivationResult(
        success: false,
        message: 'حدث خطأ أثناء الاتصال. تحقق من الإنترنت ثم أعد المحاولة.',
      );
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
    } catch (_) {
      return null;
    }
  }
}
