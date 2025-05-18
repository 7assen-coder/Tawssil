# تطبيق توصيل (Tawssil)

## إعداد خدمة إرسال البريد الإلكتروني للتحقق من الهوية

التطبيق يستخدم خدمة EmailJS لإرسال رموز التحقق عبر البريد الإلكتروني. اتبع الخطوات التالية لإعداد الخدمة:

### خطوات إعداد EmailJS

1. قم بإنشاء حساب مجاني على [EmailJS](https://www.emailjs.com)
2. أنشئ خدمة بريد إلكتروني (Email Service) جديدة وربطها بحساب البريد الإلكتروني الخاص بك (Gmail، Outlook، إلخ)
3. أنشئ قالب بريد إلكتروني (Email Template) جديد يحتوي على الحقول التالية:
   - `{{user_name}}` - اسم المستخدم
   - `{{user_email}}` - البريد الإلكتروني للمستخدم
   - `{{otp_code}}` - رمز التحقق
   - `{{app_name}}` - اسم التطبيق
   - `{{user_type}}` - نوع المستخدم
4. قم بتعديل قالب البريد الإلكتروني ليناسب تصميم تطبيقك

### تحديث معرفات EmailJS في التطبيق

بعد إعداد الخدمة، قم بتحديث الرموز التعريفية في ملف `lib/services/auth_service.dart`:

```dart
Future<bool> _sendRealEmailWithOTP({
  required String email,
  required String fullName,
  required String otpCode,
  required String userType,
}) async {
  try {
    // استخدام خدمة EmailJS
    final Uri url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    final Map<String, dynamic> data = {
      'service_id': 'YOUR_SERVICE_ID',  // استبدل بمعرف الخدمة الخاص بك
      'template_id': 'YOUR_TEMPLATE_ID',  // استبدل بمعرف القالب الخاص بك
      'user_id': 'YOUR_USER_ID',  // استبدل بمعرف المستخدم الخاص بك
      'template_params': {
        'user_email': email,
        'user_name': fullName,
        'otp_code': otpCode,
        'app_name': 'Tawssil',
        'user_type': userType,
      },
    };
    
    // ... باقي الكود
  }
}
```

### نموذج قالب بريد إلكتروني

يمكنك استخدام النموذج التالي كقالب بريد إلكتروني:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      color: #333;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
      border: 1px solid #ddd;
      border-radius: 5px;
    }
    .header {
      background-color: #2F9C95;
      color: white;
      padding: 10px;
      text-align: center;
      border-radius: 5px 5px 0 0;
    }
    .content {
      padding: 20px;
    }
    .otp-code {
      font-size: 32px;
      text-align: center;
      letter-spacing: 5px;
      margin: 20px 0;
      color: #2F9C95;
    }
    .footer {
      text-align: center;
      margin-top: 20px;
      font-size: 12px;
      color: #666;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2>{{app_name}} - رمز التحقق</h2>
    </div>
    <div class="content">
      <p>مرحبًا {{user_name}}،</p>
      <p>لقد تلقينا طلبًا للتسجيل في تطبيق {{app_name}} كـ {{user_type}}.</p>
      <p>استخدم رمز التحقق التالي لإكمال عملية التسجيل:</p>
      
      <div class="otp-code">{{otp_code}}</div>
      
      <p>هذا الرمز صالح لمدة 10 دقائق فقط.</p>
      <p>إذا لم تقم بطلب هذا الرمز، يرجى تجاهل هذا البريد الإلكتروني.</p>
    </div>
    <div class="footer">
      <p>هذا بريد إلكتروني تلقائي، يرجى عدم الرد عليه.</p>
      <p>&copy; {{app_name}} - جميع الحقوق محفوظة</p>
    </div>
  </div>
</body>
</html>
```

### ملاحظات هامة

1. يجب أن يكون لديك حساب EmailJS نشط لاستخدام هذه الخدمة
2. تأكد من تحديث معرفات الخدمة والقالب والمستخدم بالقيم الخاصة بك
3. الحساب المجاني في EmailJS يسمح بإرسال 200 بريد إلكتروني شهريًا
4. للاستخدام في بيئة الإنتاج، يُفضل استخدام خدمة بريد إلكتروني من خلال الخادم الخلفي
