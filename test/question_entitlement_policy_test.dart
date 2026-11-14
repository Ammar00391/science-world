import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/features/subscription/data/plan_catalog.dart';

void main() {
  test('standard lesson bank target is 40 questions per lesson', () {
    expect(QuestionQuotaPolicy.targetQuestionsPerLesson, 40);
    expect(QuestionQuotaPolicy.freeQuestionsPerLesson, 3);
    expect(QuestionQuotaPolicy.silverQuestionsPerLesson, 6);
  });

  test('free students can access only the first three free questions', () {
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.free,
        isPaid: false,
        positionWithinLesson: 3,
      ),
      isTrue,
    );
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.free,
        isPaid: false,
        positionWithinLesson: 4,
      ),
      isFalse,
    );
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.free,
        isPaid: true,
        positionWithinLesson: 1,
      ),
      isFalse,
    );
  });

  test('Silver unlocks three free and three additional paid questions', () {
    expect(QuestionQuotaPolicy.questionLimit(SubscriptionTier.silver), 6);
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.silver,
        isPaid: true,
        positionWithinLesson: 3,
      ),
      isTrue,
    );
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.silver,
        isPaid: true,
        positionWithinLesson: 4,
      ),
      isFalse,
    );
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.silver,
        isPaid: false,
        positionWithinLesson: 3,
      ),
      isTrue,
    );
    expect(
      PremiumFeatureAccess.allows(SubscriptionTier.silver, 'answer_reveal'),
      isTrue,
    );
    expect(
      PremiumFeatureAccess.allows(SubscriptionTier.silver, 'favorites'),
      isTrue,
    );
  });

  test('Gold unlocks at most forty questions, not admin permissions', () {
    expect(QuestionQuotaPolicy.questionLimit(SubscriptionTier.gold), 40);
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.gold,
        isPaid: true,
        positionWithinLesson: 40,
      ),
      isTrue,
    );
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.gold,
        isPaid: false,
        positionWithinLesson: 41,
      ),
      isFalse,
    );
    expect(
      PremiumFeatureAccess.allows(SubscriptionTier.gold, 'admin_dashboard'),
      isFalse,
    );
    expect(
      PremiumFeatureAccess.allows(SubscriptionTier.gold, 'unlimited_questions'),
      isTrue,
    );
    expect(
      PremiumFeatureAccess.allows(SubscriptionTier.silver, 'unlimited_questions'),
      isFalse,
    );
  });
}
