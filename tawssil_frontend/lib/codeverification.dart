import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'password.dart';

class CodeVerification extends StatefulWidget {
  final String email;
  final String phone;

  const CodeVerification({
    super.key,
    required this.email,
    required this.phone,
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
  bool _isUsingEmail = false;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
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
    return "${minutes}m ${seconds}s";
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
      // إخفاء جزء من رقم الهاتف (مثال: ****4343)
      String phone = widget.phone;
      if (phone.length > 4) {
        return "${'*' * (phone.length - 4)}${phone.substring(phone.length - 4)}";
      }
      return phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F9C95),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, right: 16),
                child: Align(
                  alignment: Alignment.topRight,
                  child: PopupMenuButton<String>(
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
                ),
              ),
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
                                      Text(
                                        '${'verification_sent'.tr()} $maskedContact',
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
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            width: 45,
                                            height: 45,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFD700),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: TextField(
                                              controller: controllers[index],
                                              textAlign: TextAlign.center,
                                              keyboardType:
                                                  TextInputType.number,
                                              maxLength: 1,
                                              style:
                                                  const TextStyle(fontSize: 18),
                                              decoration: const InputDecoration(
                                                counterText: '',
                                                border: InputBorder.none,
                                              ),
                                              enableInteractiveSelection: false,
                                              readOnly: index !=
                                                  _getActiveFieldIndex(),
                                              focusNode: null,
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
                                                                controller.text
                                                                    .isNotEmpty);
                                                    if (allFieldsFilled) {
                                                      Navigator.push(
                                                        context,
                                                        PageRouteBuilder(
                                                          pageBuilder: (context,
                                                                  animation,
                                                                  secondaryAnimation) =>
                                                              const Password(),
                                                          transitionsBuilder:
                                                              (context,
                                                                  animation,
                                                                  secondaryAnimation,
                                                                  child) {
                                                            const begin =
                                                                Offset(
                                                                    1.0, 0.0);
                                                            const end =
                                                                Offset.zero;
                                                            const curve = Curves
                                                                .easeInOut;
                                                            var tween = Tween(
                                                                    begin:
                                                                        begin,
                                                                    end: end)
                                                                .chain(CurveTween(
                                                                    curve:
                                                                        curve));
                                                            var offsetAnimation =
                                                                animation.drive(
                                                                    tween);
                                                            return SlideTransition(
                                                                position:
                                                                    offsetAnimation,
                                                                child: child);
                                                          },
                                                        ),
                                                      );
                                                    }
                                                  }
                                                } else {
                                                  if (index > 0) {
                                                    controllers[index].clear();
                                                    setState(() {});
                                                    FocusScope.of(context)
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
                                            ? () {
                                                resetTimer();
                                                // هنا يمكن إضافة منطق لإعادة إرسال الرمز
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'code_resent'.tr()),
                                                    backgroundColor:
                                                        const Color(0xFF2F9C95),
                                                  ),
                                                );
                                              }
                                            : null,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          disabledForegroundColor:
                                              Colors.grey.withOpacity(0.6),
                                        ),
                                        child: Text(
                                          'resend_code'.tr(),
                                          style: TextStyle(
                                              color: _canResend
                                                  ? const Color(0xFF2F9C95)
                                                  : Colors.grey
                                                      .withOpacity(0.6),
                                              fontSize: 13),
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
                                            ? () {
                                                setState(() {
                                                  _isUsingEmail =
                                                      !_isUsingEmail;
                                                });
                                                resetTimer();
                                                // هنا يمكن إضافة منطق لإرسال الرمز عبر الوسيلة المختارة
                                                String method = _isUsingEmail
                                                    ? 'email'
                                                    : 'phone';
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        '${'code_sent_to'.tr()} $method'),
                                                    backgroundColor:
                                                        const Color(0xFF2F9C95),
                                                  ),
                                                );
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

  int _getActiveFieldIndex() {
    for (int i = 0; i < controllers.length; i++) {
      if (controllers[i].text.isEmpty) {
        return i;
      }
    }
    return controllers.length - 1;
  }
}
