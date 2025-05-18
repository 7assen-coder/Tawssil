import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'password.dart';
import 'services/otp_service.dart';

class CodeVerification extends StatefulWidget {
  final String email;
  final String phone;
  final String userType;
  final String fullName;
  final String dob;
  final bool isUsingEmail;
  final String otpCode;

  const CodeVerification({
    super.key,
    required this.email,
    required this.phone,
    required this.userType,
    required this.fullName,
    required this.dob,
    required this.isUsingEmail,
    required this.otpCode,
  });

  @override
  State<CodeVerification> createState() => _CodeVerificationState();
}

class _CodeVerificationState extends State<CodeVerification> {
  final List<TextEditingController> controllers =
      List.generate(4, (index) => TextEditingController());
  late Timer _timer;
  int _remainingSeconds = 179; // 2m 59s
  int _resendCount = 0;
  late bool _isUsingEmail;
  bool _canResend = false;
  bool _isVerifying = false;
  String? _autoFilledOtp; // إضافة متغير لتخزين رمز OTP المستلم تلقائيًا

  @override
  void initState() {
    super.initState();
    // تعيين وسيلة الإرسال المستخدمة من وسيط الكلاس
    _isUsingEmail = widget.isUsingEmail;

    // نحتفظ بالرمز المحلي للتحقق في الخلفية فقط، بدون ملء الحقول تلقائيًا
    if (widget.otpCode.isNotEmpty && widget.otpCode.length == 4) {
      _autoFilledOtp = widget.otpCode;
    }

    // بدء العد التنازلي
    startTimer();
  }

