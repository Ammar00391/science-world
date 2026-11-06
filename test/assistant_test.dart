import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/features/assistant/data/assistant_service.dart';

void main() {
  test('AssistantService can be instantiated', () {
    final service = AssistantService();
    expect(service, isNotNull);
  });
}