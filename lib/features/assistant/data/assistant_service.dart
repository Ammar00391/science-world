import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:science_world/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssistantService {
  final String _functionUrl =
      '${SupabaseConfig.url}/functions/v1/ai-chat';

  Future<String> ask(String prompt, {String? context, String subject = 'عام'}) async {
    try {
      if (!SupabaseConfig.isInitialized) throw 'خدمة الإنترنت غير مهيأة حاليًا';
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) throw 'يجب تسجيل الدخول أولاً';

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'apikey': SupabaseConfig.publishableKey,
        },
        body: jsonEncode({
          'prompt': prompt,
          'context': context,
          'subject': subject,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'لا توجد إجابة';
      } else {
        String message = 'تعذر الاتصال بالمساعد (${response.statusCode})';
        try {
          final payload = jsonDecode(response.body);
          if (payload is Map && payload['error'] is String) {
            message = payload['error'] as String;
          }
        } catch (_) {
          // Keep the safe status message when the server does not return JSON.
        }
        throw message;
      }
    } on SocketException {
      throw 'لا يوجد اتصال بالإنترنت';
    } on TimeoutException {
      throw 'انتهت مهلة الطلب';
    } on FormatException {
      throw 'وصلت استجابة غير مفهومة من المساعد.';
    } on String {
      rethrow;
    } catch (_) {
      throw 'حدث خطأ غير متوقع أثناء الاتصال بالمساعد.';
    }
  }
}