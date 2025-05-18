import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'newpassword.dart';
import 'package:flutter/services.dart';
import 'forget_password.dart';
import 'services/otp_service.dart';

class CodePage extends StatefulWidget {
  final String? phoneNumber;
  final String? email;
  final String userType;

  const CodePage({
    super.key,
    this.phoneNumber,
    this.email,
    required this.userType,
  });

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  final List<TextEditingController> controllers =
      List.generate(4, (index) => TextEditingController());
  Timer _timer = Timer(Duration.zero, () {});
  int _remainingSeconds = 179;
  bool _canResend = false;
  int _resendCount = 0;
  bool _isVerifying = false;
  bool _isSendingCode = false;
  String? _verificationError;
  bool _initialCodeSent = false;

  final int _baseWaitSeconds = 180;

  @override
  void initState() {
    super.initState();
    _startTimerAndSendCode(isInitial: true);
  }

  void _startTimerAndSendCode({bool isInitial = false}) {
    if (_isSendingCode || (isInitial && _initialCodeSent)) return;

    setState(() {
      _isSendingCode = true;
      _canResend = false;

      if (!isInitial && _resendCount > 0) {
        _remainingSeconds = _baseWaitSeconds * (1 << _resendCount);
      } else {
        _remainingSeconds = _baseWaitSeconds;
      }
    });

    startTimer();

    _sendVerificationCode(isInitial);
  }

  void startTimer() {
    if (_timer.isActive) {
      _timer.cancel();
    }

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
    if (_canResend && !_isSendingCode) {
      setState(() {
        _resendCount++;
      });

      _startTimerAndSendCode();
    }
  }

