import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

class LanguageSelectionDialog extends StatefulWidget {
  final Function() onLanguageSelected;

  const LanguageSelectionDialog({
    super.key,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionDialog> createState() =>
      _LanguageSelectionDialogState();
}

class _LanguageSelectionDialogState extends State<LanguageSelectionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  int _selectedLanguageIndex = -1; // لتتبع اللغة المحددة

  // تعريف رموز SVG للأعلام
  final String _mauritaniaFlagSvg = '''
<svg width="800" height="600" viewBox="0 0 800 600" xmlns="http://www.w3.org/2000/svg">
  <rect width="800" height="600" fill="#006233"/>
  <path d="M400 110C315 110 245 180 245 265C245 350 315 420 400 420C485 420 555 350 555 265C555 180 485 110 400 110ZM400 370C345 370 300 325 300 270C300 215 345 170 400 170C455 170 500 215 500 270C500 325 455 370 400 370Z" fill="#FFCE08"/>
  <path d="M400 190L425 270H380L405 190Z" fill="#FFCE08"/>
  <path d="M400 140C340 140 290 190 290 250C290 310 340 360 400 360C460 360 510 310 510 250C510 190 460 140 400 140Z" fill="#006233"/>
  <path d="M400 160C350 160 310 200 310 250C310 300 350 340 400 340C450 340 490 300 490 250C490 200 450 160 400 160Z" fill="#FFCE08"/>
</svg>
  ''';

  final String _ukFlagSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 30">
  <clipPath id="a"><path d="M0 0v30h60V0z"/></clipPath>
  <clipPath id="b"><path d="M30 15h30v15zv15H0zH0V0zV0h30z"/></clipPath>
  <g clip-path="url(#a)">
    <path d="M0 0v30h60V0z" fill="#012169"/>
    <path d="M0 0l60 30m0-30L0 30" stroke="#fff" stroke-width="6"/>
    <path d="M0 0l60 30m0-30L0 30" clip-path="url(#b)" stroke="#C8102E" stroke-width="4"/>
    <path d="M30 0v30M0 15h60" stroke="#fff" stroke-width="10"/>
    <path d="M30 0v30M0 15h60" stroke="#C8102E" stroke-width="6"/>
  </g>
</svg>
  ''';

  final String _franceFlagSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 600">
  <rect width="900" height="600" fill="#ED2939"/>
  <rect width="600" height="600" fill="#fff"/>
  <rect width="300" height="600" fill="#002395"/>
</svg>
  ''';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // بدء الرسوم المتحركة
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // دالة لإنشاء علم من سلسلة SVG
  Widget _buildFlag(String svgString, {double width = 30, double height = 20}) {
    return SvgPicture.string(
      svgString,
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // طبقة الخلفية الزجاجية
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
            ),

            // المحتوى الرئيسي
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.fromLTRB(25, 25, 25, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // لوجو التطبيق
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F9C95).withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2F9C95).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/Groupes@4x.png',
                        height: 80,
                        width: 80,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // عنوان
                    const Text(
                      'اختر لغة التطبيق',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F9C95),
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Choose your language',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Choisissez votre langue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 25),

                    // فاصل زخرفي
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F9C95).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // خيارات اللغة
                    _buildLanguageOption(
                      context: context,
                      flagWidget:
                          _buildFlag(_mauritaniaFlagSvg, width: 30, height: 20),
                      language: 'العربية',
                      locale: 'ar',
                      index: 0,
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      context: context,
                      flagWidget: _buildFlag(_ukFlagSvg, width: 30, height: 20),
                      language: 'English',
                      locale: 'en',
                      index: 1,
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      context: context,
                      flagWidget:
                          _buildFlag(_franceFlagSvg, width: 30, height: 20),
                      language: 'Français',
                      locale: 'fr',
                      index: 2,
                    ),

                    const SizedBox(height: 25),

                    // زر المتابعة
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _selectedLanguageIndex >= 0
                            ? () {
                                // تنفيذ وظيفة تغيير اللغة قبل أي تأخير لتجنب مشاكل BuildContext
                                switch (_selectedLanguageIndex) {
                                  case 0:
                                    context.setLocale(const Locale('ar'));
                                    break;
                                  case 1:
                                    context.setLocale(const Locale('en'));
                                    break;
                                  case 2:
                                    context.setLocale(const Locale('fr'));
                                    break;
                                }

                                // إغلاق الحوار وتنفيذ الدالة المرتبطة
                                Navigator.of(context).pop();
                                widget.onLanguageSelected();
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: _selectedLanguageIndex >= 0
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF2F9C95),
                                      Color(0xFF2A8A84),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.shade400,
                                      Colors.grey.shade500,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedLanguageIndex >= 0
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2F9C95)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _selectedLanguageIndex >= 0
                                  ? const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'متابعة',
                                          style:  TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                         SizedBox(width: 8),
                                         Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'اختر لغة',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
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
    );
  }

  // بناء خيار اللغة مع العلم
  Widget _buildLanguageOption({
    required BuildContext context,
    required Widget flagWidget,
    required String language,
    required String locale,
    required int index,
  }) {
    final isSelected = _selectedLanguageIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLanguageIndex = index;
          });

          // تعطيل تأثير الاهتزاز عند النقر
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 60,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2F9C95).withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFF2F9C95) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2F9C95).withOpacity(0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            children: [
              // علم البلد
              Container(
                width: 40,
                height: 30,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: flagWidget,
                ),
              ),
              const SizedBox(width: 15),

              // اسم اللغة
              Text(
                language,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF2F9C95) : Colors.black87,
                ),
              ),

              const Spacer(),

              // علامة اختيار للعنصر المحدد
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F9C95),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
