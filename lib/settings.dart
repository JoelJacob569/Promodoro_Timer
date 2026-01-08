import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'pomodoro_settings_controller.dart';
import 'pomodoro_controller.dart';

class Settingspage extends StatefulWidget {
  const Settingspage({super.key});

  @override
  State<Settingspage> createState() => _SettingspageState();
}

class _SettingspageState extends State<Settingspage> {
  final settings = Get.find<PomodoroSettingsController>();
  final pomodoro = Get.find<PomodoroController>();

  late int tempWorkMinutes;
  late int tempBreakMinutes;
  late int tempMaxWork;
  late int tempMaxBreak;
  late int tempWorkDiv;
  late int tempBreakDiv;

  double previewWorkSlider = 1;
  double previewBreakSlider = 1;

  late final TextEditingController workCtrl;
  late final TextEditingController breakCtrl;
  late final TextEditingController maxWorkCtrl;
  late final TextEditingController maxBreakCtrl;
  late final TextEditingController workDivCtrl;
  late final TextEditingController breakDivCtrl;

  @override
  void initState() {
    super.initState();

    tempWorkMinutes = settings.workMinutes.value;
    tempBreakMinutes = settings.breakMinutes.value;
    tempMaxWork = settings.maxWorkMinutes.value;
    tempMaxBreak = settings.maxBreakMinutes.value;
    tempWorkDiv = settings.workDivisions.value;
    tempBreakDiv = settings.breakDivisions.value;

    workCtrl = TextEditingController(text: tempWorkMinutes.toString());
    breakCtrl = TextEditingController(text: tempBreakMinutes.toString());
    maxWorkCtrl = TextEditingController(text: tempMaxWork.toString());
    maxBreakCtrl = TextEditingController(text: tempMaxBreak.toString());
    workDivCtrl = TextEditingController(text: tempWorkDiv.toString());
    breakDivCtrl = TextEditingController(text: tempBreakDiv.toString());

    previewWorkSlider = tempWorkMinutes.toDouble();
    previewBreakSlider = tempBreakMinutes.toDouble();
  }

  @override
  void dispose() {
    workCtrl.dispose();
    breakCtrl.dispose();
    maxWorkCtrl.dispose();
    maxBreakCtrl.dispose();
    workDivCtrl.dispose();
    breakDivCtrl.dispose();
    super.dispose();
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("About"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Pomodoro Timer",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text("Created by: Joel Jacob"),
              SizedBox(height: 4),
              Text("Version: 1.1.0"),
              SizedBox(height: 12),
              Text(
                "A simple and elegant Pomodoro timer to help you stay focused and productive.",
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget row(
    String label,
    TextEditingController c,
    void Function(int) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        SizedBox(
          width: 90,
          height: 40,
          child: TextFormField(
            controller: c,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              if (v.isEmpty) return;
              setState(() => onChanged(int.parse(v)));
            },
          ),
        ),
      ],
    );
  }

  void _saveSettings() {
    settings.setWorkMinutes(tempWorkMinutes);
    settings.setBreakMinutes(tempBreakMinutes);
    settings.setMaxWorkMinutes(tempMaxWork);
    settings.setMaxBreakMinutes(tempMaxBreak);
    settings.setWorkDivisions(tempWorkDiv);
    settings.setBreakDivisions(tempBreakDiv);

    pomodoro.resetTimer();
    Get.back();
  }

  void _resetToDefaults() {
    setState(() {
      tempWorkMinutes = 25;
      tempBreakMinutes = 5;
      tempMaxWork = 90;
      tempMaxBreak = 30;
      tempWorkDiv = 17;
      tempBreakDiv = 29;

      workCtrl.text = tempWorkMinutes.toString();
      breakCtrl.text = tempBreakMinutes.toString();
      maxWorkCtrl.text = tempMaxWork.toString();
      maxBreakCtrl.text = tempMaxBreak.toString();
      workDivCtrl.text = tempWorkDiv.toString();
      breakDivCtrl.text = tempBreakDiv.toString();

      previewWorkSlider = tempWorkMinutes.toDouble();
      previewBreakSlider = tempBreakMinutes.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pomodoro.isWorkSession.value
          ? Colors.red.shade100
          : Colors.green.shade100,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            row("Work Minutes", workCtrl, (v) => tempWorkMinutes = v),
            const Divider(),
            row("Break Minutes", breakCtrl, (v) => tempBreakMinutes = v),
            const Divider(),
            row("Max Work Minutes", maxWorkCtrl, (v) {
              tempMaxWork = v;
              previewWorkSlider = previewWorkSlider.clamp(
                1,
                tempMaxWork.toDouble(),
              );
            }),

            const Divider(),
            row("Max Break Minutes", maxBreakCtrl, (v) {
              tempMaxBreak = v;
              previewBreakSlider = previewBreakSlider.clamp(
                1,
                tempMaxBreak.toDouble(),
              );
            }),

            const Divider(),
            row("Work Divisions", workDivCtrl, (v) => tempWorkDiv = v),

            Slider(
              value: previewWorkSlider,
              min: 1,
              max: tempMaxWork.toDouble(),
              label: previewWorkSlider.round().toString(),
              divisions: tempWorkDiv < 1 ? 1 : tempWorkDiv,
              onChanged: (v) {
                setState(() {
                  previewWorkSlider = v;
                });
              },
            ),

            const Divider(),
            row("Break Divisions", breakDivCtrl, (v) => tempBreakDiv = v),

            Slider(
              value: previewBreakSlider,
              min: 1,
              max: tempMaxBreak.toDouble(),
              divisions: tempBreakDiv < 1 ? 1 : tempBreakDiv,
              label: previewBreakSlider.round().toString(),
              onChanged: (v) {
                setState(() {
                  previewBreakSlider = v;
                });
              },
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.restore),
                  label: const Text("Default"),
                ),
                ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text("Save"),
                ),
              ],
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("About"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showAboutDialog,
            ),
          ],
        ),
      ),
    );
  }
}
