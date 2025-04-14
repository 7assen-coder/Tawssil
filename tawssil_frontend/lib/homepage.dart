import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool showLogin = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    bool isRTL = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF2AAF7F),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: showLogin ? _buildLoginPage(isRTL) : _buildAnimation(),
        ),
      ),
    );
  }

  Widget _buildAnimation() {
    return Container(
      color: const Color(0xFF2A9D8F),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // شعار التطبيق مع تأثير ظهور تدريجي
            TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 2),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: value,
                    child: Image.asset(
                      'assets/images/Groupes@4x.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            // رسوم متحركة للتحميل
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.network(
                'https://lottie.host/704d7228-b25f-4aa5-960d-bd8b66a6257c/vaWOhNBobl.json',
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
                frameRate:
                    const FrameRate(60), // معدل إطارات أعلى للحركة الأكثر سلاسة
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPage(bool isRTL) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              color: const Color(0xFF2A9D8F),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Language Selector
                  Align(
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
                  const SizedBox(height: 20),
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/Groupes@4x.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        Text(
                          'login'.tr(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: isRTL
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isRTL
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                'welcome'.tr(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'description'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                                textAlign:
                                    isRTL ? TextAlign.right : TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(
                            hintText: 'phone_email'.tr(),
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            hintText: 'password'.tr(),
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'forgot_password'.tr(),
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text(
                              'login_button'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'new_account'.tr(),
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Image.asset(
                            'assets/images/Rectangle@4x.png',
                            width: 80,
                            height: 80,
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
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // زيادة مدة التلاشي
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // زيادة مدة عرض الرسوم المتحركة إلى 10 ثوانٍ
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          showLogin = true;
        });
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
