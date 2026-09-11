import 'package:flutter_test/flutter_test.dart';
import 'package:medlicense/services/credit_recommendation.dart';

void main() {
  const digestive = QualificationRequirementSource(
    id: 'digestive',
    name: '消化器外科専門医',
    organization: '日本専門医機構／日本消化器外科学会',
    requirements: [
      CreditRequirementTarget(label: '消化器外科手術経験', unit: '症例'),
      CreditRequirementTarget(
        label: '日本消化器外科学会の総会又は大会',
        unit: '回',
        mandatory: true,
      ),
      CreditRequirementTarget(label: '日本外科学会定期学術集会', unit: '回'),
    ],
  );
  const surgery = QualificationRequirementSource(
    id: 'surgery',
    name: '外科専門医',
    organization: '日本専門医機構／日本外科学会',
    requirements: [
      CreditRequirementTarget(label: '専門医共通講習', unit: '単位'),
      CreditRequirementTarget(label: '医療安全講習会', unit: '回', mandatory: true),
    ],
  );

  test('医療安全の研修会名を要項の医療安全講習へ照合する', () {
    final result = recommendCreditAllocations(
      title: '第12回 医療安全研修会',
      organizer: '日本医療安全学会',
      extractedCategory: '医療安全講習',
      extractedCredits: 2,
      sources: const [surgery, digestive],
    );

    expect(result, isNotEmpty);
    expect(result.first.qualificationName, '外科専門医');
    expect(result.first.category, '医療安全講習会');
    expect(result.first.suggestedCredits, 2);
  });

  test('学会総会の名称を消化器外科の参加要件へ照合する', () {
    final result = recommendCreditAllocations(
      title: '第722回日本消化器外科学会総会',
      organizer: '日本消化器外科学会',
      sources: const [digestive, surgery],
    );

    expect(result.first.qualificationName, '消化器外科専門医');
    expect(result.first.category, '日本消化器外科学会の総会又は大会');
  });

  test('手術経験のような参加証以外の要項は推薦しない', () {
    final result = recommendCreditAllocations(
      title: '第722回日本消化器外科学会総会',
      organizer: '日本消化器外科学会',
      sources: const [digestive],
    );

    expect(result.map((item) => item.category), isNot(contains('消化器外科手術経験')));
  });
}
