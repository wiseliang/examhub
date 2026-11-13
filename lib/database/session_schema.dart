import 'package:sqflite/sqflite.dart';

/// 新安装与从 v1 升级使用同一份迁移，保留个人数据和原始节点。
Future<void> migrateSessions(Database db) async {
  await db.execute('''
    CREATE TABLE exam_session (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exam_id INTEGER NOT NULL REFERENCES exam(id) ON DELETE CASCADE,
      year INTEGER CHECK(year IS NULL OR year BETWEEN 1900 AND 2200),
      region TEXT NOT NULL,
      level TEXT NOT NULL DEFAULT '',
      batch TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'unpublished'
        CHECK(status IN ('unpublished','estimated','confirmed','postponed','cancelled')),
      source_url TEXT,
      published_at TEXT,
      verified_at TEXT,
      CHECK(status != 'confirmed' OR (year IS NOT NULL AND source_url IS NOT NULL AND verified_at IS NOT NULL))
    )
  ''');
  await db.execute(
    'ALTER TABLE exam_timeline ADD COLUMN session_id INTEGER REFERENCES exam_session(id) ON DELETE CASCADE',
  );
  await db.execute(
    "ALTER TABLE exam_timeline ADD COLUMN status TEXT NOT NULL DEFAULT 'estimated' CHECK(status IN ('unpublished','estimated','confirmed','postponed','cancelled'))",
  );
  await db.execute('ALTER TABLE exam_timeline ADD COLUMN verified_at TEXT');
  await db.execute(
    'CREATE INDEX timeline_session_idx ON exam_timeline(session_id)',
  );
  await db.execute(
    'CREATE INDEX session_scope_idx ON exam_session(exam_id, year, region)',
  );
  await db.execute('''
    INSERT INTO exam_session(exam_id, region, batch, status)
    SELECT DISTINCT exam_id, '未注明地区', '旧版参考', 'estimated' FROM exam_timeline
  ''');
  await db.execute('''
    UPDATE exam_timeline SET session_id = (
      SELECT id FROM exam_session WHERE exam_session.exam_id = exam_timeline.exam_id
    )
  ''');
}
