import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SelfieScreen extends StatefulWidget {
  const SelfieScreen({super.key});

  @override
  State<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen> {
  bool _showImageOptions = false;

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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    children: [
                      // العنوان
                      Text(
                        'choose_profile_picture'.tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // صورة الملف الشخصي الافتراضية
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE57353),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_outline,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),

                      // خيارات الصورة
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.2),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            ),
                          );
                        },
                        child: !_showImageOptions
                            ? Column(
                                key: const ValueKey('main_options'),
                                children: [
                                  // زر التقاط صورة الآن
                                  InkWell(
                                    onTap: () {
                                      // التقاط صورة
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE57353),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'take_photo_now'.tr(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // زر اختيار صورة
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _showImageOptions = true;
                                      });
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE57353),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'choose_image'.tr(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey('sub_options'),
                                children: [
                                  // زر اختيار من المعرض
                                  InkWell(
                                    onTap: () {
                                      // اختيار من المعرض
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE57353),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'choose_from_gallery'.tr(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // زر اختيار من الملفات
                                  InkWell(
                                    onTap: () {
                                      // اختيار من الملفات
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE57353),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'choose_from_files'.tr(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // زر الرجوع
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _showImageOptions = false;
                                      });
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'back'.tr(),
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const Spacer(),

                      // شعار أسفل الصفحة
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Center(
                          child: Image.asset(
                            'assets/images/Rectangle@4x.png',
                            height: 40,
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
    );
  }
}
