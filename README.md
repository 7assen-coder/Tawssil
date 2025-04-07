# مشروع Tawssil

## خط أنابيب CI/CD

هذا المشروع يستخدم GitHub Actions لتنفيذ خط أنابيب التكامل المستمر/التسليم المستمر (CI/CD). يتم تنفيذ الخطوات التالية تلقائياً عند كل push أو pull request إلى الفرع main:

### خطوات خط الأنابيب

1. **إعداد البيئة**
   - تثبيت Flutter SDK
   - تثبيت PostgreSQL
   - إعداد قاعدة البيانات

2. **التحقق من الكود**
   - تحليل الكود (flutter analyze)
   - تشغيل الاختبارات (flutter test)
   - التحقق من اتصال قاعدة البيانات

3. **بناء التطبيق**
   - بناء ملف APK للتطبيق
   - رفع الملف كـ artifact

### كيفية الاستخدام

1. تأكد من أن لديك حق الوصول إلى المستودع
2. قم بعمل push للتغييرات إلى الفرع main
3. سيتم تشغيل خط الأنابيب تلقائياً
4. يمكنك متابعة سير العمل من خلال تبويب Actions في GitHub

### متطلبات النظام

- Flutter SDK 3.19.0 أو أحدث
- PostgreSQL 17.4 أو أحدث
- Node.js (اختياري للاختبارات)

### إعداد البيئة المحلية

1. تثبيت Flutter:
```bash
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"
```

2. تثبيت PostgreSQL:
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
```

3. إعداد قاعدة البيانات:
```bash
sudo -u postgres psql
CREATE DATABASE tawssil;
ALTER USER postgres WITH PASSWORD 'Ab@2024';
```

### الاختبارات المحلية

يمكنك تشغيل الاختبارات محلياً باستخدام:
```bash
cd tawssil_frontend
flutter test
dart lib/test_connection.dart
```