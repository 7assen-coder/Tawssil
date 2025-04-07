import 'package:tawssil_frontend/database/database.dart';
import 'package:flutter/foundation.dart';

void main() async {
  if (kDebugMode) {
    debugPrint('بدء محاولة الاتصال بقاعدة البيانات...');
  }
  final db = DatabaseService();

  try {
    await db.connect();
    if (kDebugMode) {
      debugPrint('✅ تم الاتصال بقاعدة البيانات بنجاح');
    }

    // اختبار استعلام بسيط
    final result = await db.query('SELECT version();');
    if (kDebugMode) {
      debugPrint('✅ معلومات قاعدة البيانات:');
      debugPrint(result.toString());
    }

    await db.disconnect();
    if (kDebugMode) {
      debugPrint('✅ تم إغلاق الاتصال بنجاح');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ فشل الاتصال بقاعدة البيانات:');
      debugPrint('التفاصيل: $e');
      debugPrint('\nنصائح استكشاف الأخطاء:');
      debugPrint('1. تأكد من تشغيل خدمة PostgreSQL');
      debugPrint('2. تأكد من صحة اسم المستخدم وكلمة المرور');
      debugPrint('3. تأكد من وجود قاعدة البيانات Tawssil');
      debugPrint('4. تأكد من أن المنفذ 5432 مفتوح');
    }
  }
}
