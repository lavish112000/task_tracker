import 'package:flutter/material.dart';
import 'package:task_tracker/models/priority_box.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/utils/color_utils.dart';

class StatisticsScreen extends StatefulWidget {
  final List<PriorityBox> priorityBoxes;
  
  const StatisticsScreen({super.key, required this.priorityBoxes});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blue.shade900,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: ColorUtils.withOpacity(Colors.blueAccent, 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            Text(
              'Statistics',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsCards(),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.blueAccent,
                elevation: 8,
              ),
              onPressed: () {},
              child: const Text('Export Data'),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.blue.shade50,
    );
  }

  Widget _buildStatsCards() {
    final allTasks = widget.priorityBoxes.expand((box) => box.tasks).toList();
    final completedTasks = allTasks.where((task) => task.isCompleted).length;
    final totalTasks = allTasks.length;
    final completionRate = totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: ColorUtils.withOpacity(Colors.white, 0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('Total Tasks', totalTasks.toString(), Icons.assignment_outlined, Colors.blue),
            _buildStatCard('Completed', completedTasks.toString(), Icons.check_circle_outline, Colors.green),
            _buildStatCard('Rate', '$completionRate%', Icons.trending_up_rounded, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorUtils.withOpacity(color, 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blueGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
