import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/features/subscription/data/plan_catalog.dart';

void main() {
  test('standard lesson bank target is 40 = 6 free + 34 paid', () {
    expect(QuestionQuotaPolicy.targetQuestionsPerLesson, 40);
    expect(QuestionQuotaPolicy.freeQuestionsPerLesson, 6);
    expect(QuestionQuotaPolicy.paidQuestionsPerLesson, 34);
    expect(
      QuestionQuotaPolicy.freeQuestionsPerLesson +
          QuestionQuotaPolicy.paidQuestionsPerLesson,
      QuestionQuotaPolicy.targetQuestionsPerLesson,
    );
  });

  test('free students can access only the first six free questions', () {
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.free,
        isPaid: false,
        positionWithinLesson: 6,
      ),
      isTrue,
    );
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.free,
        isPaid: false,
        positionWithinLesson: 7,
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

  test('Silver unlocks 15 questions total: 6 free + 9 paid per lesson', () {
    expect(QuestionQuotaPolicy.paidQuestionLimit(SubscriptionTier.silver), 9);
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.silver,
        isPaid: true,
        positionWithinLesson: 1,
      ),
      isTrue,
    );
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.silver,
        isPaid: true,
        positionWithinLesson: 9,
      ),
      isTrue,
    );
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.silver,
        isPaid: true,
        positionWithinLesson: 10,
      ),
      isFalse,
    );
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.silver,
        isPaid: false,
        positionWithinLesson: 6,
      ),
      isTrue,
    );
  });

  test('Gold unlocks every approved question, not admin permissions', () {
    expect(QuestionQuotaPolicy.paidQuestionLimit(SubscriptionTier.gold), 34);
    expect(
      QuestionQuotaPolicy.canAccessQuestion(
        tier: SubscriptionTier.gold,
        isPaid: true,
        positionWithinLesson: 999,
      ),
      isTrue,
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
