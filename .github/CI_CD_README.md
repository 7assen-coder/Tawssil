# CI/CD Guide for Tawssil App / دليل CI/CD لتطبيق توصيل

This file explains how to set up and run the CI/CD pipelines for the application.

هذا الملف يوضح كيفية إعداد وتشغيل خطوط أنابيب CI/CD للتطبيق.

## File Structure / هيكلة الملفات

The CI/CD pipelines for Tawssil app consist of three main files:

تتكون خطوط أنابيب CI/CD لتطبيق توصيل من ثلاثة ملفات رئيسية:

- `flutter_ci.yml`: For building and testing the user interface (Flutter) / لبناء واختبار واجهة المستخدم (Flutter)
- `backend_ci.yml`: For testing, building, and deploying the backend (Django) / لاختبار وبناء ونشر الواجهة الخلفية (Django)
- `mobile_deployment.yml`: For deploying the app to app stores (Play Store / App Store) / لنشر التطبيق على متاجر التطبيقات (Play Store / App Store)

## Required Secrets / الأسرار المطلوبة

The following secrets must be added to GitHub Repository Secrets:

يجب إضافة الأسرار التالية في إعدادات GitHub Repository Secrets:

### For Backend / للواجهة الخلفية:
- `DOCKER_HUB_USERNAME`: Docker Hub username / اسم المستخدم في Docker Hub
- `DOCKER_HUB_ACCESS_TOKEN`: Docker Hub access token / رمز الوصول إلى Docker Hub
- `SERVER_HOST`: Server address for deployment / عنوان الخادم للنشر
- `SERVER_USERNAME`: Server username / اسم المستخدم للخادم
- `SERVER_SSH_KEY`: SSH key for server connection / مفتاح SSH للاتصال بالخادم

### For Android App Deployment / لنشر التطبيق على Android:
- `PLAY_STORE_JSON_KEY`: JSON key for Google Play Store account / مفتاح JSON لحساب Google Play Store

### For iOS App Deployment / لنشر التطبيق على iOS:
- `PROVISIONING_PROFILE`: App signing profile (base64 encoded) / ملف التوقيع للتطبيق (مشفر بـ base64)
- `CERTIFICATE_P12`: Signing certificate (base64 encoded) / شهادة التوقيع (مشفرة بـ base64)
- `CERTIFICATE_PASSWORD`: Signing certificate password / كلمة المرور لشهادة التوقيع
- `APPSTORE_API_KEY_JSON`: API key for App Store Connect / مفتاح API لـ App Store Connect

## How to Use / كيفية الاستخدام

### Automatic Testing and Building / الاختبار والبناء التلقائي

Testing and building pipelines run automatically when:
- Changes are pushed to main branches (main, master, develop)
- Pull requests are created to these branches

يتم تشغيل خطوط الاختبار والبناء تلقائيًا عند:
- دفع التغييرات إلى الفروع الرئيسية (main, master, develop)
- إنشاء طلب سحب (pull request) إلى هذه الفروع

### Mobile App Deployment / نشر التطبيق المحمول

To deploy the app to app stores:

لنشر التطبيق على متاجر التطبيقات:

1. Go to the "Actions" tab in GitHub / انتقل إلى تبويب "Actions" في GitHub
2. Select "Mobile Deployment" / اختر "Mobile Deployment"
3. Click "Run workflow" / انقر على "Run workflow"
4. Enter:
   - App version (e.g., 1.0.0) / إصدار التطبيق (مثل: 1.0.0)
   - Release notes / ملاحظات الإصدار

## Tips and Guidelines / نصائح وإرشادات

### For Frontend Tests / لاختبارات الواجهة الأمامية:
- Define tests in the `test/` folder within the Flutter project / تأكد من تعريف الاختبارات في مجلد `test/` داخل مشروع Flutter
- Consider using Test-Driven Development (TDD) / ضع في اعتبارك استخدام نهج التطوير المدفوع بالاختبار (TDD)

### For Backend Tests / لاختبارات الواجهة الخلفية:
- Define tests in `tests.py` files within Django apps / تأكد من تعريف الاختبارات في ملفات `tests.py` داخل تطبيقات Django
- Use an independent test database / استخدم قاعدة بيانات اختبار مستقلة

### For Deployment / للنشر:
- Always check deployment settings in `Fastfile` for both Android and iOS / تحقق دائمًا من إعدادات النشر في ملفات `Fastfile` لكل من Android و iOS
- Thoroughly test the app before actual deployment / تأكد من اختبار التطبيق جيدًا قبل النشر الفعلي

## Troubleshooting / استكشاف الأخطاء وإصلاحها

If the CI/CD process fails, check:
1. Error logs in the Actions tab / سجلات الأخطاء في تبويب Actions
2. Validity of secrets and keys / صلاحية الأسرار والمفاتيح
3. File and path configuration in YAML files / تكوين الملفات والمسارات في ملفات YAML
4. Order of execution steps in pipelines / ترتيب تنفيذ الخطوات في خطوط الأنابيب

## Security Best Practices / أفضل ممارسات الأمان

1. Never commit sensitive data directly to the repository / لا تقم أبدًا بإرسال البيانات الحساسة مباشرة إلى المستودع
2. Rotate secrets periodically / قم بتغيير الأسرار بشكل دوري
3. Use limited-scope access tokens / استخدم رموز وصول محدودة النطاق
4. Review workflow permissions in GitHub / راجع أذونات سير العمل في GitHub

## Continuous Improvement / التحسين المستمر

Consider implementing:
1. Security scanning for vulnerabilities / فحص الأمان للثغرات
2. Performance testing in the pipeline / اختبار الأداء في خط الأنابيب
3. Automated UI testing / اختبار واجهة المستخدم الآلي
4. Parallel testing to speed up the pipeline / الاختبار المتوازي لتسريع خط الأنابيب 