import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'homepage.dart';
import 'services/otp_service.dart';

class NewPasswordPage extends StatefulWidget {
  final String identifier;
  final String otpCode;
  final String userType;
  final int userId;

  const NewPasswordPage({
    super.key,
    required this.identifier,
    required this.otpCode,
    required this.userType,
    required this.userId,
  });

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isFormValid = false;
  bool _isLoading = false;
  String? _passwordError;
  String? _confirmPasswordError;

  // تعبير نمطي للتحقق من صحة كلمة المرور - يجب أن تحتوي على 8 أحرف على الأقل بما في ذلك حرف كبير وحرف صغير ورقم
  final RegExp _passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validateForm);
    _confirmPasswordController.removeListener(_validateForm);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final passwordValue = _passwordController.text;
    final confirmValue = _confirmPasswordController.text;

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
      });
    }

    if (confirmValue.isEmpty) {
      setState(() {
        _confirmPasswordError = 'input_required'.tr();
        _isFormValid = false;
      });
    } else if (confirmValue != passwordValue) {
      setState(() {
        _confirmPasswordError = 'passwords_not_match'.tr();
        _isFormValid = false;
      });
    } else {
      setState(() {
        _confirmPasswordError = null;
      });
    }

    setState(() {
      _isFormValid = _passwordError == null &&
          _confirmPasswordError == null &&
          passwordValue.isNotEmpty &&
          confirmValue.isNotEmpty;
    });
  }

  // دالة لعرض رسالة خطأ
  void _showErrorDialog(String message) {
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
          message,
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
      ),
    );
  }

  // دالة لعرض رسالة نجاح
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF2F9C95),
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              'success_title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // بعد إغلاق الحوار، انتقل للصفحة الرئيسية
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2F9C95),
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
      ),
    );
  }

  // دالة لتغيير كلمة المرور
  Future<void> _resetPassword() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // كتابة سجلات تشخيصية مفصلة
      debugPrint('=== RESET PASSWORD ATTEMPT ===');
      debugPrint('Original identifier: ${widget.identifier}');
      debugPrint('Original OTP code: ${widget.otpCode}');
      debugPrint('User type: ${widget.userType}');
      debugPrint('Password length: ${_passwordController.text.length}');
      debugPrint('User ID: ${widget.userId}');

      // تنسيق المعرف - للتشخيص
      String identifier = widget.identifier;
      String code = widget.otpCode;

      // التأكد من قيم المعرف ورمز OTP
      if (identifier.isEmpty || code.isEmpty) {
        if (!mounted) return;
        _showErrorDialog('input_required'.tr());
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // استخدام خدمة OTP لإعادة تعيين كلمة المرور
      final result = await OTPService.resetPassword(
        identifier: identifier,
        otpCode: code,
        newPassword: _passwordController.text,
        userType: widget.userType,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        _showSuccessDialog('password_reset_success'.tr());
      } else {
        String errorMessage = result['message'] ?? 'Failed to reset password';
        debugPrint('Error message from server: $errorMessage');
        _showErrorDialog(errorMessage.tr());
      }
    } catch (e) {
      debugPrint('Error in _resetPassword: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showErrorDialog('system_error'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام MediaQuery للحصول على أبعاد الشاشة
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;

    // استخدام PopScope بدلاً من WillPopScope لمنع الرجوع غير المقصود
    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (bool didPop, Future<dynamic> Function(bool)? popResult) async {
        // لا نقوم بأي إجراء عند الضغط على زر الرجوع الخاص بنظام Android
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2F9C95),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16, right: 16, left: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // زر اختيار اللغة تمت إزالته من هنا
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Image.asset(
                      'assets/images/Groupes@4x.png',
                      width: screenHeight * 0.12,
                      height: screenHeight * 0.12,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height -
                      (screenHeight * 0.12 + 80),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Password_reset'.tr(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Stack(
                                children: [
                                  Positioned(
                                    left: context.locale.languageCode == 'ar'
                                        ? null
                                        : 19,
                                    right: context.locale.languageCode == 'ar'
                                        ? 19
                                        : null,
                                    top: 20,
                                    bottom: 140,
                                    child: Container(
                                      width: 2,
                                      color: const Color(0xFF2F9C95),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor:
                                                  Color(0xFF2F9C95),
                                              child: Text(
                                                '1',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'step1'.tr(),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                'Processing_method'.tr(),
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'success_completed'.tr(),
                                                style: const TextStyle(
                                                  color: Color(0xFF2F9C95),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 40),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor:
                                                  Color(0xFF2F9C95),
                                              child: Text(
                                                '2',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'step2'.tr(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'verify_code'.tr(),
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'success_completed'.tr(),
                                                style: const TextStyle(
                                                  color: Color(0xFF2F9C95),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 40),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor:
                                                  Color(0xFF2F9C95),
                                              child: Text(
                                                '3',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'step3'.tr(),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  'create_Npassword'.tr(),
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                ),
                                                const SizedBox(height: 15),
                                                Column(
                                                  key: const ValueKey(
                                                      'password_inputs'),
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey.shade300),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: TextField(
                                                        controller:
                                                            _passwordController,
                                                        obscureText:
                                                            _obscurePassword,
                                                        textAlign: context
                                                                    .locale
                                                                    .languageCode ==
                                                                'ar'
                                                            ? TextAlign.right
                                                            : TextAlign.left,
                                                        decoration:
                                                            InputDecoration(
                                                          hintText:
                                                              'password'.tr(),
                                                          hintStyle:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .grey),
                                                          border:
                                                              InputBorder.none,
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 12,
                                                            vertical: 16,
                                                          ),
                                                          suffixIcon:
                                                              IconButton(
                                                            icon: Icon(_obscurePassword
                                                                ? Icons
                                                                    .visibility_off
                                                                : Icons
                                                                    .visibility),
                                                            onPressed: () {
                                                              setState(() {
                                                                _obscurePassword =
                                                                    !_obscurePassword;
                                                              });
                                                            },
                                                          ),
                                                          errorText:
                                                              _passwordError,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 15),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey.shade300),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: TextField(
                                                        controller:
                                                            _confirmPasswordController,
                                                        obscureText:
                                                            _obscureConfirmPassword,
                                                        textAlign: context
                                                                    .locale
                                                                    .languageCode ==
                                                                'ar'
                                                            ? TextAlign.right
                                                            : TextAlign.left,
                                                        decoration:
                                                            InputDecoration(
                                                          hintText:
                                                              'confirm_password'
                                                                  .tr(),
                                                          hintStyle:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .grey),
                                                          border:
                                                              InputBorder.none,
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 16),
                                                          suffixIcon:
                                                              IconButton(
                                                            icon: Icon(_obscureConfirmPassword
                                                                ? Icons
                                                                    .visibility_off
                                                                : Icons
                                                                    .visibility),
                                                            onPressed: () {
                                                              setState(() {
                                                                _obscureConfirmPassword =
                                                                    !_obscureConfirmPassword;
                                                              });
                                                            },
                                                          ),
                                                          errorText:
                                                              _confirmPasswordError,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 20),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 30),
                                                  child: ElevatedButton(
                                                    onPressed: _isFormValid &&
                                                            !_isLoading
                                                        ? _resetPassword
                                                        : null,
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      minimumSize: const Size(
                                                          double.infinity, 50),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF2F9C95),
                                                      disabledBackgroundColor:
                                                          Colors.grey,
                                                    ),
                                                    child: _isLoading
                                                        ? const SizedBox(
                                                            width: 24,
                                                            height: 24,
                                                            child:
                                                                CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                        : Text(
                                                            'submit'.tr(),
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
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Image.asset(
                            'assets/images/Rectangle@4x.png',
                            height: screenHeight * 0.04,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
