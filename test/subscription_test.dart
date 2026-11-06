import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/features/subscription/data/subscription_service.dart';
import 'package:science_world/features/subscription/data/subscription_model.dart';

void main() {
  test('SubscriptionService can be instantiated', () {
    final service = SubscriptionService();
    expect(service, isNotNull);
  });

  test('ActivationResult preserves server success and message', () {
    const result = ActivationResult(
      success: true,
      message: 'تم التفعيل',
    );
    expect(result.success, isTrue);
    expect(result.message, 'تم التفعيل');
  });

  test('SubscriptionModel isPremium false when status free', () {
    final sub = SubscriptionModel(
      id: '1',
      userId: 'u1',
      status: 'free',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      source: 'manual',
    );
    expect(sub.isPremium, false);
    expect(sub.isExpired, false);
  });
}