import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';
import 'newaccount.dart';
import 'forget_password.dart';
import 'homeapp.dart';
import 'driver_homeapp.dart';
import 'services/auth_service.dart';
import 'language_selection_dialog.dart';
import 'package:flutter/foundation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool showLogin = false;
  bool showLanguageDialog = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _obscureText = true;
  bool _isLoading = false; // متغير لإظهار حالة التحميل

  // إضافة خدمة المصادقة
  final AuthService _authService = AuthService();

  // إضافة متغيرات للتحكم في المدخلات
  final TextEditingController _emailPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _emailPhoneError;
  String? _passwordError;
  bool _isFormValid = false;

  // Regular expressions للتحقق
  final RegExp _phoneRegex =
      RegExp(r'^[2-4]\d{7}$'); // يبدأ بـ 2,3,4 ويتكون من 8 أرقام
  final RegExp _emailRegex =
      RegExp(r'^[^@]+@[^@]+\.[^@]+$'); // تحقق بسيط من البريد الإلكتروني
  final RegExp _passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$'); // على الأقل 8 أحرف، حرف كبير، حرف صغير، رقم

  // Add new variable for user type selection
  String _selectedUserType = 'Client'; // القيمة الافتراضية: عميل
  String _description = ''; // متغير للوصف المتغير حسب نوع الحساب

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // إضافة مستمعين للتحقق من صحة المدخلات على الفور
    _emailPhoneController.addListener(_validateInputsOnChange);
    _passwordController.addListener(_validateInputsOnChange);

    // تحديد النص الافتراضي حسب نوع الحساب
    _description = 'description'.tr();

    // عرض حوار اختيار اللغة بعد 6 ثوان
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          showLanguageDialog = true;
        });
        _showLanguageSelectionDialog();
      }
    });
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // التحقق من صحة المدخلات عند تغييرها
  void _validateInputsOnChange() {
    // التحقق من البريد الإلكتروني أو رقم الهاتف
    final emailPhoneValue = _emailPhoneController.text.trim();
    if (emailPhoneValue.isEmpty) {
      setState(() {
        _emailPhoneError = 'input_required'.tr();
        _isFormValid = false;
      });
    } else if (_phoneRegex.hasMatch(emailPhoneValue)) {
      // صالح - رقم هاتف
      setState(() {
        _emailPhoneError = null;
        _checkFormValidity();
      });
    } else if (_emailRegex.hasMatch(emailPhoneValue)) {
      // صالح - بريد إلكتروني
      setState(() {
        _emailPhoneError = null;
        _checkFormValidity();
      });
    } else {
      setState(() {
        _emailPhoneError = 'invalid_email_phone'.tr();
        _isFormValid = false;
      });
    }

    // التحقق من كلمة المرور
    final passwordValue = _passwordController.text;
    if (passwordValue.isEmpty) {
      setState(() {
        _passwordError = 'input_required'.tr();
        _isFormValid = false;
      });
    } else if (!_passwordRegex.hasMatch(passwordValue)) {
      setState(() {
        _passwordError = 'password_requirement'.tr();
        _isFormValid = false;
      });
    } else {
      setState(() {
        _passwordError = null;
        _checkFormValidity();
      });
    }
  }

  // التحقق من صلاحية النموذج بأكمله
  void _checkFormValidity() {
    final emailPhoneValue = _emailPhoneController.text.trim();
    final passwordValue = _passwordController.text;

    bool isEmailPhoneValid = emailPhoneValue.isNotEmpty &&
        (_phoneRegex.hasMatch(emailPhoneValue) ||
            _emailRegex.hasMatch(emailPhoneValue));

    bool isPasswordValid =
        passwordValue.isNotEmpty && _passwordRegex.hasMatch(passwordValue);

    setState(() {
      _isFormValid = isEmailPhoneValid && isPasswordValid;
    });
  }

  // دالة للحصول على رسالة خطأ مناسبة بناءً على نوع الخطأ
  String _getErrorMessage(Map<String, dynamic> result) {
    // التحقق مما إذا كانت الرسالة هي مفتاح ترجمة مباشر
    String message = result['message'] ?? '';

    // قائمة بمفاتيح الترجمة المعروفة
    List<String> knownTranslationKeys = [
      'invalid_credentials',
      'multiple_accounts',
      'connection_error',
      'account_not_found',
      'wrong_password',
      'account_inactive',
      'server_error',
      'try_again',
      'unknown_error',
      'login_error',
      'client_not_found',
      'driver_not_found',
      'wrong_account_type',
      'invalid_account_type'
    ];

    // إذا كانت الرسالة مفتاح ترجمة معروف، نقوم بإرجاعها للترجمة
    if (knownTranslationKeys.contains(message)) {
      return message;
    }

    // للتوافق مع الاستجابات القديمة
    final error = result['error'] ?? '';

    if (error.contains('بيانات') || error.contains('تسجيل الدخول')) {
      return 'invalid_credentials';
    } else if (error.contains('تعذر') || error.contains('الدعم')) {
      return 'multiple_accounts';
    } else if (error.contains('الاتصال') || error.contains('الخادم')) {
      return 'connection_error';
    } else if (result['status'] == 'error') {
      return 'login_error';
    }

    // الرسالة الافتراضية إذا لم نستطع تحديد نوع الخطأ
    return 'unknown_error';
  }

  // عرض مربع حوار الخطأ
  void _showErrorDialog(String message) {
    // لإصلاح مشكلة ظهور الرموز غير المفهومة
    String errorMessage = '';

    // محاولة استخدام الترجمة أولاً
    if (message.startsWith('invalid_') ||
        message.contains('error') ||
        message.contains('login_')) {
      errorMessage = message.tr();
    } else {
      errorMessage = message;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              'error_title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          errorMessage,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'ok'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 24, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isRTL = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF2F9C95),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: showLogin ? _buildLoginPage(isRTL) : _buildAnimation(),
        ),
      ),
    );
  }

  Widget _buildAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // شعار التطبيق مع تأثير ظهور تدريجي
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 3),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: value,
                  child: Image.asset(
                    'assets/images/Tawssil@logo.png',
                    width: 200,
                    height: 200,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          // رسوم متحركة للتحميل
          SizedBox(
            width: 300,
            height: 300,
            child: Lottie.network(
              'https://lottie.host/704d7228-b25f-4aa5-960d-bd8b66a6257c/vaWOhNBobl.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              frameRate:
                  const FrameRate(120), // معدل إطارات أعلى للحركة الأكثر سلاسة
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPage(bool isRTL) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF2F9C95),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const SizedBox(height: 20),
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/Tawssil@logo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(45.0),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        Text(
                          'login'.tr(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // اختيار نوع الحساب
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'choose_account_type'.tr(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 15),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // زر العميل
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          _setUserType('Client');
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15),
                                          decoration: BoxDecoration(
                                            color: _selectedUserType == 'Client'
                                                ? const Color(0xFF2F9C95)
                                                : Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: _selectedUserType ==
                                                    'Client'
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFF2F9C95)
                                                          .withOpacity(0.4),
                                                      spreadRadius: 1,
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.person,
                                                color: _selectedUserType ==
                                                        'Client'
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'login_as_client'.tr(),
                                                style: TextStyle(
                                                  color: _selectedUserType ==
                                                          'Client'
                                                      ? Colors.white
                                                      : Colors.grey[700],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    // زر السائق
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          _setUserType('Livreur');
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15),
                                          decoration: BoxDecoration(
                                            color:
                                                _selectedUserType == 'Livreur'
                                                    ? const Color(0xFF2F9C95)
                                                    : Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: _selectedUserType ==
                                                    'Livreur'
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFF2F9C95)
                                                          .withOpacity(0.4),
                                                      spreadRadius: 1,
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.delivery_dining,
                                                color: _selectedUserType ==
                                                        'Livreur'
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'login_as_driver'.tr(),
                                                style: TextStyle(
                                                  color: _selectedUserType ==
                                                          'Livreur'
                                                      ? Colors.white
                                                      : Colors.grey[700],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        Align(
                          alignment: isRTL
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isRTL
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                'welcome'.tr(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _description,
                                  key: ValueKey<String>(_description),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: _emailPhoneController,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          onChanged: (value) {
                            // التحقق المباشر عند الكتابة
                            _validateInputsOnChange();
                          },
                          decoration: InputDecoration(
                            hintText: 'phone_email'.tr(),
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 1),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            errorText: _emailPhoneError,
                            prefixIcon: const Icon(Icons.person,
                                color: Color(0xFF2F9C95)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          obscureText: _obscureText,
                          onChanged: (value) {
                            // التحقق المباشر عند الكتابة
                            _validateInputsOnChange();
                          },
                          decoration: InputDecoration(
                            hintText: 'password'.tr(),
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 1),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            errorText: _passwordError,
                            prefixIcon: const Icon(Icons.lock,
                                color: Color(0xFF2F9C95)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // تحسين مظهر زر "نسيت كلمة المرور"
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2F9C95),
                              width: 1,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () {
                              // الانتقال مباشرة إلى صفحة نسيان كلمة المرور مع تمرير نوع المستخدم الحالي
                              _navigateToForgetPassword(
                                  context, _selectedUserType);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2F9C95),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'forgot_password'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isFormValid
                                ? () async {
                                    // عرض مؤشر التحميل
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    try {
                                      // استدعاء API للتحقق من بيانات المستخدم مع تحديد نوع المستخدم
                                      final result = await _authService.login(
                                        _emailPhoneController.text.trim(),
                                        _passwordController.text,
                                        userType: _selectedUserType,
                                      );

                                      // تأكد من أن الصفحة لا تزال موجودة
                                      if (!mounted) return;

                                      // إخفاء مؤشر التحميل
                                      setState(() {
                                        _isLoading = false;
                                      });

                                      if (result['status'] == 'inactive' &&
                                          _selectedUserType == 'Client') {
                                        await showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            elevation: 0,
                                            backgroundColor: Colors.transparent,
                                            child: SingleChildScrollView(
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.95,
                                                  minWidth: 200,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        spreadRadius: 1,
                                                        blurRadius: 10,
                                                        offset:
                                                            const Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(15),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red
                                                              .withOpacity(0.1),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.block,
                                                          color: Colors.red,
                                                          size: 40,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 20),
                                                      Text(
                                                        'account_restricted_title'
                                                            .tr(),
                                                        style: const TextStyle(
                                                          fontSize: 24,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.red,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        softWrap: true,
                                                      ),
                                                      const SizedBox(
                                                          height: 15),
                                                      Container(
                                                        height: 1,
                                                        color: Colors.grey
                                                            .withOpacity(0.2),
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            vertical: 15),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(15),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.grey
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .info_outline,
                                                              color: Colors.red,
                                                              size: 24,
                                                            ),
                                                            const SizedBox(
                                                                height: 10),
                                                            Text(
                                                              'client_account_restricted_message'
                                                                  .tr(),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .black87,
                                                                height: 1.5,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              softWrap: true,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 25),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context,
                                                                    rootNavigator:
                                                                        true)
                                                                .pop();
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                            foregroundColor:
                                                                Colors.white,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        15),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            elevation: 0,
                                                          ),
                                                          child: Text(
                                                            'ok'.tr(),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                        return;
                                      } else if (result['success']) {
                                        // تم تسجيل الدخول بنجاح
                                        final userData = result['user'];
                                        if (kDebugMode) {
                                          debugPrint('USER DATA: $userData');
                                        }

                                        // تحويل userData إلى كائن User
                                        final user = User.fromJson(userData,
                                            result['tokens']?['access'] ?? '');

                                        final userType = user.userType;
                                        final statut =
                                            userData['statut_verification'];
                                        final raisonRefus =
                                            userData['raison_refus'];

                                        if (kDebugMode) {
                                          debugPrint(
                                              'userType: $userType, statut: $statut');
                                        }

                                        // التحقق من حالة السائق أولاً
                                        if (userType == 'Chauffeur' ||
                                            userType == 'Livreur') {
                                          final statutStr = statut
                                                  ?.toString()
                                                  .toLowerCase() ??
                                              '';
                                          if (statutStr.contains('refus')) {
                                            if (kDebugMode) {
                                              debugPrint(
                                                  'RAISON REFUS: $raisonRefus');
                                            }
                                            await showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) => Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                elevation: 0,
                                                backgroundColor:
                                                    Colors.transparent,
                                                child: SingleChildScrollView(
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.95,
                                                      minWidth: 200,
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.1),
                                                            spreadRadius: 1,
                                                            blurRadius: 10,
                                                            offset:
                                                                const Offset(
                                                                    0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          // أيقونة الحظر
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(15),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.red
                                                                  .withOpacity(
                                                                      0.1),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: const Icon(
                                                              Icons.block,
                                                              color: Colors.red,
                                                              size: 40,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 20),
                                                          // العنوان
                                                          Text(
                                                            'account_restricted_title'
                                                                .tr(),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 24,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors.red,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                            softWrap: true,
                                                          ),
                                                          const SizedBox(
                                                              height: 15),
                                                          // خط فاصل
                                                          Container(
                                                            height: 1,
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.2),
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        15),
                                                          ),
                                                          // رسالة الرفض
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(15),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .info_outline,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 24,
                                                                ),
                                                                const SizedBox(
                                                                    height: 10),
                                                                Text(
                                                                  '${'account_restricted_message'.tr()} ${raisonRefus ?? '-'}',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                        .black87,
                                                                    height: 1.5,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  softWrap:
                                                                      true,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 25),
                                                          // زر الموافقة
                                                          SizedBox(
                                                            width:
                                                                double.infinity,
                                                            child:
                                                                ElevatedButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context,
                                                                        rootNavigator:
                                                                            true)
                                                                    .pop();
                                                              },
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            15),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                ),
                                                                elevation: 0,
                                                              ),
                                                              child: Text(
                                                                'ok'.tr(),
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                            return; // منع الانتقال إلى الصفحة التالية
                                          } else if (statutStr
                                              .contains('attent')) {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18)),
                                                backgroundColor: Colors.white,
                                                title: Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.info_outline,
                                                        color:
                                                            Color(0xFF2F9C95),
                                                        size: 28),
                                                    const SizedBox(width: 10),
                                                    Flexible(
                                                      child: Text(
                                                        'account_review_title'
                                                            .tr(),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20,
                                                          color:
                                                              Color(0xFF2F9C95),
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                content: SingleChildScrollView(
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.8,
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        SizedBox(
                                                          height: 80,
                                                          child: Lottie.asset(
                                                            'assets/animations/hourglass.json',
                                                            repeat: true,
                                                            animate: true,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 18),
                                                        Text(
                                                          'account_review_message'
                                                              .tr(),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 16,
                                                                  color: Colors
                                                                      .black87),
                                                          textAlign:
                                                              TextAlign.center,
                                                          softWrap: true,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.white,
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF2F9C95),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 24,
                                                          vertical: 10),
                                                    ),
                                                    child: Text(
                                                      'ok'.tr(),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            return;
                                          }
                                        }

                                        // عرض رسالة نجاح
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('login_success'.tr()),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );

                                        // التحقق من نوع المستخدم وتوجيهه للصفحة المناسبة
                                        if (_selectedUserType == 'Client') {
                                          // توجيه العميل إلى صفحة العملاء
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => HomeApp(
                                                userIdentifier:
                                                    _getUserIdentifier(user),
                                                userData: user,
                                              ),
                                            ),
                                          );
                                        } else if (statut != 'Refusé' &&
                                            statut != 'En attente') {
                                          // توجيه السائق إلى صفحة السائقين فقط إذا لم يكن مرفوضاً أو في انتظار
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DriverHomeApp(
                                                userIdentifier:
                                                    _getUserIdentifier(user),
                                                userData: user,
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        // استخدام دالة الحصول على رسالة خطأ مناسبة
                                        _showErrorDialog(
                                            _getErrorMessage(result));
                                      }
                                    } catch (e) {
                                      // إخفاء مؤشر التحميل في حالة حدوث خطأ
                                      setState(() {
                                        _isLoading = false;
                                      });

                                      // عرض رسالة خطأ
                                      _showErrorDialog('server_error'.tr());
                                    }
                                  }
                                : null, // تعطيل الزر إذا كانت المدخلات غير صالحة
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'login_button'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // تحسين مظهر زر "حساب جديد"
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2F9C95),
                              width: 1,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () {
                              // تعديل السلوك ليكون مشابهاً لزر نسيت كلمة المرور
                              // استخدام نوع الحساب المحدد حالياً وإرساله مباشرة إلى صفحة إنشاء حساب جديد
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      NewAccount(userType: _selectedUserType),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2F9C95),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'new_account'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Image.asset(
                            'assets/images/Rectangle@4x.png',
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تحديث نوع الحساب
  void _setUserType(String type) {
    setState(() {
      _selectedUserType = type;

      // تحديث النص الترويجي/الوصفي حسب نوع الحساب
      if (type == 'Client') {
        _description = 'description'.tr();
      } else if (type == 'Livreur') {
        _description = 'driver_description'.tr();
      }
    });
  }

  // دالة لنسيان كلمة المرور
  void _navigateToForgetPassword(BuildContext context, String userType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForgetPassword(
          userType: userType,
        ),
      ),
    );
  }

  // إضافة دالة لعرض حوار اختيار اللغة
  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LanguageSelectionDialog(
        onLanguageSelected: () {
          // الانتقال إلى شاشة تسجيل الدخول بعد اختيار اللغة
          setState(() {
            showLogin = true;
          });
          _controller.forward();
        },
      ),
    );
  }

  // دالة مساعدة للحصول على معرف المستخدم
  String _getUserIdentifier(User user) {
    return user.email.isNotEmpty ? user.email : user.phone;
  }
}
