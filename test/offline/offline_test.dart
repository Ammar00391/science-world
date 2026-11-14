import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:science_world/core/services/sound_service.dart';
import 'package:science_world/features/settings/data/settings_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SettingsRepository instantiation', () {
    final repo = SettingsRepository();
    expect(repo, isNotNull);
  });

  test('SoundService instantiation', () {
    final service = SoundService();
    expect(service, isNotNull);
  });

  test('sound and vibration preferences are stored independently', () async {
    final service = SoundService();

    await service.setEnabled(false);
    await service.setVibrationEnabled(true);

    expect(await service.isEnabled(), isFalse);
    expect(await service.isVibrationEnabled(), isTrue);

    await service.setVibrationEnabled(false);
    expect(await service.isVibrationEnabled(), isFalse);
    expect(await service.isEnabled(), isFalse);
  });
}
