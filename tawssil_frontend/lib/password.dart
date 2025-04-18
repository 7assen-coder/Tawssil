import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'selfie.dart';

class Password extends StatefulWidget {
  const Password({super.key});

  @override
  State<Password> createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showProgress = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F9C95),
      body: SafeArea(
        child: Column(
          children: [
            // اختيار اللغة
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<String>(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

            // الشعار مع المسافة الصحيحة
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

            // الحاوية الرئيسية
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Stack(
                  children: [
                    // المحتوى الرئيسي
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // العنوان والعنوان الفرعي
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

                          // الخطوات والمحتوى
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // الخط العمودي
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

                                // الخطوات والمحتوى
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // الخطوة 1
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
                                                    fontWeight:
                                                        FontWeight.bold),
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

                                      // الخطوة 2
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
                                                    fontWeight:
                                                        FontWeight.bold),
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

                                      // الخطوة 3 (نشطة الآن) مع حقول الإدخال متحاذية معها
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // أيقونة الخطوة 3
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
                                          // عمود يحتوي على وصف الخطوة 3 وحقول كلمة المرور
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // عنوان ووصف الخطوة 3
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

                                                // عرض إما حقول الإدخال أو مؤشر التقدم باستخدام انتقال احترافي
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
                                                        ).animate(
                                                            CurvedAnimation(
                                                          parent: animation,
                                                          curve: Curves
                                                              .easeOutCubic,
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
                                                            // حقل كلمة المرور
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border.all(
                                                                    color: Colors
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
                                                                obscureText:
                                                                    _obscurePassword,
                                                                textAlign: context
                                                                            .locale
                                                                            .languageCode ==
                                                                        'ar'
                                                                    ? TextAlign
                                                                        .right
                                                                    : TextAlign
                                                                        .left,
                                                                decoration:
                                                                    InputDecoration(
                                                                  hintText:
                                                                      'password'
                                                                          .tr(),
                                                                  hintStyle: const TextStyle(
                                                                      color: Colors
                                                                          .grey),
                                                                  border:
                                                                      InputBorder
                                                                          .none,
                                                                  contentPadding:
                                                                      const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              12),
                                                                  suffixIcon:
                                                                      IconButton(
                                                                    icon: Icon(_obscurePassword
                                                                        ? Icons
                                                                            .visibility_off
                                                                        : Icons
                                                                            .visibility),
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        _obscurePassword =
                                                                            !_obscurePassword;
                                                                      });
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 15),
                                                            // حقل تأكيد كلمة المرور
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border.all(
                                                                    color: Colors
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
                                                                obscureText:
                                                                    _obscureConfirmPassword,
                                                                textAlign: context
                                                                            .locale
                                                                            .languageCode ==
                                                                        'ar'
                                                                    ? TextAlign
                                                                        .right
                                                                    : TextAlign
                                                                        .left,
                                                                decoration:
                                                                    InputDecoration(
                                                                  hintText:
                                                                      'confirm_password'
                                                                          .tr(),
                                                                  hintStyle: const TextStyle(
                                                                      color: Colors
                                                                          .grey),
                                                                  border:
                                                                      InputBorder
                                                                          .none,
                                                                  contentPadding:
                                                                      const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              12),
                                                                  suffixIcon:
                                                                      IconButton(
                                                                    icon: Icon(_obscureConfirmPassword
                                                                        ? Icons
                                                                            .visibility_off
                                                                        : Icons
                                                                            .visibility),
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        _obscureConfirmPassword =
                                                                            !_obscureConfirmPassword;
                                                                      });
                                                                    },
                                                                  ),
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
                                                                    child: TweenAnimationBuilder<
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
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                ),

                                                const SizedBox(height: 20),

                                                // زر متابعة (يظهر دائماً)
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _showProgress = true;
                                                    });

                                                    // إضافة تأخير قصير لإظهار التأثير الانتقالي قبل الانتقال للصفحة التالية
                                                    Future.delayed(
                                                        const Duration(
                                                            milliseconds: 1500),
                                                        () {
                                                      Navigator.push(
                                                        context,
                                                        PageRouteBuilder(
                                                          pageBuilder: (context,
                                                                  animation,
                                                                  secondaryAnimation) =>
                                                              const SelfieScreen(),
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
                                                    });
                                                  },
                                                  child: Container(
                                                    width: double.infinity,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF2F9C95),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'continue'.tr(),
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

                                      // شعار أسفل الصفحة
                                      Center(
                                        child: Image.asset(
                                          'assets/images/Rectangle@4x.png',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
