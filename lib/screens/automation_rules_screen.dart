import 'package:flutter/material.dart';
import 'package:task_tracker/models/automation_rule.dart';
import 'package:task_tracker/services/automation_service.dart';
import 'package:task_tracker/models/automation_log.dart';

class AutomationRulesScreen extends StatefulWidget {
  const AutomationRulesScreen({super.key});
  @override
  State<AutomationRulesScreen> createState() => _AutomationRulesScreenState();
}

class _AutomationRulesScreenState extends State<AutomationRulesScreen> {
  final AutomationService _automationService = AutomationService();
  List<AutomationRule> _rules = [];
  bool _loading = true;

  // Logs panel variables
  List<AutomationLog> _logs = [];
  bool _showLogs = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() => _loading = true);
    final rules = await _automationService.getAllRules();
    if (!mounted) return;
    setState(() { _rules = rules; _loading = false; });
  }

  Future<void> _loadLogs() async {
    final logs = await _automationService.getRecentLogs(limit: 50);
    if (!mounted) return;
    setState(() => _logs = logs);
  }

  Future<void> _toggleRule(AutomationRule rule) async {
    await _automationService.toggleRule(rule.id, !rule.isActive);
    await _loadRules();
  }

  Future<void> _deleteRule(AutomationRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rule'),
        content: Text('Are you sure you want to delete "${rule.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await _automationService.deleteRule(rule.id);
      await _loadRules();
    }
  }

  Future<void> _addRule() async {
    await _showRuleDialog();
  }

  Future<void> _showRuleDialog([AutomationRule? existingRule]) async {
    final nameController = TextEditingController(text: existingRule?.name ?? '');
    String triggerType = existingRule?.triggerType ?? 'task_completed';
    String actionType = existingRule?.actionType ?? 'notify';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existingRule == null ? 'Add Automation Rule' : 'Edit Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Rule Name',
                    hintText: 'e.g., "Notify on completion"',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: triggerType,
                  decoration: const InputDecoration(labelText: 'Trigger'),
                  items: const [
                    DropdownMenuItem(value: 'task_completed', child: Text('When task is completed')),
                    DropdownMenuItem(value: 'task_overdue', child: Text('When task becomes overdue')),
                    DropdownMenuItem(value: 'task_created', child: Text('When task is created')),
                  ],
                  onChanged: (value) => setState(() => triggerType = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: actionType,
                  decoration: const InputDecoration(labelText: 'Action'),
                  items: const [
                    DropdownMenuItem(value: 'notify', child: Text('Send notification')),
                    DropdownMenuItem(value: 'escalate_priority', child: Text('Escalate priority')),
                    DropdownMenuItem(value: 'assign_user', child: Text('Assign to user')),
                  ],
                  onChanged: (value) => setState(() => actionType = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, {
                    'name': nameController.text.trim(),
                    'triggerType': triggerType,
                    'actionType': actionType,
                  });
                }
              },
              child: Text(existingRule == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final rule = AutomationRule(
        id: existingRule?.id ?? '',
        name: result['name'],
        triggerType: result['triggerType'],
        actionType: result['actionType'],
      );

      await _automationService.addRule(rule);
      await _loadRules();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rule "${rule.name}" ${existingRule == null ? "added" : "updated"}!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showLogs ? 'Automation Logs' : 'Automation Rules'),
        actions: [
          IconButton(
            icon: Icon(_showLogs ? Icons.rule : Icons.receipt_long),
            tooltip: _showLogs ? 'Show Rules' : 'Show Logs',
            onPressed: () {
              setState(() {
                _showLogs = !_showLogs;
                if (_showLogs) {
                  _loadLogs();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Automation Help'),
                  content: const Text('Create rules to automate actions based on task events. View Logs tab to inspect recent executions.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                ),
              );
            },
          ),
        ],
      ),
      body: _showLogs ? _buildLogsBody() : _buildRulesBody(),
      floatingActionButton: _showLogs ? null : FloatingActionButton(
        onPressed: _addRule,
        child: const Icon(Icons.add),
        tooltip: 'Add Automation Rule',
      ),
    );
  }

  Widget _buildLogsBody() {
    if (_loading && _logs.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLogs,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [SizedBox(height:120), Center(child: Text('No logs yet'))],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadLogs,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16,12,16,80),
        itemCount: _logs.length,
        separatorBuilder: (_, __) => const Divider(height:1),
        itemBuilder: (ctx,i){
          final log = _logs[i];
          return ListTile(
            leading: Icon(Icons.bolt, color: Theme.of(ctx).colorScheme.primary),
            title: Text('${log.actionType} • ${log.ruleId.substring(0,6)}'),
            subtitle: Text('${log.executedAt.toLocal()}\n${log.message ?? ''}'),
            isThreeLine: log.message != null && log.message!.isNotEmpty,
            dense: true,
          );
        },
      ),
    );
  }

  Widget _buildRulesBody() {
    return Column(
      children: [
        // Feature discovery banner
        MaterialBanner(
          content: const Text('Automate your workflow! Create rules to notify, escalate, or assign tasks automatically.'),
          leading: const Icon(Icons.auto_awesome, color: Colors.blue),
          actions: [
            TextButton(
              onPressed: _addRule,
              child: const Text('Add Rule'),
            ),
          ],
        ),
        // Add Rule button (top right)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _addRule,
                icon: const Icon(Icons.add),
                label: const Text('Add Rule'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.smart_toy, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('No automation rules yet'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _addRule,
                            icon: const Icon(Icons.add),
                            label: const Text('Create your first rule'),
                          ),
                          const SizedBox(height: 8),
                          const Text('Automate your workflow with custom rules!', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRules,
                      child: ListView.builder(
                        itemCount: _rules.length,
                        itemBuilder: (context, index) {
                          final rule = _rules[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: rule.isActive ? Colors.green : Colors.grey,
                                child: Icon(
                                  rule.isActive ? Icons.play_arrow : Icons.pause,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(rule.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Trigger: ${_getTriggerLabel(rule.triggerType)}'),
                                  Text('Action: ${_getActionLabel(rule.actionType)}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(rule.isActive ? Icons.pause : Icons.play_arrow, color: rule.isActive ? Colors.orange : Colors.green),
                                    tooltip: rule.isActive ? 'Pause Rule' : 'Activate Rule',
                                    onPressed: () => _toggleRule(rule),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Edit Rule',
                                    onPressed: () => _showRuleDialog(rule),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete Rule',
                                    onPressed: () => _deleteRule(rule),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  String _getTriggerLabel(String triggerType) {
    switch (triggerType) {
      case 'task_completed': return 'Task completed';
      case 'task_overdue': return 'Task overdue';
      case 'task_created': return 'Task created';
      default: return triggerType;
    }
  }

  String _getActionLabel(String actionType) {
    switch (actionType) {
      case 'notify': return 'Send notification';
      case 'escalate_priority': return 'Escalate priority';
      case 'assign_user': return 'Assign to user';
      default: return actionType;
    }
  }
}
