import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'code.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  bool showEmailInput = false;
  bool showPhoneInput = false;
  String selectedMethod = ''; // To track which method was selected
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
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
              // Main Content Container
              Container(
                height: MediaQuery.of(context).size.height * 0.7,
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
                            'Password_reset'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )),

                          // Subtitles
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
                                  const SizedBox(height: 10),

                                  // Input Fields or Buttons
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
                                        if (!showEmailInput && !showPhoneInput)
                                          Column(
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  setState(() {
                                                    showPhoneInput = true;
                                                    selectedMethod = 'phone';
                                                  });
                                                },
                                                icon: Icon(
                                                  Icons.phone,
                                                  color: Colors.white,
                                                ),
                                                label: Text(
                                                  'To_Num'.tr(),
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  minimumSize:
                                                      Size(double.infinity, 50),
                                                  backgroundColor:
                                                      const Color(0xFF2F9C95),
                                                ),
                                              ),
                                              SizedBox(height: 12),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  setState(() {
                                                    showEmailInput = true;
                                                    selectedMethod = 'email';
                                                  });
                                                },
                                                icon: Icon(Icons.email,
                                                    color: Colors.white),
                                                label: Text(
                                                  'To_Email'.tr(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  minimumSize:
                                                      Size(double.infinity, 50),
                                                  backgroundColor:
                                                      const Color(0xFF2F9C95),
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (showPhoneInput)
                                          TextField(
                                            controller: phoneController,
                                            decoration: InputDecoration(
                                              labelText: 'phone_number'.tr(),
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.phone),
                                            ),
                                            keyboardType: TextInputType.phone,
                                          ),
                                        if (showEmailInput)
                                          TextField(
                                            controller: emailController,
                                            decoration: InputDecoration(
                                              labelText: 'email'.tr(),
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.email),
                                            ),
                                            keyboardType:
                                                TextInputType.emailAddress,
                                          ),
                                        if (showEmailInput || showPhoneInput)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 16),
                                            child: ElevatedButton(
                                              onPressed: () {
                                                // Validate and send code
                                                if (selectedMethod == 'email' &&
                                                    emailController
                                                        .text.isEmpty) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                          content: Text(
                                                              'Please enter your email')));
                                                  return;
                                                }
                                                if (selectedMethod == 'phone' &&
                                                    phoneController
                                                        .text.isEmpty) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                          content: Text(
                                                              'Please enter your phone number')));
                                                  return;
                                                }

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const CodePage()),
                                                );
                                              },
                                              child: Text('Send_Code'.tr()),
                                              style: ElevatedButton.styleFrom(
                                                minimumSize:
                                                    Size(double.infinity, 50),
                                                backgroundColor:
                                                    const Color(0xFF2F9C95),
                                              ),
                                            ),
                                          ),
                                        if (showEmailInput || showPhoneInput)
                                          Align(
                                            alignment:
                                                context.locale.languageCode ==
                                                        'ar'
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    showEmailInput = false;
                                                    showPhoneInput = false;
                                                    selectedMethod = '';
                                                  });
                                                },
                                                child: Text(
                                                  'change_method'.tr(),
                                                  style: TextStyle(
                                                      color: Color.fromARGB(
                                                          205, 2, 2, 2)),
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
                                        height: 40,
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.grey[200],
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
                                            'create_Npassword'.tr(),
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
}
