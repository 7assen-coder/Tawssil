import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'homepage.dart';

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({Key? key}) : super(key: key);

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
                        'Password_reset'.tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Stack(
                        children: [
                          Positioned(
                            left:
                                context.locale.languageCode == 'ar' ? null : 19,
                            right:
                                context.locale.languageCode == 'ar' ? 19 : null,
                            top: 20,
                            bottom: 80,
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
                                    child: const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFF2F9C95),
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
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Processing_method'.tr(),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'success_completed'.tr(),
                                        style: const TextStyle(
                                          color: Color(0xFF2F9C95),
                                          fontSize: 12,
                                        ),
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
                                    child: const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFF2F9C95),
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
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'verify_code'.tr(),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'success_completed'.tr(),
                                        style: const TextStyle(
                                          color: Color(0xFF2F9C95),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    child: const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFF2F9C95),
                                      child: Text(
                                        '3',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'step3'.tr(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'create_Npassword'.tr(),
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                        ),
                                        const SizedBox(height: 15),
                                        Column(
                                          key:
                                              const ValueKey('password_inputs'),
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        Colors.grey.shade300),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: TextField(
                                                controller: _passwordController,
                                                obscureText: _obscurePassword,
                                                textAlign: context.locale
                                                            .languageCode ==
                                                        'ar'
                                                    ? TextAlign.right
                                                    : TextAlign.left,
                                                decoration: InputDecoration(
                                                  hintText: 'password'.tr(),
                                                  hintStyle: const TextStyle(
                                                      color: Colors.grey),
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 12,
                                                    vertical:
                                                        16, // This controls vertical alignment
                                                  ),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(_obscurePassword
                                                        ? Icons.visibility_off
                                                        : Icons.visibility),
                                                    onPressed: () {
                                                      setState(() {
                                                        _obscurePassword =
                                                            !_obscurePassword;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        Colors.grey.shade300),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: TextField(
                                                controller:
                                                    _confirmPasswordController,
                                                obscureText:
                                                    _obscureConfirmPassword,
                                                textAlign: context.locale
                                                            .languageCode ==
                                                        'ar'
                                                    ? TextAlign.right
                                                    : TextAlign.left,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'confirm_password'.tr(),
                                                  hintStyle: const TextStyle(
                                                      color: Colors.grey),
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 16),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                        _obscureConfirmPassword
                                                            ? Icons
                                                                .visibility_off
                                                            : Icons.visibility),
                                                    onPressed: () {
                                                      setState(() {
                                                        _obscureConfirmPassword =
                                                            !_obscureConfirmPassword;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
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
                                                      const HomePage(),
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
                        ],
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
}
