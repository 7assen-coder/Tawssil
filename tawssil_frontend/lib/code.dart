import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'newpassword.dart';
import 'package:flutter/services.dart';
import 'forget_password.dart';

class CodePage extends StatefulWidget {
  final String? phoneNumber;
  final String? email;

  const CodePage({
    super.key,
    this.phoneNumber,
    this.email,
  });

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  final List<TextEditingController> controllers =
      List.generate(4, (index) => TextEditingController());
  late Timer _timer;
  int _remainingSeconds = 179;
  bool _canResend = false;
  int _resendCount = 0;

  @override
  void initState() {
    super.initState();
    // بدء العد التنازلي
    startTimer();
  }

  void startTimer() {
    setState(() {
      _canResend = false;
    });

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

  void resendCode() {
    if (_canResend) {
      setState(() {
        _resendCount++;
        // زيادة الوقت في كل مرة: 3 دقائق + (3 * عدد مرات إعادة الإرسال)
        _remainingSeconds = 180 + (180 * _resendCount);
        _canResend = false;
      });
      startTimer();
      // هنا يمكن إضافة كود لإعادة إرسال الرمز فعلياً
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('code_resent'.tr()),
          backgroundColor: const Color(0xFF2F9C95),
        ),
      );
    }
  }

  // دالة لإرجاع مؤشر الحقل النشط (أول حقل فارغ)
  int _getActiveFieldIndex() {
    for (int i = 0; i < controllers.length; i++) {
      if (controllers[i].text.isEmpty) {
        return i;
      }
    }
    return controllers.length - 1;
  }

  String get formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return "${minutes}m ${seconds}s";
  }

  // دالة لإخفاء جزء من معلومات الاتصال وعرضها بشكل آمن
  String _getMaskedContact() {
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      // إذا كان رقم الهاتف موجودًا، نعرض آخر 4 أرقام فقط
      if (widget.phoneNumber!.length > 4) {
        return "****${widget.phoneNumber!.substring(widget.phoneNumber!.length - 4)}";
      } else {
        return "****${widget.phoneNumber!}";
      }
    } else if (widget.email != null && widget.email!.isNotEmpty) {
      // إذا كان البريد الإلكتروني موجودًا، نعرض جزء منه فقط
      final parts = widget.email!.split('@');
      if (parts.length == 2) {
        String username = parts[0];
        String domain = parts[1];
        if (username.length > 2) {
          username = "${username.substring(0, 2)}****";
        }
        return "$username@$domain";
      }
      return "****@****";
    }
    // إذا لم تكن هناك معلومات متاحة
    return "****";
  }

  @override
  Widget build(BuildContext context) {
    // إضافة متغيرات لأحجام الشاشة
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // حساب الأحجام النسبية بناءً على حجم الشاشة
    final logoSize = screenHeight * 0.1;
    final contentPadding = EdgeInsets.all(screenWidth * 0.04);
    final inputFieldSize = screenWidth * 0.1;
    final spacingHeight = screenHeight * 0.02;

    // استخدام PopScope بدلاً من WillPopScope لمعالجة الرجوع عند الضغط على زر الرجوع الخاص بنظام Android
    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (bool didPop, Future<dynamic> Function(bool)? popResult) async {
        if (didPop) return;
        // مسح جميع المدخلات والعودة إلى صفحة forget_password عند الضغط على زر الرجوع
        for (var controller in controllers) {
          controller.clear();
        }
        // استخدام Navigator.pushReplacement بدلاً من pushReplacementNamed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ForgetPassword()),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2F9C95),
        // إزالة شريط سفلي للتنقل مع زر الرجوع
        body: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // إضافة صف يحتوي على زر الرجوع ومنتقي اللغة
                    Padding(
                      padding: EdgeInsets.only(
                          top: screenHeight * 0.02,
                          right: screenWidth * 0.04,
                          left: screenWidth * 0.04),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // زر الرجوع
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () {
                              // مسح جميع المدخلات والعودة إلى صفحة forget_password
                              for (var controller in controllers) {
                                controller.clear();
                              }
                              // استخدام Navigator.pushReplacement بدلاً من pushReplacementNamed
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgetPassword()),
                              );
                            },
                          ),
                          // منتقي اللغة
                          PopupMenuButton<String>(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.locale.languageCode.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down,
                                      color: Colors.black),
                                ],
                              ),
                            ),
                            onSelected: (String value) {
                              context.setLocale(Locale(value));
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'fr',
                                child: Text('FR - Français'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'ar',
                                child: Text('AR - العربية'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'en',
                                child: Text('EN - English'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.03),
                      child: Center(
                        child: Image.asset(
                          'assets/images/Groupes@4x.png',
                          width: logoSize,
                          height: logoSize,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(40)),
                        ),
                        child: Padding(
                          padding: contentPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Password_reset'.tr(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: spacingHeight),
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
                                    // تمديد الخط الأخضر ليصل إلى الخطوة 3
                                    bottom: 0,
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
                                              backgroundColor: Color(
                                                  0xFF2F9C95), // You can choose your color
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
                                          const SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor: Color(
                                                  0xFF2F9C95), // You can choose your color
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
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                'verify_code'.tr(),
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12),
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
                                              Text(
                                                '${'verification_sent'.tr()} ${_getMaskedContact()}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${'expiration'.tr()} $formattedTime',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: List.generate(
                                                  4,
                                                  (index) => Container(
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          screenWidth * 0.01,
                                                    ),
                                                    width: inputFieldSize,
                                                    height: inputFieldSize,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFFFD700),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: TextField(
                                                      controller:
                                                          controllers[index],
                                                      textAlign:
                                                          TextAlign.center,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      maxLength: 1,
                                                      style: const TextStyle(
                                                          fontSize: 18),
                                                      decoration:
                                                          const InputDecoration(
                                                        counterText: '',
                                                        border:
                                                            InputBorder.none,
                                                      ),
                                                      enableInteractiveSelection:
                                                          false,
                                                      readOnly: index !=
                                                          _getActiveFieldIndex(),
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
                                                            FocusScope.of(
                                                                    context)
                                                                .nextFocus();
                                                          } else if (index ==
                                                              3) {
                                                            _checkForCompletion();
                                                          }
                                                        } else {
                                                          if (index > 0) {
                                                            controllers[index]
                                                                .clear();
                                                            setState(() {});
                                                            FocusScope.of(
                                                                    context)
                                                                .previousFocus();
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: _canResend
                                                    ? resendCode
                                                    : null,
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  disabledForegroundColor:
                                                      Colors.grey
                                                          .withOpacity(0.6),
                                                ),
                                                child: Text(
                                                  'resend_code'.tr(),
                                                  style: TextStyle(
                                                      color: _canResend
                                                          ? const Color(
                                                              0xFF2F9C95)
                                                          : Colors.grey
                                                              .withOpacity(0.6),
                                                      fontSize: 13),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return Dialog(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      20.0),
                                                        ),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(20),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                'contact_support'
                                                                    .tr(),
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 20),
                                                              GridView.count(
                                                                shrinkWrap:
                                                                    true,
                                                                crossAxisCount:
                                                                    2,
                                                                mainAxisSpacing:
                                                                    15,
                                                                crossAxisSpacing:
                                                                    15,
                                                                children: [
                                                                  _buildIconButton(
                                                                    Icons.chat,
                                                                    Colors
                                                                        .green,
                                                                    Colors.green[
                                                                        50]!,
                                                                    () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  ),
                                                                  _buildIconButton(
                                                                    Icons.email,
                                                                    Colors.blue,
                                                                    Colors.blue[
                                                                        50]!,
                                                                    () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  ),
                                                                  _buildIconButton(
                                                                    Icons
                                                                        .facebook,
                                                                    Colors
                                                                        .indigo,
                                                                    Colors.indigo[
                                                                        50]!,
                                                                    () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  ),
                                                                  _buildIconButton(
                                                                    Icons
                                                                        .phone_in_talk_sharp,
                                                                    Colors.pink,
                                                                    Colors.pink[
                                                                        50]!,
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
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                ),
                                                child: Text(
                                                  'not_received'.tr(),
                                                  style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor: Colors.grey[
                                                  200], // You can choose your color
                                              child: Text(
                                                '3',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
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
                                                'step3'.tr(),
                                                style: TextStyle(
                                                    color: Colors.grey[400]),
                                              ),
                                              Text(
                                                'create_Npassword'.tr(),
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
                              SizedBox(height: spacingHeight),
                              Padding(
                                padding:
                                    EdgeInsets.only(top: screenHeight * 0.03),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  // إضافة دالة للتحقق من اكتمال الإدخال
  void _checkForCompletion() {
    bool allFieldsFilled =
        controllers.every((controller) => controller.text.isNotEmpty);
    if (allFieldsFilled) {
      // إذا تم إدخال جميع الحقول، ننتقل إلى الشاشة التالية
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          // التحقق من أن الـ State ما زالت متصلة بالـ Widget
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const NewPasswordPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          );
        }
      });
    }
  }
}
