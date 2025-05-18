import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'code.dart';
import 'services/auth_service.dart';

class ForgetPassword extends StatefulWidget {
  final String userType;

  const ForgetPassword({
    super.key,
    required this.userType,
  });

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  bool showEmailInput = false;
  bool showPhoneInput = false;
  String selectedMethod = ''; // To track which method was selected
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  // إضافة متغير للتحميل
  bool _isLoading = false;

  // إضافة خدمة المصادقة
  final AuthService _authService = AuthService();

  // Regular expressions for validation
  final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
  final RegExp phoneRegex = RegExp(r'^[2-4]\d{7}$');

  String? emailError;
  String? phoneError;

  void validateEmail(String value) {
    if (value.isEmpty) {
      setState(() {
        emailError = 'email_required'.tr();
      });
    } else if (!emailRegex.hasMatch(value)) {
      setState(() {
        emailError = 'email_invalid'.tr();
      });
    } else {
      setState(() {
        emailError = null;
      });
    }
  }

  void validatePhone(String value) {
    if (value.isEmpty) {
      setState(() {
        phoneError = 'phone_required'.tr();
      });
    } else if (!phoneRegex.hasMatch(value)) {
      setState(() {
        phoneError = 'phone_invalid'.tr();
      });
    } else {
      setState(() {
        phoneError = null;
      });
    }
  }

