import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_tracker/services/task_service.dart';
import 'package:task_tracker/widgets/hover_wrapper.dart';

import 'package:task_tracker/models/priority_box.dart';
import 'package:task_tracker/models/user.dart';
import 'package:task_tracker/screens/edit_profile_screen.dart';
import 'package:task_tracker/utils/color_utils.dart';

class ProfileScreen extends StatefulWidget {
  final List<PriorityBox> priorityBoxes;
  const ProfileScreen({super.key, required this.priorityBoxes});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user;
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _focusSessions = 0;
  int _totalTrackedSeconds = 0;
  int _totalXP = 0;
  int _maxStreak = 0;
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _defaultEncrypt = false;
  bool _loading = true;
  final _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _user = User(
      id: '1',
      name: 'User',
      email: 'user@example.com',
      profileImagePath: 'https://i.pravatar.cc/150?img=3',
      phoneNumber: '',
    );
    _init();
  }

  Future<void> _init() async {
    await _loadUserFromLocal();
    await _loadStats();
    setState(()=> _loading = false);
  }

  Future<void> _loadUserFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('pref_notifications') ?? true;
    _biometricEnabled = prefs.getBool('pref_biometric') ?? false;
    _defaultEncrypt = prefs.getBool('pref_default_encrypt') ?? false;
    setState(() {
      _user = User(
        id: '1',
        name: prefs.getString('user_name') ?? _user.name,
        email: prefs.getString('user_email') ?? _user.email,
        phoneNumber: prefs.getString('user_phone') ?? _user.phoneNumber,
        profileImagePath: prefs.getString('user_avatar') ?? _user.profileImagePath,
      );
    });
  }

  Future<void> _persistPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_notifications', _notificationsEnabled);
    await prefs.setBool('pref_biometric', _biometricEnabled);
    await prefs.setBool('pref_default_encrypt', _defaultEncrypt);
  }

  Future<void> _loadStats() async {
    final tasks = await _taskService.getTasks();
    _totalTasks = tasks.length;
    _completedTasks = tasks.where((t)=> t.isCompleted).length;
    _focusSessions = tasks.fold(0,(p,t)=> p + t.focusLevel);
    _totalTrackedSeconds = tasks.fold(0,(p,t)=> p + t.totalTrackedSeconds);
    _totalXP = tasks.fold(0,(p,t)=> p + t.rewardPoints);
    _maxStreak = tasks.fold(0,(p,t)=> t.streakCount>p? t.streakCount : p);
  }

  String _fmtDuration(int secs){
    final h = (secs ~/ 3600).toString().padLeft(2,'0');
    final m = ((secs % 3600) ~/ 60).toString().padLeft(2,'0');
    return '$h:$m';
  }

  List<_Achievement> get _achievements {
    final List<_Achievement> list = [];
    if (_totalXP >= 100) list.add(_Achievement('Rookie', 'Earn 100 XP', Icons.emoji_events, Colors.amber));
    if (_totalXP >= 500) list.add(_Achievement('Achiever', 'Earn 500 XP', Icons.military_tech, Colors.orange));
    if (_maxStreak >= 5) list.add(_Achievement('Focused 5', 'Reach 5 streak', Icons.local_fire_department, Colors.redAccent));
    if (_focusSessions >= 20) list.add(_Achievement('Deep Worker', '20 focus sessions', Icons.timer, Colors.indigo));
    if (list.isEmpty) list.add(_Achievement('Getting Started','Complete tasks to unlock achievements', Icons.flag, Colors.grey));
    return list;
  }

  Future<void> _exportData() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data export started (stub).')));
  }
  Future<void> _deleteData() async {
    final confirm = await showDialog<bool>(context: context, builder: (c)=> AlertDialog(
      title: const Text('Delete Data'),
      content: const Text('This will remove all local user preferences (tasks not deleted). Continue?'),
      actions: [TextButton(onPressed: ()=> Navigator.pop(c,false), child: const Text('Cancel')), ElevatedButton(onPressed: ()=> Navigator.pop(c,true), child: const Text('Delete'))],
    ));
    if (confirm==true){
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences cleared')));
      await _loadUserFromLocal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: () async { await _init(); },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _headerCard(theme),
            const SizedBox(height:16),
            _statsGrid(theme),
            const SizedBox(height:16),
            _achievementsSection(theme),
            const SizedBox(height:24),
            Text('Preferences', style: theme.textTheme.titleMedium),
            const SizedBox(height:8),
            _prefSwitch('Notifications', _notificationsEnabled, (v){setState(()=> _notificationsEnabled = v); _persistPrefs();}),
            _prefSwitch('Biometric Login', _biometricEnabled, (v){setState(()=> _biometricEnabled = v); _persistPrefs();}),
            _prefSwitch('Encrypt New Tasks by Default', _defaultEncrypt, (v){setState(()=> _defaultEncrypt = v); _persistPrefs();}),
            const SizedBox(height:24),
            Text('Data & Privacy', style: theme.textTheme.titleMedium),
            const SizedBox(height:8),
            HoverWrapper(onTap: _exportData, child: ListTile(leading: const Icon(Icons.download), title: const Text('Export Data'))),
            HoverWrapper(onTap: _deleteData, child: ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text('Delete Local Preferences'))),
            const SizedBox(height:32),
            Center(child: Text('XP: $_totalXP  •  Streak: $_maxStreak  •  Level ${(1+_totalXP ~/ 250)}', style: theme.textTheme.bodySmall)),
            const SizedBox(height:12),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(ThemeData theme){
    return HoverWrapper(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 42, backgroundImage: NetworkImage(_user.profileImagePath ?? '')),
            const SizedBox(width:16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_user.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height:4),
                  Text(_user.email, style: theme.textTheme.bodySmall),
                  if ((_user.phoneNumber??'').isNotEmpty) Text(_user.phoneNumber!, style: theme.textTheme.bodySmall),
                  const SizedBox(height:8),
                  Wrap(spacing:6, children: [
                    ActionChip(label: const Text('Edit'), avatar: const Icon(Icons.edit,size:16), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> EditProfileScreen(user: _user)) ).then((_)=> _loadUserFromLocal() ) ),
                  ]),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _statsGrid(ThemeData theme){
    final items = [
      _Stat('Tasks', _totalTasks.toString(), Icons.list_alt),
      _Stat('Done', _completedTasks.toString(), Icons.check_circle),
      _Stat('Focus', _focusSessions.toString(), Icons.timer),
      _Stat('Tracked', _fmtDuration(_totalTrackedSeconds), Icons.hourglass_bottom),
      _Stat('XP', _totalXP.toString(), Icons.stars),
      _Stat('Streak', _maxStreak.toString(), Icons.local_fire_department),
    ];
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.3),
      itemBuilder: (c,i){
        final s = items[i];
        return HoverWrapper(
          onTap: null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(s.icon, color: theme.colorScheme.primary),
              const SizedBox(height:6),
              Text(s.label, style: theme.textTheme.bodySmall),
              Text(s.value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }

  Widget _achievementsSection(ThemeData theme){
    final list = _achievements;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Achievements', style: theme.textTheme.titleMedium),
        const SizedBox(height:8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __)=> const SizedBox(width:12),
            itemBuilder: (ctx,i){
              final a = list[i];
              return HoverWrapper(
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(colors: [a.color.withOpacity(.15), a.color.withOpacity(.35)]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(a.icon, color: a.color),
                      const SizedBox(height:8),
                      Text(a.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height:4),
                      Text(a.desc, style: theme.textTheme.bodySmall, maxLines:2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _prefSwitch(String label, bool value, ValueChanged<bool> onChanged){
    return HoverWrapper(
      onTap: ()=> onChanged(!value),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _Stat { final String label; final String value; final IconData icon; _Stat(this.label,this.value,this.icon); }
class _Achievement { final String title; final String desc; final IconData icon; final Color color; _Achievement(this.title,this.desc,this.icon,this.color); }