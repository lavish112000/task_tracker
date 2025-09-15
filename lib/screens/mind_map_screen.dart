import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/task_service.dart';

class MindMapScreen extends StatefulWidget {
  const MindMapScreen({super.key});
  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _loading = true;
  final Graph graph = Graph()..isTree = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    final tasks = await _taskService.getTasks();
    if (!mounted) return;

    // Build graph from tasks with relationships
    graph.nodes.clear();
    graph.edges.clear();

    for (final task in tasks) {
      final node = Node.Id(task.id);
      graph.addNode(node);
    }

    // Add edges for linked tasks
    for (final task in tasks) {
      final relatedIds = task.relatedMindMapNodes ?? [];
      for (final relatedId in relatedIds) {
        final sourceNode = graph.getNodeUsingId(task.id);
        final targetNode = graph.getNodeUsingId(relatedId);
        // Directly add edge, as nodes are always present
        graph.addEdge(sourceNode, targetNode);
      }
    }

    setState(() { _tasks = tasks; _loading = false; });
  }

  Future<void> _linkTasks(String sourceId, String targetId) async {
    await _taskService.linkTasks(sourceId, targetId);
    await _loadTasks();
  }

  Task? _getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mind Map View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Mind Map Help'),
                  content: const Text('Tap nodes to select tasks. Use the link button to connect related tasks visually.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(child: Text('No tasks to visualize'))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16),
                          const SizedBox(width: 8),
                          const Text('Drag nodes to rearrange • Tap to view task details'),
                          const Spacer(),
                          Text('${_tasks.length} tasks'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: InteractiveViewer(
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(100),
                        minScale: 0.1,
                        maxScale: 2.0,
                        child: GraphView(
                          graph: graph,
                          algorithm: FruchtermanReingoldAlgorithm(iterations: 1000),
                          paint: Paint()
                            ..color = Colors.green
                            ..strokeWidth = 1
                            ..style = PaintingStyle.stroke,
                          builder: (Node node) {
                            final task = _getTaskById(node.key?.value as String? ?? '');
                            return _buildTaskNode(task, node);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLinkDialog,
        tooltip: 'Link Tasks',
        child: const Icon(Icons.link),
      ),
    );
  }

  Widget _buildTaskNode(Task? task, Node node) {
    if (task == null) {
      return Container(
        width: 120,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: const Center(child: Text('Unknown', style: TextStyle(fontSize: 12))),
      );
    }

    Color nodeColor = Colors.blue.shade100;
    if (task.isCompleted) nodeColor = Colors.green.shade100;
    if (task.isOverdue) nodeColor = Colors.red.shade100;

    return GestureDetector(
      onTap: () => _showTaskDetails(task),
      child: Container(
        width: 140,
        height: 80,
        decoration: BoxDecoration(
          color: nodeColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: task.isCompleted ? Colors.green : (task.isOverdue ? Colors.red : Colors.blue),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                task.title.length > 20 ? '${task.title.substring(0, 20)}...' : task.title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                task.priority.name.toUpperCase(),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              if (task.isCompleted)
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${task.description}'),
            const SizedBox(height: 8),
            Text('Priority: ${task.priority.name.toUpperCase()}'),
            Text('Due: ${task.dueDate}'),
            Text('Status: ${task.isCompleted ? "Completed" : "Pending"}'),
            if (task.relatedMindMapNodes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('Linked Tasks: ${task.relatedMindMapNodes!.length}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close')
          ),
        ],
      ),
    );
  }

  void _showLinkDialog() {
    if (_tasks.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 2 tasks to create links')),
      );
      return;
    }

    Task? sourceTask;
    Task? targetTask;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Link Tasks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Task>(
                value: sourceTask,
                hint: const Text('Select source task'),
                isExpanded: true,
                items: _tasks.map((task) => DropdownMenuItem(
                  value: task,
                  child: Text(task.title),
                )).toList(),
                onChanged: (task) => setState(() => sourceTask = task),
              ),
              const SizedBox(height: 16),
              DropdownButton<Task>(
                value: targetTask,
                hint: const Text('Select target task'),
                isExpanded: true,
                items: _tasks.where((t) => t.id != sourceTask?.id).map((task) => DropdownMenuItem(
                  value: task,
                  child: Text(task.title),
                )).toList(),
                onChanged: (task) => setState(() => targetTask = task),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: (sourceTask != null && targetTask != null)
                  ? () {
                      Navigator.pop(ctx);
                      _linkTasks(sourceTask!.id, targetTask!.id);
                    }
                  : null,
              child: const Text('Link'),
            ),
          ],
        ),
      ),
    );
  }
}
