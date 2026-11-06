import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:science_world/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssistantService {
  final String _functionUrl =
      '${SupabaseConfig.url}/functions/v1/ai-chat';

  Future<String> ask(String prompt, {String? context}) async {
    try {
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
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'لا توجد إجابة';
      } else {
        throw 'حدث خطأ في الخادم (${response.statusCode})';
      }
    } on SocketException {
      throw 'لا توجد اتصال بالإنترنت';
    } on TimeoutException {
      throw 'انتهت مهلة الطلب';
    } catch (e) {
      throw 'حدث خطأ: $e';
    }
  }
}