import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:math';

class User {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String userType;
  final bool isStaff;
  final String token;
  final String? statutVerification;
  final String? raisonRefus;
  final String? photoProfile;
  final bool? disponibilite;
  final double? latitude;
  final double? longitude;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.userType,
    required this.isStaff,
    required this.token,
    this.statutVerification,
    this.raisonRefus,
    this.photoProfile,
    this.disponibilite,
    this.latitude,
    this.longitude,
  });

  factory User.fromJson(Map<String, dynamic> userData, String token) {
    // طباعة البيانات للتصحيح
    debugPrint('User data from server: $userData');

    // استخراج مسار الصورة الشخصية بشكل أكثر تفصيلاً
    String? photoProfile;
    if (userData.containsKey('photo_profile')) {
      photoProfile = userData['photo_profile'];
      if (photoProfile != null && photoProfile.isNotEmpty) {
        debugPrint('تم العثور على صورة الملف الشخصي: $photoProfile');
      } else {
        debugPrint('صورة الملف الشخصي فارغة أو غير محددة');
      }
    } else {
      debugPrint('مفتاح photo_profile غير موجود في بيانات المستخدم');
    }

    // طباعة جميع المفاتيح الموجودة في بيانات المستخدم
    debugPrint('مفاتيح بيانات المستخدم: ${userData.keys.toList()}');

    // استخراج حالة التوفر (disponibilite)
    bool? disponibilite;
    if (userData.containsKey('disponibilite')) {
      disponibilite = userData['disponibilite'] == true;
      debugPrint('حالة التوفر: $disponibilite');
    }

    // استخراج إحداثيات المستخدم
    double? latitude;
    double? longitude;
    if (userData.containsKey('latitude') && userData['latitude'] != null) {
      latitude = double.tryParse(userData['latitude'].toString());
      debugPrint('خط العرض: $latitude');
    }
    if (userData.containsKey('longitude') && userData['longitude'] != null) {
      longitude = double.tryParse(userData['longitude'].toString());
      debugPrint('خط الطول: $longitude');
    }

    return User(
      id: userData['id_utilisateur'] ?? 0,
      username: userData['username'] ?? '',
      email: userData['email'] ?? '',
      phone: userData['telephone'] ?? '',
      userType: userData['type_utilisateur'] ?? '',
      isStaff: userData['is_staff'] ?? false,
      token: token,
      statutVerification: userData['statut_verification'],
      raisonRefus: userData['raison_refus'],
      photoProfile: photoProfile,
      disponibilite: disponibilite,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class AuthService {
  // تعريف رابط API - قم بتغييره حسب إعدادات البيئة الخاصة بك
  // استخدم 10.0.2.2 للوصول إلى localhost من المُحاكي في Android
  // استخدم 127.0.0.1 للاختبار المحلي
  static String baseUrl =
      'http://192.168.100.13:8000'; // استخدام 10.0.2.2 للوصول إلى localhost من محاكي Android

  // تغيير المنفذ للاختبار
  static void setBaseUrl(String newUrl) {
    baseUrl = newUrl;
    debugPrint('API base URL changed to: $baseUrl');
  }

  // دالة اختبار الاتصال بالخادم
  Future<Map<String, dynamic>> testConnection() async {
    try {
      // محاولة الاتصال بنقطة نهاية بسيطة (مثل الجذر أو صفحة التوثيق)
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Test connection status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      return {
        'success': response.statusCode < 400,
        'message': 'تم الاتصال بالخادم',
        'status_code': response.statusCode,
        'debug': response.body,
      };
    } catch (e) {
      debugPrint('خطأ في اختبار الاتصال: $e');
      return {
        'success': false,
        'message': 'فشل الاتصال بالخادم',
        'debug': 'Connection error: $e',
      };
    }
  }

  // دالة تسجيل الدخول مع التحقق من نوع الحساب
  Future<Map<String, dynamic>> login(String emailOrPhone, String password,
      {String? userType}) async {
    try {
      // تحديد ما إذا كان المدخل بريد إلكتروني أو رقم هاتف
      bool isEmail = emailOrPhone.contains('@');
      bool isPhone = !isEmail && emailOrPhone.startsWith(RegExp(r'[0-9]'));

      // إنشاء جسم الطلب للواجهة الخلفية
      Map<String, dynamic> requestBody = {};

      if (isEmail) {
        requestBody['email'] = emailOrPhone;
      } else if (isPhone) {
        requestBody['telephone'] = emailOrPhone;
      } else {
        requestBody['username'] = emailOrPhone;
      }

      // إضافة كلمة المرور
      requestBody['password'] = password;

      // إضافة نوع المستخدم إلى الطلب
      if (userType != null && userType.isNotEmpty) {
        requestBody['type_utilisateur'] = userType;
      }

      debugPrint(
          'Sending login request to $baseUrl/api/login/ with: $requestBody');

      // إرسال طلب المصادقة
      final response = await http
          .post(
        Uri.parse('$baseUrl/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Request timeout after 10 seconds');
          throw Exception('Timeout: no response from server after 10 seconds');
        },
      );

      // طباعة معلومات الاستجابة للتصحيح
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint(
          'Response body preview: ${response.body.substring(0, min(100, response.body.length))}');

      // تحقق من وجود استجابة HTML (خطأ في الخادم)
      if (response.body.contains('<!DOCTYPE html>') ||
          response.body.contains('<html>')) {
        debugPrint('Received HTML response - server error or wrong URL');

        return {
          'success': false,
          'message': 'connection_error',
        };
      }

      // محاولة تحليل JSON
      try {
        final responseData = jsonDecode(response.body);
        debugPrint('JSON keys: ${responseData.keys.toList()}');

        // معالجة حالة الحساب غير النشط
        if (responseData['status'] == 'inactive') {
          return {
            'success': false,
            'status': 'inactive',
            'user': responseData['user'],
            'message': responseData['message'] ?? '',
          };
        }

        // التحقق من الاستجابة
        if (response.statusCode == 200) {
          debugPrint('Successful response with status 200');

          // التحقق من نمط الاستجابة (API جديد: status = success)
          if (responseData.containsKey('status') &&
              responseData['status'] == 'success') {
            debugPrint('Using new API response format');
            final userData = responseData['user'];

            // التحقق من تطابق نوع الحساب إذا كان قد تم تحديد نوع
            if (userType != null && userType.isNotEmpty) {
              final userAccountType = userData['type_utilisateur'] ?? '';

              // إذا كان نوع المستخدم المختار "Client"، يجب أن يكون نوع الحساب "Client"
              if (userType == 'Client' && userAccountType != 'Client') {
                return {
                  'success': false,
                  'message': 'invalid_account_type',
                  'account_type': 'client',
                };
              }

              // إذا كان نوع المستخدم المختار "Driver"، يجب أن يكون نوع الحساب "Livreur" أو "Chauffeur"
              if (userType == 'Driver' &&
                  userAccountType != 'Livreur' &&
                  userAccountType != 'Chauffeur') {
                return {
                  'success': false,
                  'message': 'invalid_account_type',
                  'account_type': 'driver',
                };
              }
            }

            return {
              'success': true,
              'user': userData,
              'message': 'login_success',
            };
          }
          // نمط الاستجابة القديم
          else if (responseData.containsKey('tokens') &&
              responseData.containsKey('data')) {
            debugPrint('Using old API response format with tokens and data');
            final userData = responseData['data'];

            // التحقق من تطابق نوع الحساب إذا كان قد تم تحديد نوع
            if (userType != null && userType.isNotEmpty) {
              final userAccountType = userData['type_utilisateur'] ?? '';

              // إذا كان نوع المستخدم المختار "Client"، يجب أن يكون نوع الحساب "Client"
              if (userType == 'Client' && userAccountType != 'Client') {
                return {
                  'success': false,
                  'message': 'invalid_account_type',
                  'account_type': 'client',
                };
              }

              // إذا كان نوع المستخدم المختار "Driver"، يجب أن يكون نوع الحساب "Livreur" أو "Chauffeur"
              if (userType == 'Driver' &&
                  userAccountType != 'Livreur' &&
                  userAccountType != 'Chauffeur') {
                return {
                  'success': false,
                  'message': 'invalid_account_type',
                  'account_type': 'driver',
                };
              }
            }

            return {
              'success': true,
              'user': userData,
              'message': 'login_success',
            };
          } else {
            // استجابة غير متوقعة
            return {
              'success': false,
              'message': 'unknown_error',
            };
          }
        } else if (response.statusCode == 401) {
          // خطأ المصادقة - التحقق من نوع الخطأ
          String errorType = 'invalid_credentials';

          if (responseData.containsKey('error')) {
            String errorMsg = responseData['error'];

            // التحقق من نوع الخطأ ونوع الحساب المختار
            if (errorMsg.contains('غير موجود') ||
                errorMsg.contains('not found')) {
              // تخصيص رسالة الخطأ حسب نوع الحساب المختار
              if (userType == 'Client') {
                errorType = 'client_not_found';
              } else if (userType == 'Livreur') {
                errorType = 'driver_not_found';
              } else {
                errorType = 'account_not_found';
              }
            } else if (errorMsg.contains('كلمة المرور') ||
                errorMsg.contains('password')) {
              errorType = 'wrong_password';
            } else if (errorMsg.contains('نوع الحساب') ||
                errorMsg.contains('account type') ||
                errorMsg.contains('user type')) {
              errorType = 'wrong_account_type';
            }
          }

          return {
            'success': false,
            'message': errorType,
          };
        } else if (response.statusCode == 400) {
          // خطأ في البيانات المرسلة
          if (responseData.containsKey('error') &&
              responseData['error'].toString().contains('تعذر تسجيل الدخول')) {
            return {
              'success': false,
              'message': 'multiple_accounts',
            };
          }

          return {
            'success': false,
            'message': 'invalid_credentials',
          };
        } else if (response.statusCode == 404) {
          // الخدمة غير موجودة
          return {
            'success': false,
            'message': 'connection_error',
          };
        } else {
          // أي أخطاء أخرى على مستوى الخادم
          return {
            'success': false,
            'message': 'server_error',
          };
        }
      } catch (e) {
        // خطأ في تحليل JSON
        debugPrint('Error parsing JSON response: $e');
        return {
          'success': false,
          'message': 'server_error',
        };
      }
    } catch (e) {
      // خطأ في الاتصال
      debugPrint('Connection error: $e');
      if (e.toString().contains('SocketException')) {
        return {
          'success': false,
          'message': 'connection_error',
        };
      } else if (e.toString().contains('Timeout')) {
        return {
          'success': false,
          'message': 'connection_error',
        };
      }

      return {
        'success': false,
        'message': 'try_again',
      };
    }
  }

  // دالة للتحقق من وجود المستخدم في قاعدة البيانات بناءً على البريد الإلكتروني أو رقم الهاتف
  Future<Map<String, dynamic>> checkUserExists(String identifier,
      {required bool isEmail, required String userType}) async {
    try {
      // إنشاء معلمات الطلب
      Map<String, dynamic> requestBody = {};

      if (isEmail) {
        requestBody['email'] = identifier;
      } else {
        requestBody['phone'] = identifier;
      }

      // إضافة نوع المستخدم لتصفية النتائج
      requestBody['user_type'] = userType;

      debugPrint('**** بداية التحقق من وجود المستخدم ****');
      debugPrint('الرابط الأساسي للAPI: $baseUrl');
      debugPrint('عنوان الطلب الكامل: $baseUrl/api/check-user-exists/');
      debugPrint('طريقة الطلب: POST');
      debugPrint('معلمات الطلب: $requestBody');

      // إرسال طلب API للتحقق من وجود المستخدم
      debugPrint('جاري إرسال الطلب...');

      final response = await http.post(
        Uri.parse('$baseUrl/api/check-user-exists/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('**** استجابة التحقق من وجود المستخدم ****');
      debugPrint('رمز حالة الاستجابة: ${response.statusCode}');
      debugPrint('محتوى الاستجابة: ${response.body}');

      // محاولة تحليل الاستجابة كـ JSON (مع معالجة الأخطاء المحتملة)
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('Error parsing JSON response: $e');
        return {
          'exists': false,
          'message': 'خطأ في تحليل استجابة الخادم',
          'status': 'error',
        };
      }

      // التعامل مع الاستجابة بناءً على رمز الحالة
      if (response.statusCode == 200) {
        // في حالة النجاح، التحقق من أن الحقل 'exists' موجود بالفعل
        if (data.containsKey('exists')) {
          bool exists = data['exists'] ?? false;
          debugPrint('User exists: $exists');

          return {
            'exists': exists,
            'message': exists
                ? (data['message'] ?? 'تم العثور على الحساب')
                : (data['message'] ?? 'لا يوجد حساب بهذه المعلومات'),
            'status': exists ? 'success' : 'error',
          };
        } else {
          // حالة خاصة: استجابة صحيحة ولكن بدون حقل 'exists'
          debugPrint('Response missing "exists" field');
          return {
            'exists': false,
            'message': 'استجابة الخادم غير مكتملة',
            'status': 'error',
          };
        }
      } else if (response.statusCode == 404) {
        debugPrint('User not found (404)');
        return {
          'exists': false,
          'message': data['message'] ?? 'لا يوجد حساب بهذه المعلومات',
          'status': 'error',
        };
      } else {
        // أي رمز حالة آخر يعتبر خطأ
        debugPrint('Unexpected status code: ${response.statusCode}');
        return {
          'exists': false,
          'message': data['message'] ?? 'حدث خطأ في التحقق من وجود الحساب',
          'status': 'error',
        };
      }
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      return {
        'exists': false,
        'message': 'حدث خطأ في الاتصال بالخادم',
        'status': 'error',
      };
    }
  }

  // دالة لإرسال رمز التحقق عبر البريد الإلكتروني أو رقم الهاتف
  Future<Map<String, dynamic>> sendOTP({
    required String identifier,
    required bool isEmail,
    required String userType,
    required String fullName,
    String? birthDate,
  }) async {
    try {
      // تحديد نوع المعرف (بريد إلكتروني أو رقم هاتف)
      String identifierType = isEmail ? 'email' : 'phone';

      // تهيئة requestBody مع البيانات المطلوبة
      Map<String, dynamic> requestBody = {
        identifierType: identifier,
        'user_type': userType,
        'full_name': fullName,
      };

      if (birthDate != null && birthDate.isNotEmpty) {
        requestBody['birth_date'] = birthDate;
      }

      // استخدم نفس URL الذي يعمل في OTPService
      final String url = isEmail
          ? '$baseUrl/api/send-otp-email/'
          : '$baseUrl/api/send-otp-sms/';

      debugPrint('إرسال OTP عبر الرابط: $url');
      debugPrint('نوع المستخدم: $userType');
      debugPrint('طلب API: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('رمز حالة الاستجابة: ${response.statusCode}');
      debugPrint('محتوى الاستجابة: ${response.body}');

      debugPrint('رمز حالة الاستجابة: ${response.statusCode}');
      debugPrint('محتوى الاستجابة: ${response.body}');

      // حالات الاستجابة الناجحة
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('تم إرسال الرمز بنجاح عبر API الأساسي');
        try {
          Map<String, dynamic> data = jsonDecode(response.body);
          return {
            'success': true,
            'message': 'otp_sent',
            'data': data,
          };
        } catch (e) {
          // حتى لو كان هناك خطأ في تحليل JSON، الاستجابة ناجحة
          return {
            'success': true,
            'message': 'otp_sent',
            'data': {'status': 'success'},
          };
        }
      }
      // حالة عدم وجود المستخدم
      else if (response.statusCode == 404) {
        debugPrint('خطأ 404: لم يتم العثور على المستخدم أو المسار');
        return {
          'success': false,
          'message': 'user_not_found',
        };
      }
      // حالات الخطأ الأخرى
      else {
        try {
          Map<String, dynamic> errorData = jsonDecode(response.body);
          debugPrint('رسالة الخطأ: ${errorData['message']}');

          return {
            'success': false,
            'message': errorData['message'] ?? 'error_sending_otp',
          };
        } catch (e) {
          debugPrint('خطأ في تحليل استجابة الخطأ: $e');

          return {
            'success': false,
            'message': 'error_sending_otp',
            'status_code': response.statusCode,
          };
        }
      }
    } catch (e) {
      debugPrint('خطأ عام في إرسال OTP: $e');
      return {
        'success': false,
        'message': 'error_sending_otp',
        'error': e.toString(),
      };
    }
  }

  // ملاحظة: تم إزالة دالة _sendRealEmailWithOTP لأن API الأساسي يعمل بشكل جيد

  // دالة لتسجيل السائق (Livreur أو Chauffeur) مع جميع الحقول والصور
  Future<Map<String, dynamic>> registerDriver({
    required String userType,
    required String email,
    required String phone,
    required String fullName,
    required String dob,
    required String password,
    required String adresse,
    required String matriculeVehicule,
    required String typeVehicule,
    required String zoneCouverture,
    required String startTime,
    required String endTime,
    required dynamic profilePicture, // File
    required dynamic photoVehicule,
    required dynamic photoPermis,
    required dynamic photoCarteGrise,
    required dynamic photoAssurance,
    required dynamic photoVignette,
    required dynamic photoCarteMunicipale,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/api/complete-registration/');
      var request = http.MultipartRequest('POST', uri);
      request.fields.addAll({
        'user_type': userType,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'birth_date': dob,
        'password': password,
        'adresse': adresse,
        'matricule_vehicule': matriculeVehicule,
        'type_vehicule': typeVehicule,
        'zone_couverture': zoneCouverture,
        'start_time': startTime,
        'end_time': endTime,
      });
      if (profilePicture != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'photo_profile', profilePicture.path));
      }
      request.files.addAll([
        await http.MultipartFile.fromPath('photo_vehicule', photoVehicule.path),
        await http.MultipartFile.fromPath('photo_permis', photoPermis.path),
        await http.MultipartFile.fromPath(
            'photo_carte_grise', photoCarteGrise.path),
        await http.MultipartFile.fromPath(
            'photo_assurance', photoAssurance.path),
        await http.MultipartFile.fromPath('photo_vignette', photoVignette.path),
        await http.MultipartFile.fromPath(
            'photo_carte_municipale', photoCarteMunicipale.path),
      ]);
      var streamedResponse = await request.send();
      var responseData = await streamedResponse.stream.bytesToString();
      var decodedResponse = json.decode(responseData);
      return {
        'statusCode': streamedResponse.statusCode,
        'data': decodedResponse,
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'message': e.toString()},
      };
    }
  }

  // دالة لتحديث حالة توفر السائق (disponibilite)
  Future<Map<String, dynamic>> updateDriverAvailability(
      int driverId, bool isAvailable, String token) async {
    try {
      debugPrint(
          'تحديث حالة توفر السائق: driverId=$driverId, isAvailable=$isAvailable');

      // إنشاء جسم الطلب
      Map<String, dynamic> requestBody = {'disponibilite': isAvailable};

      // إرسال طلب تحديث الحالة
      final response = await http
          .patch(
        Uri.parse('$baseUrl/api/users/$driverId/update/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('انتهت مهلة الطلب بعد 10 ثوانٍ');
          throw Exception(
              'انتهت المهلة: لا توجد استجابة من الخادم بعد 10 ثوانٍ');
        },
      );

      debugPrint('رمز حالة الاستجابة: ${response.statusCode}');
      debugPrint(
          'معاينة نص الاستجابة: ${response.body.substring(0, min(100, response.body.length))}');

      // تحليل الاستجابة
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'تم تحديث الحالة بنجاح',
          'disponibilite': responseData['disponibilite'] ?? isAvailable
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'فشل تحديث الحالة',
          'error': responseData['error'] ?? 'خطأ غير معروف'
        };
      }
    } catch (e) {
      debugPrint('خطأ في تحديث حالة السائق: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تحديث الحالة',
        'error': e.toString()
      };
    }
  }

  // دالة للحصول على معلومات الملف الشخصي للمستخدم
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/validate-token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token'
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'انتهت المهلة: لا توجد استجابة من الخادم بعد 10 ثوانٍ');
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': 'فشل في الحصول على معلومات المستخدم',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الاتصال',
        'error': e.toString()
      };
    }
  }
}
