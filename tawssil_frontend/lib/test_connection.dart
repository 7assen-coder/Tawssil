import 'package:tawssil_frontend/database/database.dart';

void main() async {
  print('بدء محاولة الاتصال بقاعدة البيانات...');
  final db = DatabaseService();

  try {
    await db.connect();
    print('✅ تم الاتصال بقاعدة البيانات بنجاح');

    // اختبار استعلام بسيط
    final result = await db.query('SELECT version();');
    print('✅ معلومات قاعدة البيانات:');
    print(result);

    await db.disconnect();
    print('✅ تم إغلاق الاتصال بنجاح');
  } catch (e) {
    print('❌ فشل الاتصال بقاعدة البيانات:');
    print('التفاصيل: $e');
    print('\nنصائح استكشاف الأخطاء:');
    print('1. تأكد من تشغيل خدمة PostgreSQL');
    print('2. تأكد من صحة اسم المستخدم وكلمة المرور');
    print('3. تأكد من وجود قاعدة البيانات Tawssil');
    print('4. تأكد من أن المنفذ 5432 مفتوح');
  }
}
