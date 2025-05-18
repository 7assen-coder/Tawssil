import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'homeapp.dart';
import 'services/auth_service.dart';

class Selfie extends StatefulWidget {
  final String userType;
  final String email;
  final String phone;
  final String fullName;
  final String dob;
  final String password;

  const Selfie({
    super.key,
    required this.userType,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.dob,
    required this.password,
  });

  @override
  State<Selfie> createState() => _SelfieState();
}

class _SelfieState extends State<Selfie> {
  bool _showImageOptions = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isCreatingAccount = false;
  bool _showSuccessAnimation = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // طلب الأذونات اللازمة
  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
    await Permission.storage.request();

    if (Platform.isIOS) {
      await Permission.locationWhenInUse.request();
    } else if (Platform.isAndroid) {
      await Permission.location.request();
    }
  }

  // التقاط صورة من الكاميرا
  Future<void> _takePhoto() async {
    // التحقق من إذن الكاميرا
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        _showErrorDialog('camera_permission_denied'.tr());
        return;
      }
    }

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      _showErrorDialog('error_camera_access'.tr());
    }
  }

  // اختيار صورة من المعرض
  Future<void> _pickImageFromGallery() async {
    // التحقق من إذن المعرض
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
      if (!status.isGranted) {
        _showErrorDialog('gallery_permission_denied'.tr());
        return;
      }
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('error_gallery_access'.tr());
    }
  }

  // اختيار ملف
  Future<void> _pickFile() async {
    // التحقق من إذن الملفات
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        _showErrorDialog('storage_permission_denied'.tr());
        return;
      }
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showErrorDialog('error_file_access'.tr());
    }
  }

  // إظهار رسالة خطأ
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('error'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  // إنشاء الحساب باستخدام الصورة المحددة
  Future<void> _createAccountWithImage() async {
    if (mounted) {
      setState(() {
        _isCreatingAccount = true;
      });
    }

    try {
      // إعداد بيانات التسجيل
      final userData = {
        'user_type': widget.userType,
        'full_name': widget.fullName,
        'email': widget.email,
        'phone': widget.phone,
        'birth_date': widget.dob,
        'password': widget.password,
      };

      // إنشاء طلب متعدد الأجزاء
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthService.baseUrl}/api/complete-registration/'),
      );

      // إضافة بيانات المستخدم
      request.fields.addAll(userData);

      // إضافة الصورة إذا تم اختيارها
      if (_selectedImage != null && _selectedImage!.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            _selectedImage!.path,
          ),
        );
      } else {
        // إضافة علامة لاستخدام الصورة الافتراضية
        request.fields['use_default_image'] = 'true';
      }

      // إرسال الطلب
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var decodedResponse = json.decode(responseData);

      // إظهار رسومات نجاح إنشاء الحساب
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isCreatingAccount = false;
            _showSuccessAnimation = true;
          });
        }

        // الانتظار قليلاً لإظهار رسومات النجاح ثم الانتقال إلى الشاشة الرئيسية
        await Future.delayed(const Duration(seconds: 3));

        if (mounted) {
          // الانتقال إلى الشاشة الرئيسية مع إرسال بيانات المستخدم
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeApp(
                userIdentifier:
                    widget.email.isNotEmpty ? widget.email : widget.phone,
                userData: User(
                  id: 0,
                  username: widget.fullName,
                  email: widget.email,
                  phone: widget.phone,
                  userType: widget.userType,
                  isStaff: false,
                  token: '',
                ),
              ),
            ),
            (route) => false, // إزالة جميع الشاشات السابقة
          );
        }
      } else {
        // إظهار رسالة خطأ
        if (mounted) {
          setState(() {
            _isCreatingAccount = false;
          });
          _showErrorDialog(
              decodedResponse['message'] ?? 'error_creating_account'.tr());
        }
      }
    } catch (e) {
      // معالجة أي استثناءات
      if (mounted) {
        setState(() {
          _isCreatingAccount = false;
        });
        _showErrorDialog('${'error_creating_account'.tr()}: $e');
      }
    }
  }

  // إنشاء الحساب بالصورة الافتراضية عند الضغط على "تخطي"
  Future<void> _createAccountWithDefaultImage() async {
    // تعيين الصورة إلى null لاستخدام الصورة الافتراضية
    setState(() {
      _selectedImage = null;
    });

    // استدعاء دالة إنشاء الحساب
    await _createAccountWithImage();
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
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Image.asset(
                  'assets/images/Groupes@4x.png',
                  width: 110,
                  height: 110,
                ),
              ),
            ),
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
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                            child: _showSuccessAnimation
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Lottie.asset(
                                          'assets/animations/success.json',
                                          width: 200,
                                          height: 200,
                                          repeat: false,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'account_created_successfully'.tr(),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2F9C95),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: [
                                      Text(
                                        'choose_profile_picture'.tr(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE57353),
                                          shape: BoxShape.circle,
                                        ),
                                        child: _selectedImage != null
                                            ? ClipOval(
                                                child: Image.file(
                                                  _selectedImage!,
                                                  width: 120,
                                                  height: 120,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : const Center(
                                                child: Icon(
                                                  Icons.person_outline,
                                                  size: 60,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 60),
                                      _isCreatingAccount
                                          ? const Center(
                                              child: Column(
                                                children: [
                                                  CircularProgressIndicator(
                                                    color: Color(0xFF2F9C95),
                                                  ),
                                                  SizedBox(height: 20),
                                                  Text(
                                                    "جاري إنشاء حسابك...",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Color(0xFF2F9C95),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              transitionBuilder: (Widget child,
                                                  Animation<double> animation) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin: const Offset(
                                                          0.0, 0.2),
                                                      end: Offset.zero,
                                                    ).animate(CurvedAnimation(
                                                      parent: animation,
                                                      curve:
                                                          Curves.easeOutCubic,
                                                    )),
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              child: !_showImageOptions
                                                  ? Column(
                                                      key: const ValueKey(
                                                          'main_options'),
                                                      children: [
                                                        InkWell(
                                                          onTap: _takePhoto,
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                  0xFFE57353),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                'take_photo_now'
                                                                    .tr(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 15),
                                                        InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              _showImageOptions =
                                                                  true;
                                                            });
                                                          },
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                  0xFFE57353),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                'choose_image'
                                                                    .tr(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 15),
                                                        // إضافة زر تخطي لاستخدام الصورة الافتراضية
                                                        InkWell(
                                                          onTap:
                                                              _createAccountWithDefaultImage,
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.grey
                                                                  .shade300,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                'skip'.tr(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .black54,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Column(
                                                      key: const ValueKey(
                                                          'sub_options'),
                                                      children: [
                                                        InkWell(
                                                          onTap:
                                                              _pickImageFromGallery,
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                  0xFFE57353),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                'choose_from_gallery'
                                                                    .tr(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 15),
                                                        InkWell(
                                                          onTap: _pickFile,
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                  0xFFE57353),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                'choose_from_files'
                                                                    .tr(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 15),
                                                        InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              _showImageOptions =
                                                                  false;
                                                            });
                                                          },
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.grey
                                                                  .shade300,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                'back'.tr(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .black54,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                      SizedBox(height: screenHeight * 0.05),
                                      // زر متابعة لإنشاء الحساب بالصورة المختارة
                                      if (_selectedImage != null &&
                                          !_isCreatingAccount)
                                        InkWell(
                                          onTap: _createAccountWithImage,
                                          child: Container(
                                            width: double.infinity,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2F9C95),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'continue_button'.tr(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
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
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 20,
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
          ],
        ),
      ),
    );
  }
}