  // دالة للتحقق من وجود المستخدم قبل إرسال الرمز
  Future<bool> _verifyUserExists(String identifier, bool isEmail) async {
    setState(() {
      _isLoading = true;
    });

    debugPrint('*** بدء التحقق من وجود المستخدم ***');
    debugPrint('المعرف: $identifier');
    debugPrint('هل هو بريد إلكتروني؟ $isEmail');
    debugPrint('نوع المستخدم: ${widget.userType}');

    try {
      // استخدام النوع المناسب (Client أو Livreur) بناءً على widget.userType
      String userTypeForApi =
          widget.userType == 'Livreur' ? 'Livreur' : 'Client';

      debugPrint('نوع المستخدم المُرسل للـ API: $userTypeForApi');

      final result = await _authService.checkUserExists(
        identifier,
        isEmail: isEmail,
        userType: userTypeForApi,
      );

      // تأكد من أن ال widget لا يزال مُثبت قبل تحديث الحالة
      if (!mounted) {
        debugPrint('الحالة غير مُثبتة، إنهاء الدالة');
        return false;
      }

      debugPrint('استجابة التحقق من وجود المستخدم: $result');
      setState(() {
        _isLoading = false;
      });

      if (!result['exists']) {
        // عرض رسالة خطأ للمستخدم - لم يتم العثور على المستخدم
        String errorMessage = 'user_not_found'.tr();

        if (widget.userType == 'Client') {
          errorMessage = 'client_not_found'.tr();
        } else if (widget.userType == 'Livreur') {
          errorMessage = 'driver_not_found'.tr();
        }

        debugPrint('المستخدم غير موجود، رسالة الخطأ: $errorMessage');
        _showErrorDialog(errorMessage);
        return false;
      }

      debugPrint('المستخدم موجود، العودة بقيمة true');
      return true;
    } catch (e) {
      // تأكد من أن ال widget لا يزال مُثبت قبل تحديث الحالة
      if (!mounted) {
        debugPrint('خطأ: $e، لكن الحالة غير مُثبتة');
        return false;
      }

      debugPrint('استثناء في التحقق من وجود المستخدم: $e');
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog('server_error'.tr());
      return false;
    }
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

  // دالة للتعامل مع إعادة تعيين كلمة المرور عن طريق البريد الإلكتروني
  void _processEmailReset(String email) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // التحقق من وجود المستخدم أولاً
      bool userExists = await _verifyUserExists(email, true);

      // تأكد من أن الحالة لا تزال مثبتة بعد الاستدعاء غير المتزامن
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (userExists) {
        // الانتقال إلى صفحة إدخال الرمز - سيتم إرسال الرمز تلقائياً في صفحة CodePage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CodePage(
              email: email,
              phoneNumber: null,
              userType: widget.userType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('server_error'.tr());
      }
    }
  }

  // دالة للتعامل مع إعادة تعيين كلمة المرور عن طريق رقم الهاتف
  void _processPhoneReset(String phone) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // التحقق من وجود المستخدم أولاً
      bool userExists = await _verifyUserExists(phone, false);

      // تأكد من أن الحالة لا تزال مثبتة بعد الاستدعاء غير المتزامن
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (userExists) {
        // الانتقال إلى صفحة إدخال الرمز - سيتم إرسال الرمز تلقائياً في صفحة CodePage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CodePage(
              email: null,
              phoneNumber: phone,
              userType: widget.userType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('server_error'.tr());
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: const Color(0xFF2F9C95),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  // تم إزالة زر تغيير اللغة من هنا
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Image.asset(
                  'assets/images/Groupes@4x.png',
                  width: 110,
                  height: 110,
                ),
              ),
            ),
            // Main Content Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Center(
                                    child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    'Password_reset'.tr(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )),

                                // Form with Steps
                                Stack(
                                  children: [
                                    // Steps Line
                                    Positioned(
                                      right: context.locale.languageCode == 'ar'
                                          ? 20
                                          : null,
                                      left: context.locale.languageCode != 'ar'
                                          ? 20
                                          : null,
                                      top: 40,
                                      bottom:
                                          45, // Make it stop at step 3 with a small gap
                                      child: Container(
                                        width: 2,
                                        color: const Color(0xFF2F9C95),
                                      ),
                                    ),
                                    // Content
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Step 1 with inputs
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
                                                  '1',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'step1'.tr(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'Processing_method'.tr(),
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),

                                        // Input Fields or Buttons
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: context.locale.languageCode ==
                                                    'ar'
                                                ? 0
                                                : 52,
                                            right:
                                                context.locale.languageCode ==
                                                        'ar'
                                                    ? 52
                                                    : 0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                context.locale.languageCode ==
                                                        'ar'
                                                    ? CrossAxisAlignment.end
                                                    : CrossAxisAlignment.start,
                                            children: [
                                              if (!showEmailInput &&
                                                  !showPhoneInput)
                                                Column(
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: () {
                                                        setState(() {
                                                          showPhoneInput = true;
                                                          selectedMethod =
                                                              'phone';
                                                        });
                                                      },
                                                      icon: const Icon(
                                                        Icons.phone,
                                                        color: Colors.white,
                                                      ),
                                                      label: Text(
                                                        'To_Num'.tr(),
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16),
                                                      ),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        minimumSize: Size(
                                                            constraints
                                                                .maxWidth,
                                                            52),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        elevation: 2,
                                                        backgroundColor:
                                                            const Color(
                                                                0xFF2F9C95),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    ElevatedButton.icon(
                                                      onPressed: () {
                                                        setState(() {
                                                          showEmailInput = true;
                                                          selectedMethod =
                                                              'email';
                                                        });
                                                      },
                                                      icon: const Icon(
                                                          Icons.email,
                                                          color: Colors.white),
                                                      label: Text(
                                                        'To_Email'.tr(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        minimumSize: Size(
                                                            constraints
                                                                .maxWidth,
                                                            52),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        elevation: 2,
                                                        backgroundColor:
                                                            const Color(
                                                                0xFF2F9C95),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (showPhoneInput)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    TextField(
                                                      controller:
                                                          phoneController,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            'phone_number'.tr(),
                                                        labelStyle:
                                                            const TextStyle(
                                                          color:
                                                              Color(0xFF2F9C95),
                                                        ),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        prefixIcon: const Icon(
                                                            Icons.phone,
                                                            color: Color(
                                                                0xFF2F9C95)),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          borderSide:
                                                              const BorderSide(
                                                            color: Color(
                                                                0xFF2F9C95),
                                                            width: 2,
                                                          ),
                                                        ),
                                                        errorText: phoneError,
                                                      ),
                                                      keyboardType:
                                                          TextInputType.phone,
                                                      onChanged: validatePhone,
                                                    ),
                                                  ],
                                                ),
                                              if (showEmailInput)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    TextField(
                                                      controller:
                                                          emailController,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: 'email'.tr(),
                                                        labelStyle:
                                                            const TextStyle(
                                                          color:
                                                              Color(0xFF2F9C95),
                                                        ),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        prefixIcon: const Icon(
                                                            Icons.email,
                                                            color: Color(
                                                                0xFF2F9C95)),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          borderSide:
                                                              const BorderSide(
                                                            color: Color(
                                                                0xFF2F9C95),
                                                            width: 2,
                                                          ),
                                                        ),
                                                        errorText: emailError,
                                                      ),
                                                      keyboardType:
                                                          TextInputType
                                                              .emailAddress,
                                                      onChanged: validateEmail,
                                                    ),
                                                  ],
                                                ),
                                              if (showEmailInput ||
                                                  showPhoneInput)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 20),
                                                  child: ElevatedButton(
                                                    onPressed: _isLoading
                                                        ? null
                                                        : () {
                                                            // التحقق من صحة المدخلات
                                                            if (selectedMethod ==
                                                                'email') {
                                                              validateEmail(
                                                                  emailController
                                                                      .text);
                                                              if (emailError !=
                                                                  null) {
                                                                return;
                                                              }
                                                              // تنفيذ العملية بشكل منفصل
                                                              _processEmailReset(
                                                                  emailController
                                                                      .text
                                                                      .trim());
                                                            } else if (selectedMethod ==
                                                                'phone') {
                                                              validatePhone(
                                                                  phoneController
                                                                      .text);
                                                              if (phoneError !=
                                                                  null) {
                                                                return;
                                                              }
                                                              // تنفيذ العملية بشكل منفصل
                                                              _processPhoneReset(
                                                                  phoneController
                                                                      .text
                                                                      .trim());
                                                            }
                                                          },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      minimumSize: Size(
                                                          constraints.maxWidth,
                                                          52),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      elevation: 2,
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF2F9C95),
                                                      disabledBackgroundColor:
                                                          Colors.grey,
                                                    ),
                                                    child: _isLoading
                                                        ? const SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                        : Text(
                                                            'Send_Code'.tr(),
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
                                              if (showEmailInput ||
                                                  showPhoneInput)
                                                Align(
                                                  alignment: context.locale
                                                              .languageCode ==
                                                          'ar'
                                                      ? Alignment.centerRight
                                                      : Alignment.centerLeft,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 12),
                                                    child: TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          showEmailInput =
                                                              false;
                                                          showPhoneInput =
                                                              false;
                                                          selectedMethod = '';
                                                          emailError = null;
                                                          phoneError = null;
                                                        });
                                                      },
                                                      style:
                                                          TextButton.styleFrom(
                                                        foregroundColor:
                                                            const Color(
                                                                0xFF2F9C95),
                                                      ),
                                                      child: Text(
                                                        'change_method'.tr(),
                                                        style: const TextStyle(
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
                                        const SizedBox(height: 30),

                                        // Step 2
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: CircleAvatar(
                                                radius: 14,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                child: Text(
                                                  '2',
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'step2'.tr(),
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'verify_code'.tr(),
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 30),

                                        // Step 3
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: CircleAvatar(
                                                radius: 14,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                child: Text(
                                                  '3',
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'step3'.tr(),
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'create_Npassword'.tr(),
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: screenHeight * 0.05),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom Logo
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Image.asset(
                          "assets/images/Rectangle@4x.png",
                          height: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
