import 'package:flutter/material.dart';
import 'codeverification.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/auth_service.dart';
import 'services/otp_service.dart';

// إضافة مفتاح معلومات لإخفاء رسالة الخطأ
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class NewAccount extends StatefulWidget {
  final String userType;
  final String email;
  final String phone;
  final String fullName;
  final String dob;

  const NewAccount({
    super.key,
    required this.userType,
    this.email = '',
    this.phone = '',
    this.fullName = '',
    this.dob = '',
  });

  @override
  State<NewAccount> createState() => _NewAccountState();
}

class _NewAccountState extends State<NewAccount> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _dobError;
  bool _isFormValid = false;

  // إضافة متغيرات للتحكم في حالة التحميل والتحقق
  bool _isLoading = false;
  bool _isEmailChecking = false;
  bool _isPhoneChecking = false;
  bool _emailExists = false;
  bool _phoneExists = false;
  bool _isSendingOTP = false;

  // تحديد طريقة التوثيق الافتراضية (البريد الإلكتروني)
  final bool _isUsingEmail = true;

  // إضافة مرجع لخدمة المصادقة
  final AuthService _authService = AuthService();

  // Regular expressions للتحقق
  final RegExp _nameRegex = RegExp(
      r'^[a-zA-Z\u0600-\u06FF\s]{3,50}$'); // الاسم الكامل (عربي أو إنجليزي)
  final RegExp _emailRegex =
      RegExp(r'^[^@]+@[^@]+\.[^@]+$'); // تحقق بسيط من البريد الإلكتروني
  final RegExp _phoneRegex =
      RegExp(r'^[2-4]\d{7}$'); // يبدأ بـ 2,3,4 ويتكون من 8 أرقام

  @override
  void initState() {
    super.initState();
    // إضافة مستمعين للتحقق من صحة المدخلات على الفور
    _nameController.addListener(_validateInputsOnChange);
    _emailController.addListener(_validateEmailOnChange);
    _phoneController.addListener(_validatePhoneOnChange);
    _dobController.addListener(_validateInputsOnChange);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // دالة للتحقق من وجود البريد الإلكتروني في قاعدة البيانات
  Future<void> _checkEmailExists(String email) async {
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      return;
    }

    setState(() {
      _isEmailChecking = true;
      _isLoading = true;
    });

    try {
      final result = await _authService.checkUserExists(
        email,
        isEmail: true,
        userType: widget.userType,
      );

      setState(() {
        _isEmailChecking = false;
        _isLoading = false;
        _emailExists = result['exists'] ?? false;

        if (_emailExists) {
          _emailError = 'email_already_exists'.tr();
        }

        _checkFormValidity();
      });
    } catch (e) {
      setState(() {
        _isEmailChecking = false;
        _isLoading = false;
        // عدم تحديث _emailExists في حالة الخطأ للحفاظ على الحالة السابقة
        _checkFormValidity();
      });
    }
  }

  // دالة للتحقق من وجود رقم الهاتف في قاعدة البيانات
  Future<void> _checkPhoneExists(String phone) async {
    if (phone.isEmpty || !_phoneRegex.hasMatch(phone)) {
      return;
    }

    setState(() {
      _isPhoneChecking = true;
      _isLoading = true;
    });

    try {
      final result = await _authService.checkUserExists(
        phone,
        isEmail: false,
        userType: widget.userType,
      );

      setState(() {
        _isPhoneChecking = false;
        _isLoading = false;
        _phoneExists = result['exists'] ?? false;

        if (_phoneExists) {
          _phoneError = 'phone_already_exists'.tr();
        }

        _checkFormValidity();
      });
    } catch (e) {
      setState(() {
        _isPhoneChecking = false;
        _isLoading = false;
        // عدم تحديث _phoneExists في حالة الخطأ للحفاظ على الحالة السابقة
        _checkFormValidity();
      });
    }
  }

  // تعديل دالة التحقق من البريد الإلكتروني لاستدعاء التحقق من الوجود
  void _validateEmailOnChange() {
    final emailValue = _emailController.text.trim();
    if (emailValue.isEmpty) {
      setState(() {
        _emailError = 'input_required'.tr();
        _isFormValid = false;
      });
    } else if (!_emailRegex.hasMatch(emailValue)) {
      setState(() {
        _emailError = 'invalid_email'.tr();
        _isFormValid = false;
      });
    } else {
      setState(() {
        _emailError = null;
        _checkFormValidity();
      });

      // استدعاء دالة التحقق من وجود البريد الإلكتروني مع تأخير بسيط
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_emailController.text.trim() == emailValue) {
          _checkEmailExists(emailValue);
        }
      });
    }
  }

  // تعديل دالة التحقق من رقم الهاتف لاستدعاء التحقق من الوجود
  void _validatePhoneOnChange() {
    final phoneValue = _phoneController.text.trim();
    if (phoneValue.isEmpty) {
      setState(() {
        _phoneError = 'input_required'.tr();
        _isFormValid = false;
      });
    } else if (!_phoneRegex.hasMatch(phoneValue)) {
      setState(() {
        _phoneError = 'invalid_phone'.tr();
        _isFormValid = false;
      });
    } else {
      setState(() {
        _phoneError = null;
        _checkFormValidity();
      });

      // استدعاء دالة التحقق من وجود رقم الهاتف مع تأخير بسيط
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_phoneController.text.trim() == phoneValue) {
          _checkPhoneExists(phoneValue);
        }
      });
    }
  }

  // التحقق من صحة المدخلات عند تغييرها
  void _validateInputsOnChange() {
    // التحقق من الاسم الكامل
    final nameValue = _nameController.text.trim();
    if (nameValue.isEmpty) {
      setState(() {
        _nameError = 'input_required'.tr();
        _isFormValid = false;
      });
    } else if (!_nameRegex.hasMatch(nameValue)) {
      setState(() {
        _nameError = 'invalid_name'.tr();
        _isFormValid = false;
      });
    } else {
      setState(() {
        _nameError = null;
        _checkFormValidity();
      });
    }

    // التحقق من تاريخ الميلاد
    final dobValue = _dobController.text.trim();
    if (dobValue.isEmpty) {
      setState(() {
        _dobError = 'input_required'.tr();
        _isFormValid = false;
      });
    } else {
      try {
        final date = DateFormat('dd/MM/yyyy').parseStrict(dobValue);
        final now = DateTime.now();
        final minDate = DateTime(now.year - 80); // الحد الأدنى للعمر (80 سنة)
        final maxDate = DateTime(now.year - 18); // الحد الأقصى للعمر (18 سنة)

        if (date.isBefore(minDate) || date.isAfter(maxDate)) {
          setState(() {
            _dobError = 'invalid_age'.tr();
            _isFormValid = false;
          });
        } else {
          setState(() {
            _dobError = null;
            _checkFormValidity();
          });
        }
      } catch (e) {
        setState(() {
          _dobError = 'invalid_date'.tr();
          _isFormValid = false;
        });
      }
    }
  }

  // التحقق من صلاحية النموذج بأكمله
  void _checkFormValidity() {
    final nameValue = _nameController.text.trim();
    final emailValue = _emailController.text.trim();
    final phoneValue = _phoneController.text.trim();
    final dobValue = _dobController.text.trim();

    bool isNameValid = nameValue.isNotEmpty && _nameRegex.hasMatch(nameValue);
    bool isEmailValid = emailValue.isNotEmpty &&
        _emailRegex.hasMatch(emailValue) &&
        !_emailExists;
    bool isPhoneValid = phoneValue.isNotEmpty &&
        _phoneRegex.hasMatch(phoneValue) &&
        !_phoneExists;

    bool isDobValid = false;
    if (dobValue.isNotEmpty) {
      try {
        final date = DateFormat('dd/MM/yyyy').parseStrict(dobValue);
        final now = DateTime.now();
        final minDate = DateTime(now.year - 80);
        final maxDate = DateTime(now.year - 18);
        isDobValid = !date.isBefore(minDate) && !date.isAfter(maxDate);
      } catch (e) {
        isDobValid = false;
      }
    }

    bool isChecking = _isEmailChecking || _isPhoneChecking;

    setState(() {
      _isFormValid = isNameValid &&
          isEmailValid &&
          isPhoneValid &&
          isDobValid &&
          !isChecking;
    });
  }

  // دالة لإرسال رمز التحقق والانتقال إلى صفحة التحقق
  Future<void> _sendOTPAndNavigate() async {
    if (!_isFormValid || _isLoading) {
      debugPrint('Form is not valid or is already loading');
      // عرض رسالة للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تحقق من صحة البيانات المدخلة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isSendingOTP = true;
    });

    debugPrint('Starting OTP process...');

    try {
      // استخدام البريد الإلكتروني دائمًا كوسيلة أساسية للتحقق
      String identifier = _emailController.text.trim();
      bool isEmail = true;

      // تحضير تاريخ الميلاد
      String birthDate = _dobController.text.trim();

      debugPrint(
          'Sending OTP request with: $identifier (isEmail: $isEmail), userType: ${widget.userType}, fullName: ${_nameController.text.trim()}, birthDate: $birthDate');

      // استخدام OTPService بدلاً من AuthService لإرسال رمز التحقق
      final result = await OTPService.sendRegistrationOTPByEmail(
        email: identifier,
        userType: widget.userType,
        fullName: _nameController.text.trim(),
        birthDate: birthDate,
        isInitialRequest: true,
      );

      debugPrint('OTP result: $result');

      setState(() {
        _isLoading = false;
        _isSendingOTP = false;
      });

      if (result['success']) {
        debugPrint('OTP sent successfully, navigating to verification page');
        // الانتقال إلى صفحة التحقق
        if (!mounted) return;

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                CodeVerification(
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              userType: widget.userType,
              fullName: _nameController.text.trim(),
              dob: _dobController.text.trim(),
              isUsingEmail: true,
              // إرسال رمز التحقق المولد محليًا إلى صفحة التحقق
              otpCode: result['data']?['otp'] ?? '',
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
      } else {
        // عرض رسالة الخطأ
        debugPrint('Failed to send OTP: ${result['message']}');
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'].toString().tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during OTP send process: $e');
      setState(() {
        _isLoading = false;
        _isSendingOTP = false;
      });

      if (!mounted) return;

      // عرض رسالة الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_unexpected'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // عرض منتقي التاريخ
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime lastDate = DateTime(now.year - 18, now.month, now.day);
    final DateTime firstDate = DateTime(now.year - 80, now.month, now.day);
    final DateTime initialDate =
        DateTime(now.year - 30, now.month, now.day); // تاريخ افتراضي مناسب

    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );

      if (picked != null) {
        setState(() {
          // تنسيق التاريخ بصيغة مناسبة للعرض
          _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
        });
        _validateInputsOnChange();
      }
    } catch (e) {
      // التعامل مع الأخطاء
      debugPrint('Error selecting date: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على حجم الشاشة للتجاوب مع مختلف الأجهزة
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF2F9C95),
        body: SafeArea(
          // استخدام SingleChildScrollView داخل Expanded يضمن توسيع المحتوى بشكل صحيح
          bottom: false,
          child: Column(
            children: [
              // منطقة الشعار العلوية
              SizedBox(height: screenHeight * 0.02),
              // Logo
              SizedBox(
                height: screenHeight * 0.12,
                child: Center(
                  child: Image.asset(
                    'assets/images/Groupes@4x.png',
                    width: screenWidth * 0.25,
                    height: screenWidth * 0.25,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),

              // Main Content Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: Stack(
                    children: [
                      // استخدام SingleChildScrollView داخل منطقة المحتوى
                      SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              screenWidth * 0.04,
                              screenHeight * 0.02,
                              screenWidth * 0.04,
                              screenHeight * 0.1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Center(
                                  child: Text(
                                'create_account'.tr(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                              SizedBox(height: screenHeight * 0.01),
                              // Subtitles
                              Text(
                                'start_journey'.tr(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'closer_with_twsil'.tr(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // Form with Steps
                              Stack(
                                children: [
                                  // Steps Line
                                  Positioned(
                                    right: context.locale.languageCode == 'ar'
                                        ? screenWidth * 0.05
                                        : null,
                                    left: context.locale.languageCode != 'ar'
                                        ? screenWidth * 0.05
                                        : null,
                                    top: screenHeight * 0.04,
                                    bottom: screenHeight * 0.1,
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
                                          Container(
                                            width: screenWidth * 0.1,
                                            height: screenWidth * 0.1,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2F9C95),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.person_outline,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.03),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'step1'.tr(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: screenWidth * 0.04,
                                                ),
                                              ),
                                              Text(
                                                'personal_info'.tr(),
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: screenWidth * 0.035,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.015),

                                      // Input Fields
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: context.locale.languageCode ==
                                                  'ar'
                                              ? 0
                                              : screenWidth * 0.13,
                                          right: context.locale.languageCode ==
                                                  'ar'
                                              ? screenWidth * 0.13
                                              : 0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              context.locale.languageCode ==
                                                      'ar'
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                          children: [
                                            _buildInputField(
                                              controller: _nameController,
                                              icon: Icons.person_outline,
                                              hint: 'full_name'.tr(),
                                              error: _nameError,
                                            ),
                                            _buildInputField(
                                              controller: _emailController,
                                              icon: Icons.email_outlined,
                                              hint: 'email'.tr(),
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              error: _emailError,
                                            ),
                                            _buildInputField(
                                              controller: _phoneController,
                                              icon: Icons.phone_outlined,
                                              hint: 'phone_number'.tr(),
                                              keyboardType: TextInputType.phone,
                                              error: _phoneError,
                                            ),
                                            _buildDateField(
                                              controller: _dobController,
                                              icon:
                                                  Icons.calendar_today_outlined,
                                              hint: 'birth_date'.tr(),
                                              error: _dobError,
                                              onTap: () => _selectDate(context),
                                            ),
                                            SizedBox(
                                                height: screenHeight * 0.01),
                                            // Continue Button
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFF2F9C95),
                                                  disabledBackgroundColor:
                                                      Colors.grey[400],
                                                  padding: EdgeInsets.symmetric(
                                                      vertical:
                                                          screenHeight * 0.015),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                onPressed:
                                                    _isFormValid && !_isLoading
                                                        ? _sendOTPAndNavigate
                                                        : null,
                                                child: _isSendingOTP
                                                    ? const SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : Text(
                                                        'continue_button'.tr(),
                                                        style: TextStyle(
                                                          fontSize:
                                                              screenWidth *
                                                                  0.04,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.015),

                                      // Step 2
                                      Row(
                                        children: [
                                          Container(
                                            width: screenWidth * 0.1,
                                            height: screenWidth * 0.1,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.shield_outlined,
                                              color: Colors.grey[400],
                                              size: screenWidth * 0.05,
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.03),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'step2'.tr(),
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: screenWidth * 0.04,
                                                ),
                                              ),
                                              Text(
                                                'verify_code'.tr(),
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: screenWidth * 0.035,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.015),

                                      // Step 3
                                      Row(
                                        children: [
                                          Container(
                                            width: screenWidth * 0.1,
                                            height: screenWidth * 0.1,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.lock_outline,
                                              color: Colors.grey[400],
                                              size: screenWidth * 0.05,
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.03),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'step3'.tr(),
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: screenWidth * 0.04,
                                                ),
                                              ),
                                              Text(
                                                'create_password'.tr(),
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: screenWidth * 0.035,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // إضافة زر المتابعة
                                      SizedBox(height: screenHeight * 0.03),

                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: context.locale.languageCode ==
                                                  'ar'
                                              ? 0
                                              : screenWidth * 0.13,
                                          right: context.locale.languageCode ==
                                                  'ar'
                                              ? screenWidth * 0.13
                                              : 0,
                                        ),
                                        child: Container(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Logo - أصبحت مثبتة في الأسفل بشكل صحيح
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                          color: Colors.white,
                          child: Center(
                            child: Image.asset(
                              "assets/images/Rectangle@4x.png",
                              height: screenHeight * 0.04,
                              width: screenWidth * 0.1,
                              fit: BoxFit.contain,
                            ),
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
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? error,
  }) {
    bool isCheckingField = (hint == 'email'.tr() && _isEmailChecking) ||
        (hint == 'phone_number'.tr() && _isPhoneChecking);

    // تحديد لون مختلف للحقل استنادًا إلى كونه البريد المستخدم للتحقق
    Color fieldColor = const Color(0xFF2F9C95);
    if (hint == 'email'.tr() && _isUsingEmail) {
      fieldColor = Colors.blue; // إبراز البريد كوسيلة تحقق
    } else if (hint == 'phone_number'.tr() && !_isUsingEmail) {
      fieldColor = Colors.blue; // إبراز الهاتف كوسيلة تحقق
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              filled: true,
              fillColor: Colors.grey[100],
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              prefixIcon: Icon(icon, color: fieldColor, size: 20),
              suffixIcon: isCheckingField
                  ? Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(8),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2F9C95),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              errorText: error,
            ),
            onChanged: (_) {
              if (hint == 'email'.tr()) {
                _validateEmailOnChange();
              } else if (hint == 'phone_number'.tr()) {
                _validatePhoneOnChange();
              } else {
                _validateInputsOnChange();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required VoidCallback onTap,
    String? error,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              filled: true,
              fillColor: Colors.grey[100],
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFF2F9C95), size: 20),
              suffixIcon:
                  const Icon(Icons.calendar_today, color: Color(0xFF2F9C95)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              errorText: error,
            ),
          ),
        ],
      ),
    );
  }
}
