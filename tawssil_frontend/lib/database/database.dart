import 'package:postgres/postgres.dart';

class DatabaseService {
  late PostgreSQLConnection _connection;

  Future<void> connect() async {
    _connection = PostgreSQLConnection(
      'localhost', // عنوان الخادم
      5432, // المنفذ الافتراضي
      'Tawssil', // اسم قاعدة البيانات
      username: 'postgres', // اسم المستخدم
      password: 'Ab@2024', // كلمة المرور
    );

    await _connection.open();
  }

  Future<void> disconnect() async {
    await _connection.close();
  }

  // مثال على دالة للاستعلام
  Future<List<Map<String, dynamic>>> query(String sql) async {
    final results = await _connection.mappedResultsQuery(sql);
    return results;
  }

  // مثال على دالة للإضافة
  Future<void> insert(String table, Map<String, dynamic> data) async {
    final columns = data.keys.join(', ');
    final values = data.values.map((v) => "'$v'").join(', ');
    final sql = 'INSERT INTO $table ($columns) VALUES ($values)';
    await _connection.execute(sql);
  }
}