  Future<void> _sendVerificationCode(bool isInitial) async {
    Map<String, dynamic> result;

    try {
      if (widget.email != null && widget.email!.isNotEmpty) {
        result = await OTPService.sendOTPByEmail(
          email: widget.email!,
          userType: widget.userType,
          isInitialRequest: isInitial,
        );
      } else if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
        result = await OTPService.sendOTPBySMS(
          phoneNumber: widget.phoneNumber!,
          userType: widget.userType,
          isInitialRequest: isInitial,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('contact_method_required'.tr()),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSendingCode = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isSendingCode = false;
          if (isInitial) _initialCodeSent = true;
        });

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  isInitial ? 'verification_sent'.tr() : 'code_resent'.tr()),
              backgroundColor: const Color(0xFF2F9C95),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'].toString().tr()),
              backgroundColor: Colors.red,
            ),
          );

          setState(() {
            _canResend = true;
            _timer.cancel();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
          _canResend = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_sending_code'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
    return "$minutes${'minutes'.tr()} $seconds${'seconds'.tr()}";
  }

  String _getMaskedContact() {
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      if (widget.phoneNumber!.length > 4) {
        return "****${widget.phoneNumber!.substring(widget.phoneNumber!.length - 4)}";
      } else {
        return "****${widget.phoneNumber!}";
      }
    } else if (widget.email != null && widget.email!.isNotEmpty) {
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
    return "****";
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    final logoSize = screenHeight * 0.1;
    final contentPadding = EdgeInsets.all(screenWidth * 0.04);
    final inputFieldSize = screenWidth * 0.1;
    final spacingHeight = screenHeight * 0.02;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (bool didPop, Future<dynamic> Function(bool)? popResult) async {
        if (didPop) return;
        for (var controller in controllers) {
          controller.clear();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ForgetPassword(userType: widget.userType)),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2F9C95),
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
                    Padding(
                      padding: EdgeInsets.only(
                          top: screenHeight * 0.02,
                          right: screenWidth * 0.04,
                          left: screenWidth * 0.04),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () {
                              for (var controller in controllers) {
                                controller.clear();
                              }
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ForgetPassword(
                                        userType: widget.userType)),
                              );
                            },
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
                                                      color:
                                                          _verificationError !=
                                                                      null &&
                                                                  controllers[
                                                                          index]
                                                                      .text
                                                                      .isNotEmpty
                                                              ? Colors
                                                                  .red.shade100
                                                              : const Color(
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
                                                      readOnly: _isVerifying ||
                                                          index !=
                                                              _getActiveFieldIndex(),
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .digitsOnly,
                                                        LengthLimitingTextInputFormatter(
                                                            1),
                                                      ],
                                                      onChanged: (value) {
                                                        if (_verificationError !=
                                                            null) {
                                                          setState(() {
                                                            _verificationError =
                                                                null;
                                                          });
                                                        }

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
                                              SizedBox(
                                                  height: screenHeight * 0.01),
                                              if (_isVerifying)
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            Color(0xFF2F9C95),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      'verifying'.tr(),
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF2F9C95),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (_verificationError != null &&
                                                  !_isVerifying)
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8.0),
                                                  child: Text(
                                                    _verificationError!.tr(),
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              TextButton(
                                                onPressed: _canResend &&
                                                        !_isVerifying &&
                                                        !_isSendingCode
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
                                                  _isSendingCode
                                                      ? 'sending_code'.tr()
                                                      : 'resend_code'.tr(),
                                                  style: TextStyle(
                                                      color: _canResend &&
                                                              !_isVerifying &&
                                                              !_isSendingCode
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
                                              backgroundColor: Colors.grey[200],
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
    if (_timer.isActive) {
      _timer.cancel();
    }
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

  void _checkForCompletion() async {
    bool allFieldsFilled =
        controllers.every((controller) => controller.text.isNotEmpty);

    if (allFieldsFilled) {
      String otpCode =
          controllers.map((controller) => controller.text).join('');

      setState(() {
        _isVerifying = true;
        _verificationError = null;
      });

      try {
        String? email;
        String? phoneNumber;

        if (widget.email != null && widget.email!.isNotEmpty) {
          email = widget.email!.trim().toLowerCase();
        }

        if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
          String cleanPhone = widget.phoneNumber!.trim();
          phoneNumber =
              cleanPhone.startsWith('+') ? cleanPhone : '+222$cleanPhone';
        }

        debugPrint('Verifying OTP: $otpCode');
        debugPrint('Email: $email, Phone: $phoneNumber');

        final result = await OTPService.verifyOTP(
          email: email,
          phoneNumber: phoneNumber,
          otpCode: otpCode,
          userType: widget.userType,
        );

        if (!mounted) return;

        setState(() {
          _isVerifying = false;
        });

        if (result['success']) {
          String identifier = (email ?? phoneNumber) ?? '';

          debugPrint('=== OTP VERIFICATION SUCCESSFUL ===');
          debugPrint('User ID: ${result['user_id']}');
          debugPrint('Original email: ${widget.email}');
          debugPrint('Original phone: ${widget.phoneNumber}');
          debugPrint('Formatted email: $email');
          debugPrint('Formatted phone: $phoneNumber');
          debugPrint('Using identifier: $identifier');
          debugPrint('OTP code: $otpCode');

          debugPrint(
              '⚠️ هام: نفس رمز OTP مطلوب لإعادة تعيين كلمة المرور، لكنه قد تم تأشيره كمستخدم بالفعل!');

          debugPrint('محاولة إعادة تنشيط رمز OTP...');
          try {
            await OTPService.reactivateOTP(
              email: email,
              phoneNumber: phoneNumber,
              otpCode: otpCode,
              userType: widget.userType,
            );
            debugPrint('تمت محاولة إعادة تنشيط OTP بنجاح');
          } catch (e) {
            debugPrint('خطأ في إعادة تنشيط OTP: $e');
          }

          if (!mounted) return;

          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  NewPasswordPage(
                identifier: identifier,
                otpCode: otpCode,
                userType: widget.userType,
                userId: result['user_id'] ?? 0,
              ),
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
        } else {
          setState(() {
            _verificationError = result['message'];
          });

          _showErrorDialog(result['message'].toString().tr());

          for (var controller in controllers) {
            controller.clear();
          }

          FocusScope.of(context).requestFocus(FocusNode());
        }
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isVerifying = false;
          _verificationError = 'system_error';
        });

        _showErrorDialog('system_error'.tr());
      }
    }
  }
}
