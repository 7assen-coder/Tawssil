import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'selfie.dart';
import 'newaccount.dart';

class Password extends StatefulWidget {
  final String userType;
  final String email;
  final String phone;
  final String fullName;
  final String dob;

  const Password({
    super.key,
    required this.userType,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.dob,
  });

  @override
  State<Password> createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _showProgress = false;

  // إضافة متغيرات للتحقق من صحة كلمة المرور
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isFormValid = false;

  // التعبير النمطي المعدل لكلمة المرور (حرف كبير، حرف صغير، ورقم على الأقل)
  final RegExp _passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$'); // على الأقل 8 أحرف، حرف كبير، حرف صغير، ورقم

  @override
  void initState() {
    super.initState();
    // إضافة مستمعين للتحقق من صحة المدخلات
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);
  }

  // طريقة عرض رسائل الخطأ المخصصة
  InputDecoration _getInputDecoration({
    required String hint,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      errorText: errorText,
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      // تعديل المساحة لرسائل الخطأ
      errorMaxLines: 1,
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // عند الضغط على زر الرجوع، نعود إلى صفحة إنشاء حساب جديد وإعادة ضبط العملية
        _resetRegistrationProcess();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2F9C95),
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Stack(
            children: [
              // زر الرجوع المخصص في الزاوية اليسرى العليا
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _resetRegistrationProcess,
                ),
              ),
              // المحتوى الأصلي
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Image.asset(
                          'assets/images/Groupes@4x.png',
                          width: 110,
                          height: 110,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(40)),
                      ),
                      padding: const EdgeInsets.only(bottom: 16),
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 200,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'create_account'.tr(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Column(
                              children: [
                                Text(
                                  'start_journey'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),
                                Text(
                                  'closer_with_twsil'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
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
                                  bottom: 80,
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
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2F9C95),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.person_outline,
                                            color: Colors.white,
                                            size: 20,
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
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'personal_info'.tr(),
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12),
                                            ),
                                            Text(
                                              'success_completed'.tr(),
                                              style: const TextStyle(
                                                  color: Color(0xFF2F9C95),
                                                  fontSize: 12),
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
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2F9C95),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.shield_outlined,
                                            color: Colors.white,
                                            size: 20,
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
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'verification_code'.tr(),
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12),
                                            ),
                                            Text(
                                              'success_completed'.tr(),
                                              style: const TextStyle(
                                                  color: Color(0xFF2F9C95),
                                                  fontSize: 12),
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
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2F9C95),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.lock_outline,
                                            color: Colors.white,
                                            size: 20,
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
                                                'create_password'.tr(),
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12),
                                              ),
                                              const SizedBox(height: 15),
                                              AnimatedSwitcher(
                                                duration: const Duration(
                                                    milliseconds: 500),
                                                transitionBuilder:
                                                    (Widget child,
                                                        Animation<double>
                                                            animation) {
                                                  return FadeTransition(
                                                    opacity: animation,
                                                    child: SlideTransition(
                                                      position: Tween<Offset>(
                                                        begin: const Offset(
                                                            0.0, 0.2),
                                                        end: Offset.zero,
                                                      ).animate(CurvedAnimation(
                                                        parent: animation,
                                                        curve:
                                                            Curves.easeOutCubic,
                                                      )),
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                                child: !_showProgress
                                                    ? Column(
                                                        key: const ValueKey(
                                                            'password_inputs'),
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: _passwordError !=
                                                                          null
                                                                      ? Colors
                                                                          .red
                                                                      : Colors
                                                                          .grey
                                                                          .shade300),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: TextField(
                                                              controller:
                                                                  _passwordController,
                                                              obscureText: true,
                                                              textAlign: context
                                                                          .locale
                                                                          .languageCode ==
                                                                      'ar'
                                                                  ? TextAlign
                                                                      .right
                                                                  : TextAlign
                                                                      .left,
                                                              decoration:
                                                                  _getInputDecoration(
                                                                hint: 'password'
                                                                    .tr(),
                                                                errorText:
                                                                    _passwordError,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 15),
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: _confirmPasswordError !=
                                                                          null
                                                                      ? Colors
                                                                          .red
                                                                      : Colors
                                                                          .grey
                                                                          .shade300),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: TextField(
                                                              controller:
                                                                  _confirmPasswordController,
                                                              obscureText: true,
                                                              textAlign: context
                                                                          .locale
                                                                          .languageCode ==
                                                                      'ar'
                                                                  ? TextAlign
                                                                      .right
                                                                  : TextAlign
                                                                      .left,
                                                              decoration:
                                                                  _getInputDecoration(
                                                                hint:
                                                                    'confirm_password'
                                                                        .tr(),
                                                                errorText:
                                                                    _confirmPasswordError,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Column(
                                                        key: const ValueKey(
                                                            'progress_indicator'),
                                                        children: [
                                                          Center(
                                                            child: Stack(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              children: [
                                                                SizedBox(
                                                                  width: 80,
                                                                  height: 80,
                                                                  child:
                                                                      TweenAnimationBuilder<
                                                                          double>(
                                                                    tween: Tween<
                                                                            double>(
                                                                        begin:
                                                                            0.0,
                                                                        end:
                                                                            0.5),
                                                                    duration: const Duration(
                                                                        seconds:
                                                                            1),
                                                                    builder: (context,
                                                                        value,
                                                                        child) {
                                                                      return CircularProgressIndicator(
                                                                        value:
                                                                            value,
                                                                        strokeWidth:
                                                                            8,
                                                                        backgroundColor: Colors
                                                                            .grey
                                                                            .shade200,
                                                                        valueColor:
                                                                            const AlwaysStoppedAnimation<Color>(Color(0xFF2F9C95)),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                                const Text(
                                                                  '50%',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Color(
                                                                        0xFF2F9C95),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 15),
                                                          Center(
                                                            child: Text(
                                                              'completed_progress'
                                                                  .tr(),
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                              const SizedBox(height: 20),
                                              InkWell(
                                                onTap: _isFormValid
                                                    ? () {
                                                        setState(() {
                                                          _showProgress = true;
                                                        });

                                                        Future.delayed(
                                                            const Duration(
                                                                milliseconds:
                                                                    1500), () {
                                                          if (mounted) {
                                                            _navigateToSelfie();
                                                          }
                                                        });
                                                      }
                                                    : null,
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: _isFormValid
                                                        ? const Color(
                                                            0xFF2F9C95)
                                                        : Colors.grey[400],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      'continue_button'.tr(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: Image.asset(
                                        'assets/images/Rectangle@4x.png',
                                        height: 40,
                                      ),
                                    ),
                                    // إضافة مساحة إضافية لتغطية الفجوة في الأسفل
                                    SizedBox(
                                        height: MediaQuery.of(context)
                                                .padding
                                                .bottom +
                                            20),
                                  ],
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  void _navigateToSelfie() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Selfie(
          userType: widget.userType,
          email: widget.email,
          phone: widget.phone,
          fullName: widget.fullName,
          dob: widget.dob,
          password: _passwordController.text,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // التحقق من صحة كلمة المرور والتأكيد
  void _validatePassword() {
    final passwordValue = _passwordController.text;
    final confirmValue = _confirmPasswordController.text;

    // التحقق من كلمة المرور
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

    // التحقق من تأكيد كلمة المرور
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
        _checkFormValidity();
      });
    }
  }

  // التحقق من صلاحية النموذج بالكامل
  void _checkFormValidity() {
    final passwordValue = _passwordController.text;
    final confirmValue = _confirmPasswordController.text;

    bool isPasswordValid =
        passwordValue.isNotEmpty && _passwordRegex.hasMatch(passwordValue);
    bool isConfirmValid =
        confirmValue.isNotEmpty && confirmValue == passwordValue;

    setState(() {
      _isFormValid = isPasswordValid && isConfirmValid;
    });
  }

  // دالة للعودة إلى صفحة إنشاء حساب جديد
  void _resetRegistrationProcess() {
    // التنقل إلى صفحة إنشاء حساب جديد مع استبدال كامل المكدس (stack)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => NewAccount(
                userType: widget.userType,
                email: widget.email,
                phone: widget.phone,
                fullName: widget.fullName,
                dob: widget.dob,
              )),
      (route) => false, // إزالة جميع الصفحات السابقة من المكدس
    );
  }
}
