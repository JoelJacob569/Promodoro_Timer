import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PomodoroSettingsController extends GetxController {
  final workMinutes = 25.obs;
  final breakMinutes = 5.obs;

  final maxWorkMinutes = 90.obs;
  final maxBreakMinutes = 30.obs;

  final workDivisions = 17.obs;
  final breakDivisions = 29.obs;

  @override
  void onInit() {
    super.onInit();
    _load();

    everAll([
      workMinutes,
      breakMinutes,
      maxWorkMinutes,
      maxBreakMinutes,
      workDivisions,
      breakDivisions,
    ], (_) => _save());
  }

  void _validate() {
    workMinutes.value = workMinutes.value.clamp(1, maxWorkMinutes.value);
    breakMinutes.value = breakMinutes.value.clamp(1, maxBreakMinutes.value);

    workDivisions.value = workDivisions.value.clamp(1, maxWorkMinutes.value);
    breakDivisions.value = breakDivisions.value.clamp(1, maxBreakMinutes.value);
  }

  Future<void> _save() async {
    _validate();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('workMinutes', workMinutes.value);
    prefs.setInt('breakMinutes', breakMinutes.value);
    prefs.setInt('maxWorkMinutes', maxWorkMinutes.value);
    prefs.setInt('maxBreakMinutes', maxBreakMinutes.value);
    prefs.setInt('workDivisions', workDivisions.value);
    prefs.setInt('breakDivisions', breakDivisions.value);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    workMinutes.value = prefs.getInt('workMinutes') ?? 25;
    breakMinutes.value = prefs.getInt('breakMinutes') ?? 5;
    maxWorkMinutes.value = prefs.getInt('maxWorkMinutes') ?? 90;
    maxBreakMinutes.value = prefs.getInt('maxBreakMinutes') ?? 30;
    workDivisions.value = prefs.getInt('workDivisions') ?? 17;
    breakDivisions.value = prefs.getInt('breakDivisions') ?? 29;
    _validate();
  }

  void setWorkMinutes(int v) => workMinutes.value = v;
  void setBreakMinutes(int v) => breakMinutes.value = v;
  void setMaxWorkMinutes(int v) => maxWorkMinutes.value = v;
  void setMaxBreakMinutes(int v) => maxBreakMinutes.value = v;
  void setWorkDivisions(int v) => workDivisions.value = v;
  void setBreakDivisions(int v) => breakDivisions.value = v;
}
