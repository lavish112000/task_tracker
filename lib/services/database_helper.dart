import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'task_tracker.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorValue INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT,
        isCompleted INTEGER NOT NULL,
        priority TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        tags TEXT,
        notes TEXT,
        categoryId TEXT,
        status TEXT NOT NULL,
        recurrenceRule TEXT,
        lastCompletionDate TEXT,
        streakCount INTEGER DEFAULT 0,
        totalTrackedSeconds INTEGER DEFAULT 0,
        workspaceId TEXT,
        aiModel TEXT,
        aiParameters TEXT,
        isAutomated INTEGER DEFAULT 0,
        focusLevel INTEGER DEFAULT 0,
        rewardPoints INTEGER DEFAULT 0,
        locationId TEXT,
        latitude REAL,
        longitude REAL,
        isEncrypted INTEGER DEFAULT 0,
        encryptionKey TEXT,
        mindMapId TEXT,
        relatedMindMapNodes TEXT,
        FOREIGN KEY(categoryId) REFERENCES categories(id)
      );
    ''');
    await db.execute('CREATE INDEX idx_tasks_dueDate ON tasks(dueDate);');
    await db.execute('CREATE INDEX idx_tasks_priority ON tasks(priority);');
    await db.execute('CREATE INDEX idx_tasks_category ON tasks(categoryId);');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status);');
    await db.execute('CREATE INDEX idx_tasks_workspace ON tasks(workspaceId);');
    await db.execute('CREATE INDEX idx_tasks_mindMap ON tasks(mindMapId);');

    await db.execute('''
      CREATE TABLE automation_rules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        triggerType TEXT NOT NULL,
        triggerData TEXT,
        actionType TEXT NOT NULL,
        actionData TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_automation_active ON automation_rules(isActive);');
    await db.execute('''
      CREATE TABLE automation_logs (
        id TEXT PRIMARY KEY,
        ruleId TEXT NOT NULL,
        taskId TEXT NOT NULL,
        actionType TEXT NOT NULL,
        executedAt TEXT NOT NULL,
        message TEXT,
        FOREIGN KEY(ruleId) REFERENCES automation_rules(id) ON DELETE CASCADE,
        FOREIGN KEY(taskId) REFERENCES tasks(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX idx_automation_logs_rule ON automation_logs(ruleId);');
    await db.execute('CREATE INDEX idx_automation_logs_task ON automation_logs(taskId);');

    await db.execute('''
      CREATE TABLE subtasks (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        title TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        dueDate TEXT,
        FOREIGN KEY(taskId) REFERENCES tasks(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX idx_subtasks_taskId ON subtasks(taskId);');

    await db.execute('''
      CREATE TABLE status_changes (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        status TEXT NOT NULL,
        changedAt TEXT NOT NULL,
        FOREIGN KEY(taskId) REFERENCES tasks(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX idx_status_changes_taskId ON status_changes(taskId);');

    await _createV2Structures(db);

    await db.insert('categories', {'id': 'work', 'name': 'Work'});
    await db.insert('categories', {'id': 'personal', 'name': 'Personal'});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final columns = await db.rawQuery('PRAGMA table_info(tasks);');
      final names = columns.map((c) => c['name']).toSet();
      Future<void> addCol(String def) async {
        final colName = def.split(' ').first;
        if (!names.contains(colName)) {
          await db.execute('ALTER TABLE tasks ADD COLUMN $def;');
        }
      }
      await addCol('recurrenceRule TEXT');
      await addCol('lastCompletionDate TEXT');
      await addCol('streakCount INTEGER DEFAULT 0');
      await addCol('totalTrackedSeconds INTEGER DEFAULT 0');
      await addCol('workspaceId TEXT');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_workspace ON tasks(workspaceId);');
      await _createV2Structures(db);
    }

    if (oldVersion < 3) {
      final columns = await db.rawQuery('PRAGMA table_info(tasks);');
      final names = columns.map((c) => c['name']).toSet();
      Future<void> addCol(String def) async {
        final colName = def.split(' ').first;
        if (!names.contains(colName)) {
          await db.execute('ALTER TABLE tasks ADD COLUMN $def;');
        }
      }
      await addCol('aiModel TEXT');
      await addCol('aiParameters TEXT');
      await addCol('isAutomated INTEGER DEFAULT 0');
      await addCol('focusLevel INTEGER DEFAULT 0');
      await addCol('rewardPoints INTEGER DEFAULT 0');
      await addCol('locationId TEXT');
      await addCol('latitude REAL');
      await addCol('longitude REAL');
      await addCol('isEncrypted INTEGER DEFAULT 0');
      await addCol('encryptionKey TEXT');
      await addCol('mindMapId TEXT');
      await addCol('relatedMindMapNodes TEXT');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_mindMap ON tasks(mindMapId);');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS automation_rules (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          triggerType TEXT NOT NULL,
          triggerData TEXT,
          actionType TEXT NOT NULL,
          actionData TEXT,
          isActive INTEGER NOT NULL DEFAULT 1,
          createdAt TEXT NOT NULL
        );
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_automation_active ON automation_rules(isActive);');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS automation_logs (
          id TEXT PRIMARY KEY,
          ruleId TEXT NOT NULL,
          taskId TEXT NOT NULL,
          actionType TEXT NOT NULL,
          executedAt TEXT NOT NULL,
          message TEXT,
          FOREIGN KEY(ruleId) REFERENCES automation_rules(id) ON DELETE CASCADE,
          FOREIGN KEY(taskId) REFERENCES tasks(id) ON DELETE CASCADE
        );
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_automation_logs_rule ON automation_logs(ruleId);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_automation_logs_task ON automation_logs(taskId);');
    }
  }

  Future<void> _createV2Structures(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_dependencies (
        taskId TEXT NOT NULL,
        dependsOnId TEXT NOT NULL,
        PRIMARY KEY (taskId, dependsOnId),
        FOREIGN KEY(taskId) REFERENCES tasks(id) ON DELETE CASCADE,
        FOREIGN KEY(dependsOnId) REFERENCES tasks(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_task_dependencies_task ON task_dependencies(taskId);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS time_logs (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        start TEXT NOT NULL,
        end TEXT,
        durationSeconds INTEGER,
        source TEXT,
        FOREIGN KEY(taskId) REFERENCES tasks(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_time_logs_task ON time_logs(taskId);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS comments (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        userId TEXT,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(taskId) REFERENCES tasks(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_comments_task ON comments(taskId);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attachments (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        fileName TEXT,
        path TEXT,
        mimeType TEXT,
        sizeBytes INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(taskId) REFERENCES tasks(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attachments_task ON attachments(taskId);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workspaces (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workspace_members (
        workspaceId TEXT NOT NULL,
        userId TEXT NOT NULL,
        role TEXT NOT NULL,
        PRIMARY KEY (workspaceId, userId),
        FOREIGN KEY(workspaceId) REFERENCES workspaces(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_assignments (
        taskId TEXT NOT NULL,
        userId TEXT NOT NULL,
        PRIMARY KEY (taskId, userId),
        FOREIGN KEY(taskId) REFERENCES tasks(id) ON DELETE CASCADE
      );
    ''');
  }
}
