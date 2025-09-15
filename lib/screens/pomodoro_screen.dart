import 'dart:async';
import 'package:flutter/material.dart';
import 'package:task_tracker/services/task_service.dart';
import 'package:task_tracker/models/task.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int defaultWorkMinutes = 25;
  static const int defaultBreakMinutes = 5;

  int workMinutes = defaultWorkMinutes;
  int breakMinutes = defaultBreakMinutes;
  bool onBreak = false;
  int remainingSeconds = defaultWorkMinutes * 60;
  Timer? _timer;
  final TaskService _taskService = TaskService();
  Task? _selectedTask; // optional association
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskService.getTasks();
    if (!mounted) return;
    setState(() { _tasks = tasks.where((t)=>!t.isCompleted).toList(); _loading = false; });
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds <= 0) {
        _switchPhase();
      } else {
        setState(() { remainingSeconds--; });
      }
    });
  }

  void _pause() { _timer?.cancel(); }

  void _reset() {
    _timer?.cancel();
    setState(() { remainingSeconds = (onBreak ? breakMinutes : workMinutes) * 60; });
  }

  Future<void> _switchPhase() async {
    _timer?.cancel();
    if (!onBreak && _selectedTask != null) {
      // simplistic focus logging via increment focus level
      await _taskService.logFocusSession(_selectedTask!);
    }
    setState(() {
      onBreak = !onBreak;
      remainingSeconds = (onBreak ? breakMinutes : workMinutes) * 60;
    });
    _start();
  }

  String _format(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2,'0');
    final s = (secs % 60).toString().padLeft(2,'0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro Focus')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children:[
              Expanded(child: DropdownButton<Task>(
                isExpanded: true,
                value: _selectedTask,
                hint: const Text('Associate Task (optional)'),
                items: _tasks.map((t)=> DropdownMenuItem(value: t, child: Text(t.title))).toList(),
                onChanged: (t)=> setState(()=> _selectedTask = t),
              )),
            ]),
            const SizedBox(height: 16),
            Row(children:[
              Expanded(child: _numberField('Work (min)', workMinutes, (v){ setState(()=> workMinutes = v); if(!onBreak) remainingSeconds = workMinutes*60; })),
              const SizedBox(width:12),
              Expanded(child: _numberField('Break (min)', breakMinutes, (v){ setState(()=> breakMinutes = v); if(onBreak) remainingSeconds = breakMinutes*60; })),
            ]),
            const SizedBox(height: 32),
            Expanded(child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(onBreak ? 'Break' : 'Focus', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  Text(_format(remainingSeconds), style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Wrap(spacing: 12, children: [
                    ElevatedButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow), label: const Text('Start')),
                    ElevatedButton.icon(onPressed: _pause, icon: const Icon(Icons.pause), label: const Text('Pause')),
                    ElevatedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('Reset')),
                    ElevatedButton.icon(onPressed: _switchPhase, icon: const Icon(Icons.skip_next), label: const Text('Skip')),
                  ])
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _numberField(String label, int value, void Function(int) onChanged) {
    final controller = TextEditingController(text: value.toString());
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onSubmitted: (v){ final n = int.tryParse(v); if(n!=null && n>0) onChanged(n); },
    );
  }
}

