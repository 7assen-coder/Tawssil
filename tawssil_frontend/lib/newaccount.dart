import 'package:flutter/material.dart';
import 'codeverification.dart';
import 'package:easy_localization/easy_localization.dart';

class NewAccount extends StatefulWidget {
  const NewAccount({super.key});

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
    _emailController.addListener(_validateInputsOnChange);
    _phoneController.addListener(_validateInputsOnChange);
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

    // التحقق من البريد الإلكتروني
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
    }

    // التحقق من رقم الهاتف
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
    bool isEmailValid =
        emailValue.isNotEmpty && _emailRegex.hasMatch(emailValue);
    bool isPhoneValid =
        phoneValue.isNotEmpty && _phoneRegex.hasMatch(phoneValue);

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

    setState(() {
      _isFormValid = isNameValid && isEmailValid && isPhoneValid && isDobValid;
    });
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
              const SizedBox(height: 20),
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/Groupes@4x.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 20),

              // Main Content Container
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Center(
                              child: Text(
                            'create_account'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                          const SizedBox(height: 8),
                          // Subtitles
                          Text(
                            'start_journey'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'closer_with_twsil'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),

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
                                bottom: 100,
                                child: Container(
                                  width: 2,
                                  color: const Color(0xFF2F9C95),
                                ),
                              ),
                              // Content
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Step 1 with inputs
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
                                          Icons.person_outline,
                                          color: Colors.white,
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
                                            'personal_info'.tr(),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Input Fields
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: context.locale.languageCode == 'ar'
                                          ? 0
                                          : 52,
                                      right: context.locale.languageCode == 'ar'
                                          ? 52
                                          : 0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          context.locale.languageCode == 'ar'
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
                                          icon: Icons.calendar_today_outlined,
                                          hint: 'birth_date'.tr(),
                                          error: _dobError,
                                          onTap: () => _selectDate(context),
                                        ),
                                        const SizedBox(height: 10),
                                        // Continue Button
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF2F9C95),
                                              disabledBackgroundColor:
                                                  Colors.grey[400],
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: _isFormValid
                                                ? () {
                                                    Navigator.push(
                                                      context,
                                                      PageRouteBuilder(
                                                        pageBuilder: (context,
                                                                animation,
                                                                secondaryAnimation) =>
                                                            CodeVerification(
                                                          email:
                                                              _emailController
                                                                  .text
                                                                  .trim(),
                                                          phone:
                                                              _phoneController
                                                                  .text
                                                                  .trim(),
                                                        ),
                                                        transitionsBuilder:
                                                            (context,
                                                                animation,
                                                                secondaryAnimation,
                                                                child) {
                                                          const begin =
                                                              Offset(0.0, -1.0);
                                                          const end =
                                                              Offset.zero;
                                                          const curve =
                                                              Curves.easeInOut;

                                                          var tween = Tween(
                                                                  begin: begin,
                                                                  end: end)
                                                              .chain(CurveTween(
                                                                  curve:
                                                                      curve));
                                                          var offsetAnimation =
                                                              animation
                                                                  .drive(tween);

                                                          return FadeTransition(
                                                            opacity: animation,
                                                            child:
                                                                SlideTransition(
                                                              position:
                                                                  offsetAnimation,
                                                              child: child,
                                                            ),
                                                          );
                                                        },
                                                        transitionDuration:
                                                            const Duration(
                                                                milliseconds:
                                                                    400),
                                                      ),
                                                    );
                                                  }
                                                : null,
                                            child: Text(
                                              'continue'.tr(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Step 2
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.shield_outlined,
                                          color: Colors.grey[400],
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
                                  const SizedBox(height: 10),

                                  // Step 3
                                  Row(
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
                                            ),
                                          ),
                                          Text(
                                            'create_password'.tr(),
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 60),
                                ],
                              ),
                            ],
                          ),
                        ],
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
              prefixIcon: Icon(icon, color: const Color(0xFF2F9C95), size: 20),
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
            onChanged: (_) => _validateInputsOnChange(),
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
