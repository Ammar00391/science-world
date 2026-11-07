import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/core/services/sound_service.dart';
import 'package:science_world/features/settings/data/settings_repository.dart';

void main() {
  test('SettingsRepository instantiation', () {
    final repo = SettingsRepository();
    expect(repo, isNotNull);
  });

  test('SoundService instantiation', () {
    final service = SoundService();
    expect(service, isNotNull);
  });
}
