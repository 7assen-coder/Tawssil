# CI/CD Guide for Tawssil App / دليل CI/CD لتطبيق توصيل

This file explains how to set up and run the CI/CD pipelines for the application.

هذا الملف يوضح كيفية إعداد وتشغيل خطوط أنابيب CI/CD للتطبيق.

## File Structure / هيكلة الملفات

The CI/CD pipelines for Tawssil app consist of three main files:

تتكون خطوط أنابيب CI/CD لتطبيق توصيل من ثلاثة ملفات رئيسية:

- `flutter_ci.yml`: For building and testing the user interface (Flutter) / لبناء واختبار واجهة المستخدم (Flutter)
- `backend_ci.yml`: For testing, building, and deploying the backend (Django) / لاختبار وبناء ونشر الواجهة الخلفية (Django)
- `mobile_deployment.yml`: For deploying the app to app stores (Play Store / App Store) / لنشر التطبيق على متاجر التطبيقات (Play Store / App Store)

## Enhanced Features / الميزات المحسّنة

Our CI/CD pipeline now includes:

تتضمن خطوط أنابيب CI/CD الخاصة بنا الآن:

1. **Security Scanning / فحص الأمان**
   - OWASP Dependency-Check for frontend / فحص التبعيات لواجهة المستخدم
   - Safety and Bandit tools for backend / أدوات Safety و Bandit للواجهة الخلفية

2. **Performance Testing / اختبار الأداء**
   - Locust performance testing for backend / اختبار الأداء باستخدام Locust للواجهة الخلفية
   - Automated reports for review / تقارير آلية للمراجعة

3. **Phased Rollout / النشر التدريجي**
   - Controlled percentage rollout for Android / نشر تدريجي محكوم لأجهزة Android
   - Phased release for iOS / إصدار تدريجي لأجهزة iOS

4. **Validation / التحقق**
   - Version format validation / التحقق من تنسيق الإصدار
   - Automated testing before deployment / اختبار آلي قبل النشر

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

### Security Report Review / مراجعة تقارير الأمان

To review security reports:
1. Go to the "Actions" tab in GitHub / انتقل إلى تبويب "Actions" في GitHub
2. Select the most recent workflow run / اختر أحدث تشغيل لسير العمل
3. Download artifacts from the "Artifacts" section / قم بتنزيل المخرجات من قسم "Artifacts"
4. Review the HTML reports for security issues / راجع تقارير HTML للمشاكل الأمنية

### Performance Testing / اختبارات الأداء

Performance reports are generated automatically and uploaded as artifacts. Review them to:
- Identify API bottlenecks / تحديد نقاط الاختناق في واجهة API
- Monitor response times / مراقبة أوقات الاستجابة
- Plan optimizations / تخطيط التحسينات

يتم إنشاء تقارير الأداء تلقائيًا وتحميلها كمخرجات. راجعها من أجل:
- تحديد نقاط الاختناق في واجهة API
- مراقبة أوقات الاستجابة
- تخطيط التحسينات

### Mobile App Deployment / نشر التطبيق المحمول

To deploy the app to app stores with phased rollout:

لنشر التطبيق على متاجر التطبيقات مع النشر التدريجي:

1. Go to the "Actions" tab in GitHub / انتقل إلى تبويب "Actions" في GitHub
2. Select "Mobile Deployment" / اختر "Mobile Deployment"
3. Click "Run workflow" / انقر على "Run workflow"
4. Enter:
   - App version (e.g., 1.0.0) / إصدار التطبيق (مثل: 1.0.0)
   - Release notes / ملاحظات الإصدار
   - Rollout percentage (default 10%) / نسبة النشر التدريجي (الافتراضي 10%)

## Setting Up Integration Tests / إعداد اختبارات التكامل

### For Flutter / لـ Flutter:
1. Create an `integration_test` directory in the project / قم بإنشاء مجلد `integration_test` في المشروع
2. Add integration test files / أضف ملفات اختبار التكامل
3. Tests will automatically run before deployment / سيتم تشغيل الاختبارات تلقائيًا قبل النشر

### For Backend / للواجهة الخلفية:
1. Create performance test scenarios in `locustfile.py` / قم بإنشاء سيناريوهات اختبار الأداء في `locustfile.py`
2. Add more test endpoints as needed / أضف نقاط نهاية اختبار إضافية حسب الحاجة

## Tips and Guidelines / نصائح وإرشادات

### For Frontend Tests / لاختبارات الواجهة الأمامية:
- Define tests in the `test/` folder within the Flutter project / تأكد من تعريف الاختبارات في مجلد `test/` داخل مشروع Flutter
- Consider using Test-Driven Development (TDD) / ضع في اعتبارك استخدام نهج التطوير المدفوع بالاختبار (TDD)
- For UI tests, use the `integration_test` folder / لاختبارات واجهة المستخدم، استخدم مجلد `integration_test`

### For Backend Tests / لاختبارات الواجهة الخلفية:
- Define tests in `tests.py` files within Django apps / تأكد من تعريف الاختبارات في ملفات `tests.py` داخل تطبيقات Django
- Use an independent test database / استخدم قاعدة بيانات اختبار مستقلة
- Monitor code coverage reports / راقب تقارير تغطية الكود

### For Deployment / للنشر:
- Always check deployment settings in `Fastfile` for both Android and iOS / تحقق دائمًا من إعدادات النشر في ملفات `Fastfile` لكل من Android و iOS
- Thoroughly test the app before actual deployment / تأكد من اختبار التطبيق جيدًا قبل النشر الفعلي
- Use phased rollouts to minimize risk / استخدم النشر التدريجي لتقليل المخاطر

## Troubleshooting / استكشاف الأخطاء وإصلاحها

If the CI/CD process fails, check:
1. Error logs in the Actions tab / سجلات الأخطاء في تبويب Actions
2. Validity of secrets and keys / صلاحية الأسرار والمفاتيح
3. File and path configuration in YAML files / تكوين الملفات والمسارات في ملفات YAML
4. Order of execution steps in pipelines / ترتيب تنفيذ الخطوات في خطوط الأنابيب
5. Downloaded artifacts for more detailed logs / قم بتنزيل المخرجات للحصول على سجلات أكثر تفصيلاً

## Security Best Practices / أفضل ممارسات الأمان

1. Never commit sensitive data directly to the repository / لا تقم أبدًا بإرسال البيانات الحساسة مباشرة إلى المستودع
2. Rotate secrets periodically / قم بتغيير الأسرار بشكل دوري
3. Use limited-scope access tokens / استخدم رموز وصول محدودة النطاق
4. Review workflow permissions in GitHub / راجع أذونات سير العمل في GitHub
5. Review security scan reports regularly / راجع تقارير فحص الأمان بانتظام

## Continuous Improvement / التحسين المستمر

Our CI/CD pipeline includes:
1. Security scanning for vulnerabilities / فحص الأمان للثغرات
2. Performance testing in the pipeline / اختبار الأداء في خط الأنابيب
3. Automated UI testing / اختبار واجهة المستخدم الآلي
4. Phased rollout deployment / نشر تدريجي للتطبيق

Future enhancements to consider:
1. A/B testing integration / دمج اختبارات A/B
2. Automated visual regression testing / اختبار تراجع بصري آلي
3. Expanded integration test coverage / توسيع تغطية اختبار التكامل 