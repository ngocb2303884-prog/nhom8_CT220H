import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subject.dart';
import '../models/schedule.dart';
import '../models/event.dart';
import '../models/grade.dart';
import 'package:firebase_auth/firebase_auth.dart'; // thu vien firebase

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('student_schedule.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Tăng version lên 2 nếu app đã từng chạy để SQLite tự tạo thêm 2 bảng mới
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Tự động tạo bảng nếu người dùng nâng cấp từ version 1 lên 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS resources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          url TEXT NOT NULL,
          type TEXT,
          FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_streak (
          id INTEGER PRIMARY KEY DEFAULT 1,
          current_streak INTEGER DEFAULT 0,
          last_active_date TEXT
        );
      ''');

      await db.execute('''
        INSERT OR IGNORE INTO user_streak (id, current_streak, last_active_date) 
        VALUES (1, 0, NULL);
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    // bang mon hoc
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT, 
        name TEXT NOT NULL,
        teacher TEXT NOT NULL,
        room TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        credits INTEGER NOT NULL
      )
    ''');

    // bang lich hoc
    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        day_of_week INTEGER NOT NULL,
        start_period INTEGER NOT NULL,
        end_period INTEGER NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // bang diem so
    await db.execute('''
      CREATE TABLE grades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        score REAL NOT NULL,
        weight REAL NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // bang deadline, lich thi
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        date_time TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // 1. Tạo bảng lưu Tài liệu / Resources cho Material Hub
    await db.execute('''
      CREATE TABLE resources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        type TEXT,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      );
    ''');

    // 2. Tạo bảng lưu Chuỗi ngày học tập / Streak
    await db.execute('''
      CREATE TABLE user_streak (
        id INTEGER PRIMARY KEY DEFAULT 1,
        current_streak INTEGER DEFAULT 0,
        last_active_date TEXT
      );
    ''');

    // Khởi tạo sẵn 1 dòng dữ liệu mặc định cho streak
    await db.execute('''
      INSERT INTO user_streak (id, current_streak, last_active_date) 
      VALUES (1, 0, NULL);
    ''');
  }

  // quan ly mon hoc
  Future<int> insertSubject(Subject s) async {
    final db = await database;
    Map<String, dynamic> row = Map<String, dynamic>.from(s.toMap());

    // lay ID ng dung hien tai gan vao data
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      row['userId'] = user.uid;
    }

    return await db.insert('subjects', row);
  }

  Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // lay mon hoc cua nguoi dang dn
      final res = await db.query('subjects', where: 'userId = ?', whereArgs: [user.uid]);
      return res.map((json) => Subject.fromMap(json)).toList();
    }
    return [];
  }

  Future<int> updateSubject(Subject s) async =>
      await (await database).update('subjects', s.toMap(), where: 'id = ?', whereArgs: [s.id]);

  Future<int> deleteSubject(int id) async =>
      await (await database).delete('subjects', where: 'id = ?', whereArgs: [id]);

  // quan ly lich hoc
  Future<int> insertSchedule(Schedule s) async =>
      await (await database).insert('schedules', s.toMap());

  Future<List<Schedule>> getSchedulesForSubject(int subjectId) async {
    final db = await database;
    final res = await db.query('schedules', where: 'subject_id = ?', whereArgs: [subjectId]);
    return res.map((json) => Schedule.fromMap(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getSchedulesForDay(int day) async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // chi lay lich hoc cua cac mon thuoc ve nguoi dang dn
    final res = await db.rawQuery('''
      SELECT 
        schedules.start_period, 
        schedules.end_period, 
        subjects.name AS subject_name, 
        subjects.color_value 
      FROM schedules
      INNER JOIN subjects ON schedules.subject_id = subjects.id
      WHERE schedules.day_of_week = ? AND subjects.userId = ?
      ORDER BY schedules.start_period ASC
    ''', [day, user.uid]);

    return res;
  }

  Future<int> deleteSchedulesForSubject(int subjectId) async =>
      await (await database).delete('schedules', where: 'subject_id = ?', whereArgs: [subjectId]);

  // quan ly diem so
  Future<int> insertGrade(Grade g) async =>
      await (await database).insert('grades', g.toMap());

  Future<List<Grade>> getGradesForSubject(int subjectId) async {
    final db = await database;
    final res = await db.query('grades', where: 'subject_id = ?', whereArgs: [subjectId]);
    return res.map((json) => Grade.fromMap(json)).toList();
  }

  Future<int> deleteGrade(int id) async =>
      await (await database).delete('grades', where: 'id = ?', whereArgs: [id]);

  // quan ly su kien
  Future<int> insertEvent(AcademicEvent e) async =>
      await (await database).insert('events', e.toMap());

  Future<List<AcademicEvent>> getAllEvents() async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // chi lay su kien cua ng dang dn
    final res = await db.rawQuery('''
      SELECT events.* FROM events
      INNER JOIN subjects ON events.subject_id = subjects.id
      WHERE subjects.userId = ?
      ORDER BY events.date_time ASC
    ''', [user.uid]);

    return res.map((json) => AcademicEvent.fromMap(json)).toList();
  }

  Future<int> deleteEvent(int id) async =>
      await (await database).delete('events', where: 'id = ?', whereArgs: [id]);

  // ==================== HÀM CHO MATERIAL HUB ====================

  // Lấy danh sách tài liệu theo môn học
  Future<List<Map<String, dynamic>>> getResourcesBySubject(int subjectId) async {
    final db = await database;
    return await db.query(
      'resources',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
    );
  }

  // Thêm tài liệu mới
  Future<int> insertResource(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('resources', row);
  }

  // Xóa tài liệu
  Future<int> deleteResource(int id) async {
    final db = await database;
    return await db.delete('resources', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== HÀM CHO STREAK SYSTEM ====================

  // Lấy thông tin Streak hiện tại
  Future<Map<String, dynamic>?> getStreakInfo() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query('user_streak', where: 'id = 1');
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // Cập nhật thông tin Streak mới
  Future<int> updateStreakInfo(int newStreak, String lastActiveDate) async {
    final db = await database;
    return await db.update(
      'user_streak',
      {
        'current_streak': newStreak,
        'last_active_date': lastActiveDate,
      },
      where: 'id = 1',
    );
  }
}