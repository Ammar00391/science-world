import 'package:shared_preferences/shared_preferences.dart';

/// Small persistence API for the side-world systems; existing database tables
/// are left untouched. Values are stored locally on this device.
class WorldProgressService {
  Future<int> getExperience() async => (await SharedPreferences.getInstance()).getInt('world_xp') ?? 0;
  Future<int> getRoomLevel() async => (await SharedPreferences.getInstance()).getInt('world_room') ?? 1;
  Future<int> getLabLevel() async => (await SharedPreferences.getInstance()).getInt('world_lab') ?? 1;
  Future<String> getCompanionName() async => (await SharedPreferences.getInstance()).getString('world_companion') ?? 'رفيق';
  Future<void> saveNote(String note) async => (await SharedPreferences.getInstance()).setString('world_note', note);
  Future<String> getNote() async => (await SharedPreferences.getInstance()).getString('world_note') ?? '';
}
