import 'package:flutter/material.dart';
import 'codeverification.dart';
import 'package:easy_localization/easy_localization.dart';

class NewAccount extends StatelessWidget {
  const NewAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F9C95),
      body: SafeArea(
        child: SingleChildScrollView(
          // Added SingleChildScrollView
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
                                        _buildInput(Icons.person_outline,
                                            'full_name'.tr()),
                                        _buildInput(
                                            Icons.email_outlined, 'email'.tr()),
                                        _buildInput(Icons.phone_outlined,
                                            'phone_number'.tr()),
                                        _buildInput(
                                            Icons.calendar_today_outlined,
                                            'birth_date'.tr()),
                                        const SizedBox(height: 10),
                                        // Continue Button
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF2F9C95),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (context,
                                                          animation,
                                                          secondaryAnimation) =>
                                                      const CodeVerification(),
                                                  transitionsBuilder: (context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child) {
                                                    const begin =
                                                        Offset(0.0, -1.0);
                                                    const end = Offset.zero;
                                                    const curve =
                                                        Curves.easeInOut;

                                                    var tween = Tween(
                                                            begin: begin,
                                                            end: end)
                                                        .chain(CurveTween(
                                                            curve: curve));
                                                    var offsetAnimation =
                                                        animation.drive(tween);

                                                    return FadeTransition(
                                                      opacity: animation,
                                                      child: SlideTransition(
                                                        position:
                                                            offsetAnimation,
                                                        child: child,
                                                      ),
                                                    );
                                                  },
                                                  transitionDuration:
                                                      const Duration(
                                                          milliseconds: 400),
                                                ),
                                              );
                                            },
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

  Widget _buildInput(IconData icon, String hint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        decoration: InputDecoration(
          icon: Icon(
            icon,
            color: Colors.grey[600],
            size: 20,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}
