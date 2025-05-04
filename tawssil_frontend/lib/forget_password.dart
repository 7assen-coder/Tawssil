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

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF2F9C95),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
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
                                                    onPressed: () {
                                                      // Validate and send code
                                                      if (selectedMethod ==
                                                          'email') {
                                                        validateEmail(
                                                            emailController
                                                                .text);
                                                        if (emailError !=
                                                            null) {
                                                          return;
                                                        }
                                                      }
                                                      if (selectedMethod ==
                                                          'phone') {
                                                        validatePhone(
                                                            phoneController
                                                                .text);
                                                        if (phoneError !=
                                                            null) {
                                                          return;
                                                        }
                                                      }

                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    CodePage(
                                                                      phoneNumber: selectedMethod ==
                                                                              'phone'
                                                                          ? phoneController
                                                                              .text
                                                                          : null,
                                                                      email: selectedMethod ==
                                                                              'email'
                                                                          ? emailController
                                                                              .text
                                                                          : null,
                                                                    )),
                                                      );
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
                                                    ),
                                                    child: Text(
                                                      'Send_Code'.tr(),
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
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
