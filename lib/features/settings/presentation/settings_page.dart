import 'package:flutter/material.dart';

import '../../../app/theme/app_theme_controller.dart';
import '../../../core/services/sound_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _sound = SoundService();
  final _themeController = AppThemeController.instance;
  bool _enabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = false;
  bool _reduceMotionEnabled = false;
  double _volume = .75;
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await _sound.isEnabled();
      final vibrationEnabled = await _sound.isVibrationEnabled();
      final volume = await _sound.getVolume();
      await _themeController.load();
      if (!mounted) return;
      setState(() {
        _enabled = enabled;
        _vibrationEnabled = vibrationEnabled;
        _volume = volume;
        _darkModeEnabled = _themeController.mode == ThemeMode.dark;
        _reduceMotionEnabled = _themeController.reduceMotion;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Settings unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _loading = false;
          _message = 'تعذر تحميل بعض الإعدادات. أعد فتح الصفحة للمحاولة.';
        });
      }
    }
  }

  Future<void> _setDarkMode(bool enabled) async {
    try {
      await _themeController.setMode(enabled ? ThemeMode.dark : ThemeMode.light);
      if (mounted) setState(() => _darkModeEnabled = enabled);
    } catch (error) {
      debugPrint('Theme preference save failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ إعداد الوضع الليلي. حاول مجددًا.')),
      );
    }
  }

  Future<void> _setReduceMotion(bool enabled) async {
    try {
      await _themeController.setReduceMotion(enabled);
      if (mounted) setState(() => _reduceMotionEnabled = enabled);
    } catch (error) {
      debugPrint('Reduce-motion preference save failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ إعداد تقليل الحركة. حاول مجددًا.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            children: [
              const ListTile(
                leading: Icon(Icons.text_fields),
                title: Text('حجم النص'),
                subtitle: Text('يتبع إعداد حجم الخط في جهازك'),
              ),
              const ListTile(
                leading: Icon(Icons.language),
                title: Text('لغة التطبيق'),
                subtitle: Text('العربية'),
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('الوضع الليلي'),
                subtitle: Text(_darkModeEnabled ? 'مفعّل' : 'غير مفعّل'),
                value: _darkModeEnabled,
                onChanged: _loading ? null : _setDarkMode,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.animation),
                title: const Text('تقليل الحركات'),
                subtitle: Text(
                  _reduceMotionEnabled
                      ? 'الحركات مخففة'
                      : 'احترام إعداد تقليل الحركة في الجهاز',
                ),
                value: _reduceMotionEnabled,
                onChanged: _loading ? null : _setReduceMotion,
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.graphic_eq),
                title: Text('المؤثرات الصوتية'),
                subtitle: Text('أصوات أصلية للإجابات والتحديات والإنجازات'),
              ),
              if (_loading)
                const LinearProgressIndicator()
              else ...[
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up),
                  title: const Text('تشغيل المؤثرات'),
                  subtitle: Text(_enabled ? 'الأصوات مفعّلة' : 'الوضع الصامت'),
                  value: _enabled,
                  onChanged: (value) async {
                    await _sound.setEnabled(value);
                    if (!mounted) return;
                    setState(() => _enabled = value);
                    if (value) await _sound.playXp();
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: const Text('الاهتزاز'),
                  subtitle: Text(_vibrationEnabled ? 'الاهتزاز مفعّل' : 'الاهتزاز متوقف'),
                  value: _vibrationEnabled,
                  onChanged: (value) async {
                    await _sound.setVibrationEnabled(value);
                    if (mounted) setState(() => _vibrationEnabled = value);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('مستوى الصوت'),
                  subtitle: Slider(
                    value: _volume,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: '${(_volume * 100).round()}%',
                    onChanged: _enabled
                        ? (value) async {
                            await _sound.setVolume(value);
                            if (mounted) setState(() => _volume = value);
                          }
                        : null,
                  ),
                  trailing: Text('${(_volume * 100).round()}%'),
                ),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('تجربة الصوت'),
                  subtitle: const Text('تشغيل نغمة أصلية قصيرة'),
                  onTap: _sound.playAchievement,
                ),
              ],
              const Divider(),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('حول التطبيق'),
                subtitle: Text('عالم العلوم • الإصدار 2.2.3+25'),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_message!, textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      );
}
