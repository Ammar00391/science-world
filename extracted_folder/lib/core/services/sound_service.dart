import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Plays original, locally bundled UI tones (not copyrighted music).
class SoundService {
  static const String _soundKey = 'sound_enabled';
  static const String _volumeKey = 'sound_volume';
  AudioPlayer? _player;
  AudioPlayer get _audioPlayer => _player ??= AudioPlayer();

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }
  Future<double> getVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_volumeKey) ?? 0.75;
  }
  Future<void> setVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, value.clamp(0.0, 1.0).toDouble());
    await _audioPlayer.setVolume(value.clamp(0.0, 1.0).toDouble());
  }
  Future<void> _play(String asset, {int vibrationMs = 45}) async {
    if (!await isEnabled()) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(await getVolume());
      await _audioPlayer.play(AssetSource(asset));
    } catch (_) {
      try { if (await Vibration.hasVibrator() ?? false) await Vibration.vibrate(duration: vibrationMs); } catch (_) {}
    }
  }
  Future<void> playCorrect() => _play('audio/correct.wav', vibrationMs: 55);
  Future<void> playWrong() => _play('audio/wrong.wav', vibrationMs: 100);
  Future<void> playXp() => _play('audio/xp.wav', vibrationMs: 35);
  Future<void> playLevelUp() => _play('audio/level_up.wav', vibrationMs: 110);
  Future<void> playAchievement() => _play('audio/achievement.wav', vibrationMs: 85);
  Future<void> playChallengeStart() => _play('audio/challenge_start.wav', vibrationMs: 65);
  Future<void> playChallengeTick() => _play('audio/tick.wav', vibrationMs: 20);
  Future<void> playGoalComplete() => _play('audio/goal_complete.wav', vibrationMs: 70);
  /// Original generated ambient noise for the relaxation area.
  Future<void> playNatureAmbience() async {
    if (!await isEnabled()) return;
    try { await _audioPlayer.setReleaseMode(ReleaseMode.loop); await _audioPlayer.setVolume(await getVolume()); await _audioPlayer.play(AssetSource('audio/nature_ambience.wav')); } catch (_) {}
  }
  Future<void> stopNatureAmbience() async { try { await _audioPlayer.stop(); await _audioPlayer.setReleaseMode(ReleaseMode.release); } catch (_) {} }
  Future<void> dispose() async { await _player?.dispose(); _player = null; }
}
