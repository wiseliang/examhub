import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/exam.dart';
import '../models/exam_timeline.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'examhub.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 考试主表
    await db.execute('''
      CREATE TABLE exam (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        full_name TEXT NOT NULL,
        category TEXT NOT NULL,
        industry TEXT NOT NULL,
        target_groups TEXT NOT NULL,
        organizing_body TEXT NOT NULL,
        official_website TEXT,
        difficulty INTEGER CHECK(difficulty >= 1 AND difficulty <= 5),
        gold_content REAL,
        description TEXT,
        eligibility TEXT,
        exam_format TEXT,
        subjects TEXT,
        tags TEXT,
        logo_asset_path TEXT
      )
    ''');

    // 时间节点表
    await db.execute('''
      CREATE TABLE exam_timeline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        event_type TEXT NOT NULL,
        period_desc TEXT NOT NULL,
        date TEXT,
        is_estimated INTEGER DEFAULT 1,
        source_url TEXT,
        FOREIGN KEY (exam_id) REFERENCES exam(id) ON DELETE CASCADE
      )
    ''');

    // 官方通知表
    await db.execute('''
      CREATE TABLE exam_notice (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        publish_date TEXT NOT NULL,
        summary TEXT,
        key_points TEXT,
        source_url TEXT,
        fetched_at TEXT,
        FOREIGN KEY (exam_id) REFERENCES exam(id) ON DELETE CASCADE
      )
    ''');

    // 用户关注表(本地)
    await db.execute('''
      CREATE TABLE local_follow (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL UNIQUE,
        remind_signup INTEGER DEFAULT 1,
        remind_exam INTEGER DEFAULT 1,
        remind_score INTEGER DEFAULT 1,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (exam_id) REFERENCES exam(id) ON DELETE CASCADE
      )
    ''');

    // 收藏表(本地)
    await db.execute('''
      CREATE TABLE local_bookmark (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL UNIQUE,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (exam_id) REFERENCES exam(id) ON DELETE CASCADE
      )
    ''');

    // 浏览历史表
    await db.execute('''
      CREATE TABLE browse_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        viewed_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (exam_id) REFERENCES exam(id) ON DELETE CASCADE
      )
    ''');

    // 插入种子数据
    await SeedData.insertAll(db);
  }

  // ==================== 考试查询 ====================

  /// 获取所有考试
  Future<List<Exam>> getAllExams() async {
    final db = await database;
    final maps = await db.query('exam', orderBy: 'gold_content DESC');
    return maps.map((m) => Exam.fromMap(m)).toList();
  }

  /// 按ID获取考试
  Future<Exam?> getExamById(int id) async {
    final db = await database;
    final maps = await db.query('exam', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Exam.fromMap(maps.first);
  }

  /// 搜索考试
  Future<List<Exam>> searchExams(String query) async {
    final db = await database;
    final like = '%$query%';
    final maps = await db.query(
      'exam',
      where:
          'name LIKE ? OR full_name LIKE ? OR description LIKE ? OR industry LIKE ? OR organizing_body LIKE ?',
      whereArgs: [like, like, like, like, like],
      orderBy: 'gold_content DESC',
    );
    return maps.map((m) => Exam.fromMap(m)).toList();
  }

  /// 按维度筛选考试
  Future<List<Exam>> filterExams({
    String? category,
    String? industry,
    String? targetGroup,
    int? minDifficulty,
    int? maxDifficulty,
    double? minGoldContent,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (category != null && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }
    if (industry != null && industry.isNotEmpty) {
      whereClauses.add('industry = ?');
      whereArgs.add(industry);
    }
    if (targetGroup != null && targetGroup.isNotEmpty) {
      whereClauses.add('target_groups LIKE ?');
      whereArgs.add('%$targetGroup%');
    }
    if (minDifficulty != null) {
      whereClauses.add('difficulty >= ?');
      whereArgs.add(minDifficulty);
    }
    if (maxDifficulty != null) {
      whereClauses.add('difficulty <= ?');
      whereArgs.add(maxDifficulty);
    }
    if (minGoldContent != null) {
      whereClauses.add('gold_content >= ?');
      whereArgs.add(minGoldContent);
    }

    final where =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final maps = await db.query(
      'exam',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'gold_content DESC',
    );
    return maps.map((m) => Exam.fromMap(m)).toList();
  }

  /// 按行业分组统计
  Future<Map<String, int>> getExamCountByIndustry() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT industry, COUNT(*) as count FROM exam GROUP BY industry ORDER BY count DESC',
    );
    final map = <String, int>{};
    for (final row in result) {
      map[row['industry'] as String] = row['count'] as int;
    }
    return map;
  }

  /// 获取热门考试（按含金量+热度）
  Future<List<Exam>> getHotExams({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'exam',
      orderBy: 'gold_content DESC, difficulty DESC',
      limit: limit,
    );
    return maps.map((m) => Exam.fromMap(m)).toList();
  }

  /// 按人群获取推荐考试
  Future<List<Exam>> getExamsByTargetGroup(String group, {int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'exam',
      where: 'target_groups LIKE ?',
      whereArgs: ['%$group%'],
      orderBy: 'gold_content DESC',
      limit: limit,
    );
    return maps.map((m) => Exam.fromMap(m)).toList();
  }

  // ==================== 时间节点查询 ====================

  /// 获取考试的时间节点
  Future<List<ExamTimeline>> getTimelines(int examId) async {
    final db = await database;
    final maps = await db.query(
      'exam_timeline',
      where: 'exam_id = ?',
      whereArgs: [examId],
      orderBy: 'date ASC',
    );
    return maps.map((m) => ExamTimeline.fromMap(m)).toList();
  }

  /// 获取近期事件
  Future<List<Map<String, dynamic>>> getUpcomingEvents({int days = 30}) async {
    final db = await database;
    final targetDate =
        DateTime.now().add(Duration(days: days)).toIso8601String();
    final now = DateTime.now().toIso8601String();

    final result = await db.rawQuery('''
      SELECT et.*, e.name as exam_name, e.full_name as exam_full_name
      FROM exam_timeline et
      JOIN exam e ON et.exam_id = e.id
      WHERE et.date IS NOT NULL
        AND et.date >= ?
        AND et.date <= ?
      ORDER BY et.date ASC
    ''', [now, targetDate]);

    return result;
  }

  // ==================== 通知查询 ====================

  /// 获取考试的通知列表
  Future<List<ExamNotice>> getNotices(int examId) async {
    final db = await database;
    final maps = await db.query(
      'exam_notice',
      where: 'exam_id = ?',
      whereArgs: [examId],
      orderBy: 'publish_date DESC',
    );
    return maps.map((m) => ExamNotice.fromMap(m)).toList();
  }

  // ==================== 关注/收藏/历史 ====================

  /// 关注考试
  Future<void> followExam(int examId, {
    bool remindSignup = true,
    bool remindExam = true,
    bool remindScore = true,
  }) async {
    final db = await database;
    await db.insert('local_follow', {
      'exam_id': examId,
      'remind_signup': remindSignup ? 1 : 0,
      'remind_exam': remindExam ? 1 : 0,
      'remind_score': remindScore ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 取消关注
  Future<void> unfollowExam(int examId) async {
    final db = await database;
    await db.delete('local_follow', where: 'exam_id = ?', whereArgs: [examId]);
  }

  /// 是否已关注
  Future<bool> isFollowing(int examId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM local_follow WHERE exam_id = ?',
      [examId],
    );
    return (result.first['c'] as int) > 0;
  }

  /// 获取关注的考试列表
  Future<List<Exam>> getFollowedExams() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT e.* FROM exam e
      INNER JOIN local_follow f ON e.id = f.exam_id
      ORDER BY f.created_at DESC
    ''');
    return maps.map((m) => Exam.fromMap(m)).toList();
  }

  /// 收藏考试
  Future<void> bookmarkExam(int examId) async {
    final db = await database;
    await db.insert(
      'local_bookmark',
      {'exam_id': examId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 取消收藏
  Future<void> unbookmarkExam(int examId) async {
    final db = await database;
    await db.delete(
      'local_bookmark',
      where: 'exam_id = ?',
      whereArgs: [examId],
    );
  }

  /// 是否已收藏
  Future<bool> isBookmarked(int examId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM local_bookmark WHERE exam_id = ?',
      [examId],
    );
    return (result.first['c'] as int) > 0;
  }

  /// 获取收藏列表
  Future<List<Exam>> getBookmarkedExams() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT e.* FROM exam e
      INNER JOIN local_bookmark b ON e.id = b.exam_id
      ORDER BY b.created_at DESC
    ''');
    return maps.map((m) => Exam.fromMap(m)).toList();
  }

  /// 记录浏览历史
  Future<void> recordBrowse(int examId) async {
    final db = await database;
    // 清理旧的重复记录
    await db.delete('browse_history', where: 'exam_id = ?', whereArgs: [examId]);
    await db.insert('browse_history', {
      'exam_id': examId,
      'viewed_at': DateTime.now().toIso8601String(),
    });
  }

  /// 获取浏览历史
  Future<List<Exam>> getBrowseHistory({int limit = 50}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT e.* FROM exam e
      INNER JOIN browse_history h ON e.id = h.exam_id
      ORDER BY h.viewed_at DESC
      LIMIT ?
    ''', [limit]);
    return maps.map((m) => Exam.fromMap(m)).toList();
  }

  /// 重置数据库
  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('local_follow');
    await db.delete('local_bookmark');
    await db.delete('browse_history');
    await db.delete('exam_notice');
    await db.delete('exam_timeline');
    await db.delete('exam');
    await SeedData.insertAll(db);
  }
}
