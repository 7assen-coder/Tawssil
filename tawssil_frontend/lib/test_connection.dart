import 'package:tawssil_frontend/database/database.dart';
import 'dart:developer' as developer;

void main() async {
  developer.log('بدء محاولة الاتصال بقاعدة البيانات...');
  final db = DatabaseService();

  try {
    await db.connect();
    developer.log('✅ تم الاتصال بقاعدة البيانات بنجاح');

    // اختبار استعلام بسيط
    final result = await db.query('SELECT version();');
    developer.log('✅ معلومات قاعدة البيانات:');
    developer.log(result.toString());

    await db.disconnect();
    developer.log('✅ تم إغلاق الاتصال بنجاح');
  } catch (e) {
    developer.log('❌ فشل الاتصال بقاعدة البيانات:');
    developer.log('التفاصيل: $e');
    developer.log('\nنصائح استكشاف الأخطاء:');
    developer.log('1. تأكد من تشغيل خدمة PostgreSQL');
    developer.log('2. تأكد من صحة اسم المستخدم وكلمة المرور');
    developer.log('3. تأكد من وجود قاعدة البيانات Tawssil');
    developer.log('4. تأكد من أن المنفذ 5432 مفتوح');
  }
}
