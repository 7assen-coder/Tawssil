# Tawssil Project / مشروع توصيل

## CI/CD Pipeline / خط أنابيب CI/CD

This project uses GitHub Actions for Continuous Integration and Continuous Delivery (CI/CD). The following steps are automatically executed on each push or pull request to the main branch:

هذا المشروع يستخدم GitHub Actions لتنفيذ خط أنابيب التكامل المستمر/التسليم المستمر (CI/CD). يتم تنفيذ الخطوات التالية تلقائياً عند كل push أو pull request إلى الفرع main:

### Pipeline Steps / خطوات خط الأنابيب

1. **Environment Setup / إعداد البيئة**
   - Install Flutter SDK / تثبيت Flutter SDK
   - Setup PostgreSQL / تثبيت PostgreSQL
   - Configure database / إعداد قاعدة البيانات

2. **Code Verification / التحقق من الكود**
   - Code analysis (flutter analyze) / تحليل الكود
   - Run tests (flutter test) / تشغيل الاختبارات
   - Verify database connection / التحقق من اتصال قاعدة البيانات

3. **Application Building / بناء التطبيق**
   - Build APK and AAB for Android / بناء ملفات APK و AAB للتطبيق
   - Build IPA for iOS / بناء ملف IPA للتطبيق
   - Upload build artifacts / رفع ملفات البناء كـ artifacts

4. **Deployment / النشر**
   - Deploy backend to production server / نشر الخلفية على خادم الإنتاج
   - Release mobile app to stores / نشر التطبيق المحمول على المتاجر

### CI/CD Setup / إعداد CI/CD

To set up the CI/CD pipeline, you need to configure the following GitHub secrets:

لإعداد خط أنابيب CI/CD، تحتاج إلى تكوين الأسرار التالية في GitHub:

#### Backend Secrets / أسرار الخلفية
- `DOCKER_HUB_USERNAME`: Docker Hub username / اسم المستخدم في Docker Hub
- `DOCKER_HUB_ACCESS_TOKEN`: Docker Hub access token / رمز الوصول إلى Docker Hub
- `SERVER_HOST`: Deployment server address / عنوان خادم النشر
- `SERVER_USERNAME`: Server username / اسم المستخدم للخادم
- `SERVER_SSH_KEY`: SSH key for server access / مفتاح SSH للاتصال بالخادم

#### Android Deployment Secrets / أسرار نشر أندرويد
- `PLAY_STORE_JSON_KEY`: Google Play Store JSON key / مفتاح JSON لحساب Google Play Store

#### iOS Deployment Secrets / أسرار نشر iOS
- `PROVISIONING_PROFILE`: Base64 encoded provisioning profile / ملف التوقيع للتطبيق (مشفر بـ base64)
- `CERTIFICATE_P12`: Base64 encoded signing certificate / شهادة التوقيع (مشفرة بـ base64)
- `CERTIFICATE_PASSWORD`: Certificate password / كلمة المرور لشهادة التوقيع
- `APPSTORE_API_KEY_JSON`: App Store Connect API key / مفتاح API لـ App Store Connect

### Usage / كيفية الاستخدام

1. Ensure you have access to the repository / تأكد من أن لديك حق الوصول إلى المستودع
2. Push changes to the main branch / قم بعمل push للتغييرات إلى الفرع main
3. The pipeline will run automatically / سيتم تشغيل خط الأنابيب تلقائياً
4. Monitor workflow progress in the Actions tab on GitHub / يمكنك متابعة سير العمل من خلال تبويب Actions في GitHub

To deploy mobile apps manually:
1. Go to GitHub Actions tab / انتقل إلى تبويب Actions في GitHub
2. Select "Mobile Deployment" workflow / اختر سير عمل "Mobile Deployment"
3. Click "Run workflow" button / انقر على زر "Run workflow"
4. Enter app version and release notes / أدخل إصدار التطبيق وملاحظات الإصدار

### System Requirements / متطلبات النظام

- Flutter SDK 3.19.0 or newer / أو أحدث
- PostgreSQL 17.4 or newer / أو أحدث
- Node.js (optional for testing) / اختياري للاختبارات

### Local Environment Setup / إعداد البيئة المحلية

1. Install Flutter / تثبيت Flutter:
```bash
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"
```

2. Install PostgreSQL / تثبيت PostgreSQL:
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
```

3. Setup Database / إعداد قاعدة البيانات:
```bash
sudo -u postgres psql
CREATE DATABASE tawssil;
ALTER USER postgres WITH PASSWORD 'Ab@2024';
```

4. Configure environment / إعداد البيئة:
```bash
cp env.example .env
# Edit .env file with your configuration
```

5. Run with Docker Compose / تشغيل باستخدام Docker Compose:
```bash
docker-compose up -d
```

### Local Testing / الاختبارات المحلية

You can run tests locally using / يمكنك تشغيل الاختبارات محلياً باستخدام:
```bash
# Frontend tests / اختبارات الواجهة الأمامية
cd tawssil_frontend
flutter test

# Backend tests / اختبارات الواجهة الخلفية
cd ../
python manage.py test
```

### Troubleshooting CI/CD / استكشاف أخطاء CI/CD

If the CI/CD pipeline fails, check:
1. GitHub Actions logs for detailed error messages
2. Verify all required secrets are configured correctly
3. Ensure your code passes all tests locally before pushing
4. Check Docker and container logs for backend deployment issues

## تحسينات نظام استعادة كلمة المرور

تم إجراء التعديلات التالية على نظام استعادة كلمة المرور باستخدام رموز OTP:

### 1. حل مشكلة الرسائل المتعددة
- إضافة متغير `_isSendingOtp` للتحكم في عمليات الإرسال المتزامنة
- تعديل دالة `_sendInitialOTP` لمنع الاستدعاءات المتكررة
- إضافة تأخير بسيط بين محاولات إرسال رموز OTP
- تنظيف متغير `_lastRequestForIdentifier` وإضافة كلمة `final` له

### 2. تحسين تجربة المستخدم
- إضافة دالة `_clearAllSnackbars` لإزالة الإشعارات المتداخلة
- تعديل رسائل الإشعارات لتكون واضحة ومترجمة
- إضافة دعم الترجمات لرسائل نظام استعادة كلمة المرور في الإعدادات الثلاثة (العربية والإنجليزية والفرنسية)

### 3. تحسينات الأمان
- تعديل دالة `setupDebugPrint` لتصفية رسائل السجل التي تحتوي على كلمات مثل "OTP" أو "Code"
- إزالة رمز OTP من الإشعارات في وضع الإنتاج
- إضافة تحقق من الحالة `mounted` قبل تحديث واجهة المستخدم

### 4. معالجة أرقام الهواتف
- تحسين معالجة أرقام الهواتف بإضافة رمز الدولة +222 بشكل صحيح
- مواءمة معالجة رقم الهاتف بين الواجهة والخادم

### 5. تكوين Twilio
- إضافة مفاتيح API الخاصة بـ Twilio في ملف الإعدادات
- تكوين إرسال رسائل SMS حقيقية باستخدام Twilio

بفضل هذه التعديلات، تم تحسين نظام استعادة كلمة المرور بحيث:
- يرسل رمز OTP مرة واحدة فقط
- يخفي رمز OTP من الإشعارات والسجلات
- يعالج أرقام الهواتف بشكل صحيح مع إضافة رمز الدولة +222
- يستخدم Twilio لإرسال رسائل SMS حقيقية