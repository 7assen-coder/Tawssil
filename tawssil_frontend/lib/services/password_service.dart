import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class PasswordService {
  static String baseUrl = AuthService.baseUrl;

  /// التحقق من وجود المستخدم بناءً على البريد الإلكتروني أو رقم الهاتف
  static Future<Map<String, dynamic>> checkUserExists({
    required String userType,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'user_type': userType,
      };

      // إضافة البريد الإلكتروني أو رقم الهاتف إذا كان متوفراً
      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // تنظيف رقم الهاتف
        String formattedPhone = phoneNumber;
        if (phoneNumber.startsWith('+222')) {
          formattedPhone = phoneNumber.substring(4);
        } else if (phoneNumber.startsWith('+')) {
          formattedPhone = phoneNumber.substring(1);
        }
        requestBody['phone'] = formattedPhone;
      }

      debugPrint('Checking user exists with data: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/check-user-exists/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Check user exists response: ${response.statusCode}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // المستخدم موجود
        return {
          'success': true,
          'exists': true,
          'message': responseData['message'] ?? 'User found',
          'userId': responseData['user_id'], // في حالة إرجاع API لمعرف المستخدم
        };
      } else if (response.statusCode == 404) {
        // المستخدم غير موجود
        return {
          'success': true,
          'exists': false,
          'message': responseData['message'] ?? 'User not found',
        };
      } else {
        // خطأ آخر
        return {
          'success': false,
          'exists': false,
          'message': responseData['message'] ?? 'Error checking user existence',
        };
      }
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      return {
        'success': false,
        'exists': false,
        'message': 'Error: $e',
      };
    }
  }

  /// إعادة تعيين كلمة المرور
  static Future<Map<String, dynamic>> resetPassword({
    String? userId,
    required String newPassword,
    String? email,
    String? phoneNumber,
    required String userType,
    String? code,
    String? identifier,
  }) async {
    try {
      // التحقق من وجود المستخدم إذا لم يتم تمرير معرف المستخدم أو معرف التحقق
      if ((userId == null || userId.isEmpty) &&
          (identifier == null || identifier.isEmpty)) {
        final userCheckResult = await checkUserExists(
          userType: userType,
          email: email,
          phoneNumber: phoneNumber,
        );

        if (!userCheckResult['success'] || !userCheckResult['exists']) {
          return {
            'success': false,
            'message': 'user_not_found',
          };
        }

        // استخدام معرف المستخدم من نتيجة التحقق
        userId = userCheckResult['userId']?.toString();

        // إذا ما زال معرف المستخدم غير متوفر، نعود بخطأ
        if (userId == null || userId.isEmpty) {
          return {
            'success': false,
            'message': 'user_id_not_available',
          };
        }
      }

      final Map<String, dynamic> requestBody = {
        'new_password': newPassword,
      };

      // استخدام المعرف للبحث
      if (identifier != null && identifier.isNotEmpty) {
        requestBody['identifier'] = identifier;

        // إضافة رمز التحقق إذا كان متوفراً (لم يعد ضرورياً عند استخدام identifier)
        if (code != null && code.isNotEmpty) {
          requestBody['code'] = code;
        }
      } else if (userId != null && userId.isNotEmpty) {
        // استخدام user_id للتوافق مع وضع API القديم
        requestBody['user_id'] = userId;
      }

      // إضافة نوع المستخدم
      requestBody['user_type'] = userType;

      // إضافة البريد الإلكتروني أو رقم الهاتف إذا كانت متوفرة للتوافق
      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        requestBody['phone'] = phoneNumber;
      }

      debugPrint('Resetting password with data: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/reset-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Reset password response: ${response.statusCode}');
      debugPrint('Reset password response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
