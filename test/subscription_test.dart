import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/features/subscription/data/subscription_service.dart';
import 'package:science_world/features/subscription/data/subscription_model.dart';
import 'package:science_world/features/subscription/data/plan_catalog.dart';

void main() {
  test('SubscriptionService can be instantiated', () {
    final service = SubscriptionService();
    expect(service, isNotNull);
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
  test('future subscription is not active before starts_at', () {
    final now = DateTime.now();
    final sub = SubscriptionModel(
      id: 'scheduled',
      userId: 'u1',
      status: 'premium',
      tier: 'gold',
      startsAt: now.add(const Duration(days: 1)),
      expiresAt: now.add(const Duration(days: 76)),
      createdAt: now,
      updatedAt: now,
      source: 'manual',
    );
    expect(sub.isPremium, isFalse);
    expect(sub.isNotStarted, isTrue);
    expect(sub.isExpired, isFalse);
  });

  test('active subscription must be inside its start and expiry window', () {
    final now = DateTime.now();
    final sub = SubscriptionModel(
      id: 'active',
      userId: 'u1',
      status: 'premium',
      tier: 'silver',
      startsAt: now.subtract(const Duration(days: 1)),
      expiresAt: now.add(const Duration(days: 29)),
      createdAt: now,
      updatedAt: now,
      source: 'manual',
    );
    expect(sub.isPremium, isTrue);
    expect(sub.isNotStarted, isFalse);
  });

  test('approved A1 durations are silver 30 days and gold 75 days', () {
    expect(PlanCatalog.silver.durationDays, 30);
    expect(PlanCatalog.silver.durationLabel, '30 يومًا');
    expect(PlanCatalog.gold.durationDays, 75);
    expect(PlanCatalog.gold.durationLabel, '75 يومًا');
    expect(PlanCatalog.silver.priceSyp, isNull);
    expect(PlanCatalog.gold.priceSyp, isNull);
    expect(PlanCatalog.silver.isConfigured, isFalse);
    expect(PlanCatalog.gold.isConfigured, isFalse);
  });

  test('gold VIP feature keys are gold-only and silver features are shared', () {
    expect(PremiumFeatureAccess.allows(SubscriptionTier.gold, 'unlimited_questions'), isTrue);
    expect(PremiumFeatureAccess.allows(SubscriptionTier.silver, 'unlimited_questions'), isFalse);
    expect(PremiumFeatureAccess.allows(SubscriptionTier.gold, 'ai_tutor'), isTrue);
    expect(PremiumFeatureAccess.allows(SubscriptionTier.silver, 'ai_tutor'), isFalse);
    expect(PremiumFeatureAccess.allows(SubscriptionTier.silver, 'silver_extra_questions'), isTrue);
    expect(PremiumFeatureAccess.allows(SubscriptionTier.gold, 'silver_extra_questions'), isTrue);
  });

  test('unknown premium feature keys fail closed', () {
    expect(PremiumFeatureAccess.allows(SubscriptionTier.gold, 'unknown_feature'), isFalse);
    expect(PremiumFeatureAccess.allows(SubscriptionTier.free, 'ai_tutor'), isFalse);
    expect(PremiumFeatureAccess.allows(SubscriptionTier.silver, 'ai_tutor'), isFalse);
    expect(PremiumFeatureAccess.allows(SubscriptionTier.gold, 'ai_tutor'), isTrue);
  });

}