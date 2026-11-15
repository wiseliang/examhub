import 'package:sqflite/sqflite.dart';

Future<void> migrateCustomExams(Database db) async {
  await db.execute(
    "ALTER TABLE exam ADD COLUMN origin TEXT NOT NULL DEFAULT 'catalog' CHECK(origin IN ('catalog','custom'))",
  );
  await db.execute('ALTER TABLE exam ADD COLUMN target_date TEXT');
}