  void startTimer() {
    _canResend = false;
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (timer) {
      if (_remainingSeconds < 1) {
        setState(() {
          timer.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void resetTimer() {
    _timer.cancel();
    setState(() {
      _resendCount++;
      // زيادة الوقت بمقدار 3 دقائق × عدد مرات إعادة الإرسال
      _remainingSeconds = 180 * (_resendCount + 1) - 1;
      _canResend = false;
    });
    startTimer();
  }

  // دالة لتنسيق الوقت بصيغة دقائق وثواني
  String get formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return "$minutes${'minutes'.tr()} $seconds${'seconds'.tr()}";
  }

  // دالة لإظهار البريد الإلكتروني أو رقم الهاتف مع إخفاء جزء منه
  String get maskedContact {
    if (_isUsingEmail) {
      // إخفاء جزء من البريد الإلكتروني (مثال: a***@example.com)
      String email = widget.email;
      int atIndex = email.indexOf('@');
      if (atIndex > 1) {
        return "${email.substring(0, 1)}${'*' * (atIndex - 1)}${email.substring(atIndex)}";
      }
      return email;
    } else {
      // إخفاء جزء من رقم الهاتف (مثال: 052****)
      String phone = widget.phone;
      if (phone.length > 3) {
        return "${phone.substring(0, 3)}${'*' * (phone.length - 3)}";
      }
      return phone;
    }
  }

  // إضافة دالة لعرض SnackBar بشكل آمن
  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  // التحقق من الرمز المُدخل
  void _verifyOtp() {
    if (!mounted) return;

    // تجميع الرمز المدخل
    String enteredOtp = controllers.map((controller) => controller.text).join();

    if (enteredOtp.length != 4) {
      _showSnackBar('invalid_code'.tr(), Colors.red);
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    // إذا كان هناك رمز مخزن تلقائيًا (من التسجيل المحلي) نسمح بمقارنته أيضًا
    // لكن نحاول دائمًا التحقق من الخادم أولًا
    _verifyWithServer(enteredOtp);
  }

  // التحقق من الرمز مع الخادم
  void _verifyWithServer(String otp) async {
    try {
      // محاولة التحقق من خلال الخادم أولًا
      Map<String, dynamic> result = await OTPService.verifyOTP(
        email: _isUsingEmail ? widget.email : null,
        phoneNumber: !_isUsingEmail ? widget.phone : null,
        otpCode: otp,
        userType: widget.userType,
      );

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      // إذا كان التحقق من الخادم ناجحًا
      if (result['success']) {
        _navigateToPassword();
        return;
      }

      // إذا فشل التحقق من الخادم وكنا في وضع الاختبار المحلي
      // وكان الرمز المدخل يطابق الرمز المحلي، نسمح بالمتابعة
      if (_autoFilledOtp != null && _autoFilledOtp == otp) {
        _navigateToPassword();
        return;
      }

      // إذا وصلنا إلى هنا، فالرمز غير صحيح
      _showSnackBar(result['message'].tr(), Colors.red);
    } catch (e) {
      debugPrint('Error verifying OTP with server: $e');

      // في حالة حدوث خطأ في الاتصال بالخادم
      // نتحقق من الرمز المحلي فقط إذا كنا في وضع الاختبار
      if (_autoFilledOtp != null && _autoFilledOtp == otp) {
        if (!mounted) return;
        setState(() {
          _isVerifying = false;
        });
        _navigateToPassword();
        return;
      }

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      _showSnackBar('error_verifying_code'.tr(), Colors.red);
    }
  }

  // إضافة دالة للتنقل بشكل آمن
  void _navigateToPassword() {
    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Password(
            userType: widget.userType,
            email: widget.email,
            phone: widget.phone,
            fullName: widget.fullName,
            dob: widget.dob),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F9C95),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
                            left:
                                context.locale.languageCode == 'ar' ? null : 19,
                            right:
                                context.locale.languageCode == 'ar' ? 19 : null,
                            top: 20,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: const Color(0xFF2F9C95),
                            ),
                          ),
                          Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                            color: Colors.grey, fontSize: 12),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // إضافة معلومات الوسيلة المستخدمة للتحقق
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey[200]!),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  _isUsingEmail
                                                      ? Icons.email_outlined
                                                      : Icons.phone_android,
                                                  color:
                                                      const Color(0xFF2F9C95),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _isUsingEmail
                                                      ? 'verification_sent_email'
                                                          .tr()
                                                      : 'verification_sent_phone'
                                                          .tr(),
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              maskedContact,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'enter_code'.tr(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${'expiration'.tr()} $formattedTime',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),

                                      // نص توضيحي حول مصدر الرمز
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _isUsingEmail
                                              ? 'check_email_for_code'.tr()
                                              : 'check_phone_for_code'.tr(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(
                                          4,
                                          (index) => SizedBox(
                                            width: 45,
                                            height: 48,
                                            child: Stack(
                                              children: [
                                                TextField(
                                                  controller:
                                                      controllers[index],
                                                  textAlign: TextAlign.center,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  maxLength: 1,
                                                  enabled: !_isVerifying,
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  decoration: InputDecoration(
                                                    counterText: "",
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .grey[300]!),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      borderSide:
                                                          const BorderSide(
                                                              color: Color(
                                                                  0xFF2F9C95),
                                                              width: 2),
                                                    ),
                                                  ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                    LengthLimitingTextInputFormatter(
                                                        1),
                                                  ],
                                                  onChanged: (value) {
                                                    if (value.isNotEmpty) {
                                                      if (index < 3) {
                                                        setState(() {});
                                                        FocusScope.of(context)
                                                            .nextFocus();
                                                      } else if (index == 3) {
                                                        bool allFieldsFilled =
                                                            controllers.every(
                                                                (controller) =>
                                                                    controller
                                                                        .text
                                                                        .isNotEmpty);
                                                        if (allFieldsFilled) {
                                                          // استدعاء دالة التحقق
                                                          _verifyOtp();
                                                        }
                                                      }
                                                    } else {
                                                      if (index > 0) {
                                                        controllers[index]
                                                            .clear();
                                                        setState(() {});
                                                        FocusScope.of(context)
                                                            .previousFocus();
                                                      }
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _canResend
                                            ? () async {
                                                // تعيين _isVerifying إلى true لإظهار حالة التحميل
                                                setState(() {
                                                  _isVerifying = true;
                                                });

                                                resetTimer();

                                                // استخدام OTPService لإعادة إرسال الرمز
                                                try {
                                                  Map<String, dynamic> result;

                                                  if (_isUsingEmail) {
                                                    // إرسال الرمز عبر البريد الإلكتروني
                                                    result = await OTPService
                                                        .sendRegistrationOTPByEmail(
                                                      email: widget.email,
                                                      userType: widget.userType,
                                                      fullName: widget.fullName,
                                                      birthDate: widget.dob,
                                                      isInitialRequest: false,
                                                    );
                                                  } else {
                                                    // إرسال الرمز عبر الرسائل القصيرة
                                                    result = await OTPService
                                                        .sendRegistrationOTPBySMS(
                                                      phoneNumber: widget.phone,
                                                      userType: widget.userType,
                                                      fullName: widget.fullName,
                                                      birthDate: widget.dob,
                                                      isInitialRequest: false,
                                                    );
                                                  }

                                                  // التحقق من أن الـ Widget ما زالت مرتبطة بعد العمليات غير المتزامنة
                                                  if (!mounted) return;

                                                  // إعادة تعيين حالة التحقق
                                                  setState(() {
                                                    _isVerifying = false;
                                                  });

                                                  if (result['success']) {
                                                    // استخدام الدالة الآمنة لعرض رسالة النجاح
                                                    _showSnackBar(
                                                      'code_resent'.tr(),
                                                      const Color(0xFF2F9C95),
                                                    );
                                                  } else {
                                                    // استخدام الدالة الآمنة لعرض رسالة الخطأ
                                                    _showSnackBar(
                                                      result['message'] ??
                                                          'error_resending_code'
                                                              .tr(),
                                                      Colors.red,
                                                    );
                                                  }
                                                } catch (e) {
                                                  debugPrint(
                                                      'Error resending OTP: $e');

                                                  // استخدام الدالة الآمنة لعرض رسالة الخطأ
                                                  _showSnackBar(
                                                    'error_resending_code'.tr(),
                                                    Colors.red,
                                                  );
                                                }
                                              }
                                            : null,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          disabledForegroundColor:
                                              Colors.grey.withOpacity(0.6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_isVerifying)
                                              Container(
                                                width: 12,
                                                height: 12,
                                                margin: const EdgeInsets.only(
                                                    right: 8),
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: _canResend
                                                      ? const Color(0xFF2F9C95)
                                                      : Colors.grey
                                                          .withOpacity(0.6),
                                                ),
                                              ),
                                            Text(
                                              'resend_code'.tr(),
                                              style: TextStyle(
                                                  color: _canResend
                                                      ? const Color(0xFF2F9C95)
                                                      : Colors.grey
                                                          .withOpacity(0.6),
                                                  fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'contact_support'.tr(),
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 20),
                                                      GridView.count(
                                                        shrinkWrap: true,
                                                        crossAxisCount: 2,
                                                        mainAxisSpacing: 15,
                                                        crossAxisSpacing: 15,
                                                        children: [
                                                          _buildIconButton(
                                                            Icons.chat,
                                                            Colors.green,
                                                            Colors.green[50]!,
                                                            () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                          _buildIconButton(
                                                            Icons.email,
                                                            Colors.blue,
                                                            Colors.blue[50]!,
                                                            () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                          _buildIconButton(
                                                            Icons.facebook,
                                                            Colors.indigo,
                                                            Colors.indigo[50]!,
                                                            () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                          _buildIconButton(
                                                            Icons
                                                                .phone_in_talk_sharp,
                                                            Colors.pink,
                                                            Colors.pink[50]!,
                                                            () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                        ),
                                        child: Text(
                                          'not_received'.tr(),
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _canResend
                                            ? () async {
                                                setState(() {
                                                  _isUsingEmail =
                                                      !_isUsingEmail;
                                                  _isVerifying = true;
                                                });
                                                resetTimer();

                                                // إرسال رمز جديد عبر الوسيلة المختارة
                                                try {
                                                  Map<String, dynamic> result;
                                                  if (_isUsingEmail) {
                                                    // تغيير إلى البريد الإلكتروني
                                                    result = await OTPService
                                                        .sendRegistrationOTPByEmail(
                                                      email: widget.email,
                                                      userType: widget.userType,
                                                      fullName: widget.fullName,
                                                      birthDate: widget.dob,
                                                      isInitialRequest: false,
                                                    );
                                                  } else {
                                                    // تغيير إلى الرسائل القصيرة
                                                    result = await OTPService
                                                        .sendRegistrationOTPBySMS(
                                                      phoneNumber: widget.phone,
                                                      userType: widget.userType,
                                                      fullName: widget.fullName,
                                                      birthDate: widget.dob,
                                                      isInitialRequest: false,
                                                    );
                                                  }

                                                  if (!mounted) return;

                                                  // إعادة تعيين حالة التحقق
                                                  setState(() {
                                                    _isVerifying = false;
                                                  });

                                                  if (result['success']) {
                                                    _showSnackBar(
                                                      _isUsingEmail
                                                          ? 'verification_sent_email'
                                                              .tr()
                                                          : 'verification_sent_phone'
                                                              .tr(),
                                                      const Color(0xFF2F9C95),
                                                    );
                                                  } else {
                                                    _showSnackBar(
                                                      result['message'] ??
                                                          'error_sending_code'
                                                              .tr(),
                                                      Colors.red,
                                                    );
                                                  }
                                                } catch (e) {
                                                  debugPrint(
                                                      'Error switching verification method: $e');
                                                  if (!mounted) return;

                                                  setState(() {
                                                    _isVerifying = false;
                                                  });

                                                  _showSnackBar(
                                                    'error_sending_code'.tr(),
                                                    Colors.red,
                                                  );
                                                }
                                              }
                                            : null,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          disabledForegroundColor:
                                              Colors.grey.withOpacity(0.6),
                                        ),
                                        child: Text(
                                          _isUsingEmail
                                              ? 'send_phone'.tr()
                                              : 'send_email'.tr(),
                                          style: TextStyle(
                                              color: _canResend
                                                  ? Colors.grey[600]
                                                  : Colors.grey
                                                      .withOpacity(0.6),
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.lock_outline,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'step3'.tr(),
                                        style:
                                            TextStyle(color: Colors.grey[400]),
                                      ),
                                      Text(
                                        'create_password'.tr(),
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
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
                          height: MediaQuery.of(context).size.height * 0.1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // إلغاء العداد عند الخروج من الصفحة
    _timer.cancel();
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildIconButton(IconData icon, Color iconColor, Color backgroundColor,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 35,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  // الدالة القديمة للإرسال عبر SMS تم استبدالها بالمنطق الجديد أعلاه
}
