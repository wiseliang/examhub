-- Snapshot of database schema at 792293b, before session migration.

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
    ;

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
    ;

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
    ;

      CREATE TABLE local_follow (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL UNIQUE,
        remind_signup INTEGER DEFAULT 1,
        remind_exam INTEGER DEFAULT 1,
        remind_score INTEGER DEFAULT 1,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (exam_id) REFERENCES exam(id) ON DELETE CASCADE
      )
    ;

      CREATE TABLE local_bookmark (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL UNIQUE,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (exam_id) REFERENCES exam(id) ON DELETE CASCADE
      )
    ;

      CREATE TABLE browse_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        viewed_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (exam_id) REFERENCES exam(id) ON DELETE CASCADE
      )
    ;
