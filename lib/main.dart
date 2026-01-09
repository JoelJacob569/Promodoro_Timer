import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'pomodoro_controller.dart';
import 'pomodoro_settings_controller.dart';
import 'settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  Get.put(PomodoroSettingsController());
  Get.put(PomodoroController());

  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.red[400],
          inactiveTrackColor: Colors.red.shade100,
          thumbColor: Colors.red[400],
          overlayColor: Colors.red.withValues(alpha: 0.2),
          valueIndicatorColor: Colors.red[400],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(140, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
      ),

      home: const PomodoroHomePage(),
    );
  }
}

class PomodoroHomePage extends StatelessWidget {
  const PomodoroHomePage({super.key});

  void _showCustomDialog(
    PomodoroSettingsController settings,
    PomodoroController controller,
  ) {
    int tempWork = settings.workMinutes.value;
    int tempBreak = settings.breakMinutes.value;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Custom Duration"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Productivity"),
                Slider(
                  value: tempWork.toDouble(),
                  min: 1,
                  max: settings.maxWorkMinutes.value.toDouble(),
                  divisions: settings.workDivisions.value,
                  label: "$tempWork",
                  onChanged: (v) {
                    setState(() {
                      tempWork = v.toInt();
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Text("Break"),
                Slider(
                  value: tempBreak.toDouble(),
                  min: 1,
                  max: settings.maxBreakMinutes.value.toDouble(),
                  divisions: settings.breakDivisions.value,
                  label: "$tempBreak",
                  onChanged: (v) {
                    setState(() {
                      tempBreak = v.toInt();
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: Get.back, child: const Text("Close")),
              ElevatedButton(
                onPressed: () {
                  settings.setWorkMinutes(tempWork);
                  settings.setBreakMinutes(tempBreak);
                  controller.resetTimer();
                  Get.back();
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PomodoroController>();
    final settings = Get.find<PomodoroSettingsController>();

    return Obx(() {
      final totalSeconds =
          (controller.isWorkSession.value
              ? settings.workMinutes.value
              : settings.breakMinutes.value) *
          60;

      final progress = controller.remainingSeconds.value / totalSeconds;

      return Scaffold(
        backgroundColor: controller.isWorkSession.value
            ? Colors.red.shade100
            : Colors.green.shade100,
        appBar: AppBar(
          title: const Text("Pomodoro Timer"),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Get.to(const Settingspage()),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.isWorkSession.value
                    ? "Productivity Session"
                    : "Break Time",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 1, end: 1 - progress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            controller.isWorkSession.value
                                ? Colors.red
                                : Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      controller.formattedTime,
                      key: ValueKey(controller.formattedTime),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: controller.isRunning.value
                            ? controller.pauseTimer
                            : controller.startTimer,
                        icon: Icon(
                          controller.isRunning.value
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          controller.isRunning.value ? "Pause" : "Start",
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: controller.resetTimer,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reset"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showCustomDialog(settings, controller),
                    child: const Text("Custom"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
