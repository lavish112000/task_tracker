import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:task_tracker/models/priority_box.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/priority.dart';
import 'package:task_tracker/utils/app_colors.dart';
import 'package:intl/intl.dart';

enum TimeRange { today, thisWeek, thisMonth, allTime }
enum SortBy { completion, priority, dueDate }

class StatisticsScreen extends StatefulWidget {
  final List<PriorityBox> priorityBoxes;
  
  const StatisticsScreen({super.key, required this.priorityBoxes});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  TimeRange _selectedTimeRange = TimeRange.allTime;
  SortBy _selectedSortBy = SortBy.completion;
  
  @override
  Widget build(BuildContext context) {
    final taskStats = _calculateTaskStats();
    final priorityStats = _calculatePriorityStats();
    final weeklyStats = _calculateWeeklyStats();
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Statistics'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(taskStats),
                  const SizedBox(height: 24),
                  _buildCompletionChart(taskStats),
                  const SizedBox(height: 24),
                  _buildPriorityChart(priorityStats),
                  const SizedBox(height: 24),
                  _buildWeeklyChart(weeklyStats),
                  const SizedBox(height: 24),
                  _buildTaskList(filteredTasks),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26), // 0.1 * 255 ≈ 26
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Time Range: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ...TimeRange.values.map((range) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(_getTimeRangeLabel(range)),
                  selected: _selectedTimeRange == range,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTimeRange = range;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primaryColor.withAlpha(51), // 0.2 * 255 ≈ 51
                  labelStyle: TextStyle(
                    color: _selectedTimeRange == range 
                        ? AppColors.primaryColor 
                        : Colors.black87,
                    fontWeight: _selectedTimeRange == range 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Sort By: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ...SortBy.values.map((sortBy) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(_getSortByLabel(sortBy)),
                  selected: _selectedSortBy == sortBy,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSortBy = sortBy;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primaryColor.withAlpha(51), // 0.2 * 255 ≈ 51
                  labelStyle: TextStyle(
                    color: _selectedSortBy == sortBy 
                        ? AppColors.primaryColor 
                        : Colors.black87,
                    fontWeight: _selectedSortBy == sortBy 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getTimeRangeLabel(TimeRange range) {
    switch (range) {
      case TimeRange.today:
        return 'Today';
      case TimeRange.thisWeek:
        return 'This Week';
      case TimeRange.thisMonth:
        return 'This Month';
      case TimeRange.allTime:
        return 'All Time';
    }
  }
  
  String _getSortByLabel(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.completion:
        return 'Completion';
      case SortBy.priority:
        return 'Priority';
      case SortBy.dueDate:
        return 'Due Date';
    }
  }
  
  List<Task> _getFilteredTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Filter by time range
    List<Task> filteredTasks = [];
    for (var box in widget.priorityBoxes) {
      for (var task in box.tasks) {
        if (task.dueDate == null) continue;
        
        final taskDate = task.dueDate!;
        final taskDay = DateTime(taskDate.year, taskDate.month, taskDate.day);
        
        bool shouldInclude = false;
        switch (_selectedTimeRange) {
          case TimeRange.today:
            shouldInclude = taskDay.isAtSameMomentAs(today);
            break;
          case TimeRange.thisWeek:
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            shouldInclude = !taskDay.isBefore(weekStart) && !taskDay.isAfter(weekEnd);
            break;
          case TimeRange.thisMonth:
            final monthStart = DateTime(now.year, now.month, 1);
            final monthEnd = DateTime(now.year, now.month + 1, 0);
            shouldInclude = !taskDay.isBefore(monthStart) && !taskDay.isAfter(monthEnd);
            break;
          case TimeRange.allTime:
            shouldInclude = true;
            break;
        }
        
        if (shouldInclude) {
          filteredTasks.add(task);
        }
      }
    }
    
    // Sort tasks
    filteredTasks.sort((a, b) {
      switch (_selectedSortBy) {
        case SortBy.completion:
          return a.isCompleted == b.isCompleted ? 0 : a.isCompleted ? 1 : -1;
        case SortBy.priority:
          return a.priority.index.compareTo(b.priority.index);
        case SortBy.dueDate:
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
      }
    });
    
    return filteredTasks;
  }
  }

  Widget _buildCompletionChart(Map<String, int> stats) {
    final total = stats['total']!;
    final completed = stats['completed']!;
    final pending = stats['pending']!;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Completion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: Colors.green,
                            value: completed.toDouble(),
                            title: '${(completed / total * 100).toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.orange,
                            value: pending.toDouble(),
                            title: '${(pending / total * 100).toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(Colors.green, 'Completed', completed),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.orange, 'Pending', pending),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.blue, 'Total', total),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChart(Map<Priority, int> stats) {
    final data = [
      _BarData(priority: 'High', count: stats[Priority.high] ?? 0, color: Colors.red),
      _BarData(priority: 'Medium', count: stats[Priority.medium] ?? 0, color: Colors.orange),
      _BarData(priority: 'Low', count: stats[Priority.low] ?? 0, color: Colors.green),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasks by Priority',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (data.map((e) => e.count).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${data[groupIndex].count} tasks\n${data[groupIndex].priority}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(data[index].priority),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: item.count.toDouble(),
                          color: item.color,
                          width: 30,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(Map<String, int> stats) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: true, horizontalInterval: 1),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < weekDays.length) {
                            return Text(weekDays[index]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: stats.values.reduce((a, b) => a > b ? a : b).toDouble() + 2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: weekDays.asMap().entries.map((entry) {
                        final dayIndex = entry.key;
                        final day = entry.value;
                        return FlSpot(
                          dayIndex.toDouble(),
                          stats[day]?.toDouble() ?? 0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withAlpha((AppColors.primaryColor.alpha * 0.3).toInt()),
                            AppColors.primaryColor.withAlpha((AppColors.primaryColor.alpha * 0.1).toInt()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, int count) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text('$text: $count'),
      ],
    );
  }

  Widget _buildSummaryCards(Map<String, int> stats) {
    final total = stats['total']!;
    final completed = stats['completed']!;
    final pending = stats['pending']!;
    final completionRate = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0';
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Tasks',
            total.toString(),
            Icons.task,
            AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Completed',
            '$completed ($completionRate%)',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Pending',
            pending.toString(),
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No tasks found for the selected filters',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tasks',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) {
                    // Handle task completion toggle
                  },
                  activeColor: AppColors.primaryColor,
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: task.dueDate != null
                    ? Text(
                        'Due: ${DateFormat('MMM d, y').format(task.dueDate!)}',
                        style: TextStyle(
                          color: task.dueDate!.isBefore(DateTime.now()) && !task.isCompleted
                              ? Colors.red
                              : Colors.grey,
                        ),
                      )
                    : null,
                trailing: _buildPriorityChip(task.priority),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildPriorityChip(Priority priority) {
    final priorityData = {
      Priority.high: {'label': 'High', 'color': Colors.red},
      Priority.medium: {'label': 'Medium', 'color': Colors.orange},
      Priority.low: {'label': 'Low', 'color': Colors.green},
    };
    
    final color = priorityData[priority]!['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((color.alpha * 0.2).toInt()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priorityData[priority]!['label'] as String,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Task> _getFilteredTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Filter by time range
    List<Task> filteredTasks = [];
    for (var box in widget.priorityBoxes) {
      for (var task in box.tasks) {
        if (task.dueDate == null) continue;
        
        final taskDate = task.dueDate!;
        final taskDay = DateTime(taskDate.year, taskDate.month, taskDate.day);
        
        bool shouldInclude = false;
        switch (_selectedTimeRange) {
          case TimeRange.today:
            shouldInclude = taskDay.isAtSameMomentAs(today);
            break;
          case TimeRange.thisWeek:
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            shouldInclude = !taskDay.isBefore(weekStart) && !taskDay.isAfter(weekEnd);
            break;
          case TimeRange.thisMonth:
            final monthStart = DateTime(now.year, now.month, 1);
            final monthEnd = DateTime(now.year, now.month + 1, 0);
            shouldInclude = !taskDay.isBefore(monthStart) && !taskDay.isAfter(monthEnd);
            break;
          case TimeRange.allTime:
            shouldInclude = true;
            break;
        }
        
        if (shouldInclude) {
          filteredTasks.add(task);
        }
      }
    }
    
    // Sort tasks
    filteredTasks.sort((a, b) {
      switch (_selectedSortBy) {
        case SortBy.completion:
          return a.isCompleted == b.isCompleted ? 0 : a.isCompleted ? 1 : -1;
        case SortBy.priority:
          return a.priority.index.compareTo(b.priority.index);
        case SortBy.dueDate:
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
      }
    });
    
    return filteredTasks;
  }

  Map<String, int> _calculateTaskStats() {
    final filteredTasks = _getFilteredTasks();
    final total = filteredTasks.length;
    final completed = filteredTasks.where((task) => task.isCompleted).length;

    return {
      'total': total,
      'completed': completed,
      'pending': total - completed,
    };
  }

  Map<Priority, int> _calculatePriorityStats() {
    final stats = <Priority, int>{
      Priority.high: 0,
      Priority.medium: 0,
      Priority.low: 0,
    };

    final filteredTasks = _getFilteredTasks();
    for (var task in filteredTasks) {
      stats[task.priority] = (stats[task.priority] ?? 0) + 1;
    }

    return stats;
  }

  Map<String, int> _calculateWeeklyStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final weekDays = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };
    
    final filteredTasks = _getFilteredTasks();
    
    for (var task in filteredTasks) {
      if (task.dueDate == null) continue;
      
      final taskDate = task.dueDate!;
      final dayDiff = taskDate.difference(weekStart).inDays;
      
      if (dayDiff >= 0 && dayDiff < 7) {
        final dayName = DateFormat('E').format(taskDate);
        weekDays[dayName] = (weekDays[dayName] ?? 0) + 1;
      }
    }
    
    // Reorder to start with Monday
    final orderedWeekDays = {
      'Mon': weekDays['Mon']!,
      'Tue': weekDays['Tue']!,
      'Wed': weekDays['Wed']!,
      'Thu': weekDays['Thu']!,
      'Fri': weekDays['Fri']!,
      'Sat': weekDays['Sat']!,
      'Sun': weekDays['Sun']!,
    };
    
    return orderedWeekDays;
  }
}

class _BarData {
  final String priority;
  final int count;
  final Color color;

  _BarData({
    required this.priority,
    required this.count,
    required this.color,
  });
}
