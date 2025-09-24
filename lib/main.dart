import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init timezone
  tz.initializeTimeZones();

  // Init local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const PomodoroHomePage(),
    );
  }
}

class PomodoroHomePage extends StatefulWidget {
  const PomodoroHomePage({super.key});

  @override
  State<PomodoroHomePage> createState() => _PomodoroHomePageState();
}

class _PomodoroHomePageState extends State<PomodoroHomePage>
    with TickerProviderStateMixin {
  int workMinutes = 25;
  int breakMinutes = 5;

  late int _remainingTime;
  Timer? _timer;
  bool _isRunning = false;
  bool _isWorkSession = true;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _remainingTime = workMinutes * 60;

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(minutes: workMinutes),
    );
  }

  Future<void> _scheduleNotification(int seconds) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Pomodoro Finished 🎉',
      _isWorkSession
          ? 'Work session done! Take a break ☕'
          : 'Break over! Back to work 💪',
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_channel',
          'Pomodoro Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _startTimer() {
    if (_isRunning) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
          _animationController.forward();
        });
      } else {
        _switchSession();
      }
    });

    // 🔔 Schedule background notification
    _scheduleNotification(_remainingTime);

    setState(() {
      _isRunning = true;
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _animationController.stop();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    _animationController.reset();
    setState(() {
      _isRunning = false;
      _remainingTime = (_isWorkSession ? workMinutes : breakMinutes) * 60;
    });
  }

  Future<void> _switchSession() async {
    _timer?.cancel();
    _animationController.reset();

    // Play alert sound
    await _audioPlayer.play(AssetSource('alert.mp3'));

    setState(() {
      _isWorkSession = !_isWorkSession;
      _remainingTime = (_isWorkSession ? workMinutes : breakMinutes) * 60;
      _isRunning = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isWorkSession
              ? "Break over! Back to work 💪"
              : "Work session done! Take a break ☕",
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  void _showCustomSessionDialog() {
    int newWork = workMinutes;
    int newBreak = breakMinutes;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Set Custom Durations"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text("Work (min): "),
                      Expanded(
                        child: Slider(
                          value: newWork.toDouble(),
                          min: 5,
                          max: 90, // ⬅️ increased to 90
                          divisions: 17, // steps of 5
                          label: "$newWork",
                          onChanged: (val) {
                            setStateDialog(() => newWork = val.toInt());
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Break (min): "),
                      Expanded(
                        child: Slider(
                          value: newBreak.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          label: "$newBreak",
                          onChanged: (val) {
                            setStateDialog(() => newBreak = val.toInt());
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      workMinutes = newWork;
                      breakMinutes = newBreak;
                      _resetTimer();
                      _animationController.duration = Duration(
                        minutes: workMinutes,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (_isWorkSession
                ? (_remainingTime / (workMinutes * 60))
                : (_remainingTime / (breakMinutes * 60)))
            .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _isWorkSession
          ? Colors.red.shade100
          : Colors.green.shade100,
      appBar: AppBar(
        title: const Text(
          "Pomodoro Timer",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isWorkSession ? "Work Session" : "Break Time",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: 1 - progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isWorkSession
                          ? const Color.fromARGB(255, 255, 17, 0)
                          : const Color.fromARGB(255, 68, 213, 73),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _formatTime(_remainingTime),
                    key: ValueKey(_remainingTime),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 15,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? "Pause" : "Start"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _showCustomSessionDialog,
              child: Text("Custom"),
            ),
          ],
        ),
      ),
    );
  }
}
