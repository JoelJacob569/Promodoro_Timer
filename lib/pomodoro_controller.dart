import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'pomodoro_settings_controller.dart';

class PomodoroController extends GetxController with WidgetsBindingObserver {
  final settings = Get.find<PomodoroSettingsController>();

  final isWorkSession = true.obs;
  final isRunning = false.obs;
  final remainingSeconds = 0.obs;
  bool _hasStarted = false;

  DateTime? _endTime;
  Timer? _uiTicker;

  final AudioPlayer _audio = AudioPlayer();
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    _initNotifications();

    // Initial reset (may use default values)
    resetTimer();

    // ✅ only reset if never started
    ever(settings.workMinutes, (_) => _syncIfIdle());
    ever(settings.breakMinutes, (_) => _syncIfIdle());
  }

  void _syncIfIdle() {
    // ✅ only reset if NEVER started
    if (!isRunning.value && !_hasStarted) {
      resetTimer();
    }
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notifications.initialize(
      const InitializationSettings(android: android),
    );
  }

  void startTimer() {
    if (isRunning.value) return;

    _hasStarted = true; // ✅ mark session started

    final secondsToRun = remainingSeconds.value;
    _endTime = DateTime.now().add(Duration(seconds: secondsToRun));
    isRunning.value = true;

    _scheduleNotification(secondsToRun);
    _startTicker();
  }

  void _startTicker() {
    _uiTicker?.cancel();
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds.value <= 0) {
        _uiTicker?.cancel();
        return;
      }

      remainingSeconds.value -= 1;

      if (remainingSeconds.value <= 0) {
        _uiTicker?.cancel();
        isRunning.value = false;
        _endTime = null;
        _onComplete();
      }
    });
  }

  void _adjustTimerAfterResume() {
    if (!isRunning.value || _endTime == null) return;

    final diff = _endTime!.difference(DateTime.now()).inSeconds;
    if (diff <= 0) {
      _uiTicker?.cancel();
      remainingSeconds.value = 0;
      isRunning.value = false;
      _endTime = null;
      _onComplete();
    } else if (diff != remainingSeconds.value) {
      remainingSeconds.value = diff;
    }
  }

  void pauseTimer() {
    _uiTicker?.cancel();
    isRunning.value = false;

    _endTime = null; // 🔑 this marks PAUSED state
    notifications.cancelAll();
  }

  void resetTimer() {
    _uiTicker?.cancel();
    notifications.cancelAll();

    isRunning.value = false;
    _endTime = null;
    _hasStarted = false; // ✅ reset session state

    remainingSeconds.value =
        (isWorkSession.value
            ? settings.workMinutes.value
            : settings.breakMinutes.value) *
        60;
  }

  Future<void> _onComplete() async {
    await _audio.setReleaseMode(ReleaseMode.loop);
    await _audio.play(AssetSource('alert.mp3'));

    Get.dialog(
      AlertDialog(
        title: const Text("Time's Up"),
        content: Text(
          isWorkSession.value
              ? "Work session completed! Take a break ☕"
              : "Break over! Back to work 💪",
        ),
        actions: [
          TextButton(
            onPressed: () {
              _audio.stop();
              Get.back();

              isWorkSession.toggle();

              _hasStarted = false;
              _endTime = null;

              resetTimer();
            },

            child: const Text("OK"),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _scheduleNotification(int seconds) async {
    await notifications.zonedSchedule(
      0,
      'Pomodoro Finished',
      isWorkSession.value ? 'Time for a break ☕' : 'Back to work 💪',
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_channel',
          'Pomodoro',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  String get formattedTime {
    final m = (remainingSeconds.value ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds.value % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _adjustTimerAfterResume();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiTicker?.cancel();
    _audio.dispose();
    super.onClose();
  }
}
