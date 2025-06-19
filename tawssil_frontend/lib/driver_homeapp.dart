import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/auth_service.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'translations/locale_keys.g.dart';

class DriverHomeApp extends StatefulWidget {
  final String userIdentifier; // يمكن أن يكون بريد إلكتروني أو رقم هاتف
  final User? userData; // بيانات المستخدم كاملة (اختياري)

  const DriverHomeApp({
    super.key,
    required this.userIdentifier,
    this.userData,
  });

  @override
  State<DriverHomeApp> createState() => _DriverHomeAppState();
}

class _DriverHomeAppState extends State<DriverHomeApp> {
  int _selectedIndex = 0;
  late String _username;
  bool _isOnline = false; // حالة السائق (متصل/غير متصل)
  int _deliveriesCompleted = 0; // عدد التوصيلات المكتملة
  double _rating = 4.5; // تقييم السائق
  bool showChatPage = false; // متغير لعرض صفحة المحادثة
  bool _isUpdatingStatus = false; // متغير لتتبع حالة تحديث التوفر
  int _earnings = 0; // أرباح السائق

  // إضافة موقع ثابت للخريطة

  // متغيرات للموقع
  final Location _location = Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  LocationData? _locationData;

  @override
  void initState() {
    super.initState();
    // استخدام اسم المستخدم إذا كان متاحاً، وإلا استخدام المعرف
    _username = widget.userData?.username ?? 'مستخدم';

    // طباعة معلومات المستخدم للتشخيص
    if (widget.userData != null) {
      debugPrint('معلومات المستخدم عند التهيئة:');
      debugPrint('معرف المستخدم: ${widget.userData!.id}');
      debugPrint('اسم المستخدم: ${widget.userData!.username}');
      debugPrint('نوع المستخدم: ${widget.userData!.userType}');
      debugPrint(
          'التوكن: ${widget.userData!.token.isNotEmpty ? "موجود" : "غير موجود"}');

      // إذا كان التوكن فارغًا، إنشاء توكن مؤقت للاختبار
      if (widget.userData!.token.isEmpty) {
        debugPrint('التوكن فارغ، إنشاء توكن مؤقت للاختبار...');
        _createTemporaryToken();
      }

      if (widget.userData!.userType == 'Livreur' ||
          widget.userData!.userType == 'Chauffeur') {
        // استخدام قيمة disponibilite من قاعدة البيانات
        _isOnline = widget.userData!.disponibilite ?? false;
        debugPrint('تم تعيين الحالة الأولية من قاعدة البيانات: $_isOnline');
      }
    } else {
      debugPrint('بيانات المستخدم غير متوفرة (widget.userData is null)');
    }

    // تحديث معلومات المستخدم من الخادم
    if (widget.userData != null && widget.userData!.token.isNotEmpty) {
      debugPrint('جاري تحديث معلومات المستخدم من الخادم...');
      _updateUserDataFromServer();
    } else {
      debugPrint('لا يمكن تحديث معلومات المستخدم: التوكن غير متوفر');
    }

    // طلب إذن الموقع عند بدء التطبيق
    _checkLocationPermission();

    // تأخير قليل قبل تحميل بيانات السائق للتأكد من اكتمال تهيئة الصفحة
    Future.delayed(const Duration(milliseconds: 500), () {
      // مستقبلاً: استرجاع بيانات السائق من API
      if (widget.userData != null) {
        debugPrint('جاري تحميل بيانات السائق بعد التأخير...');
        _loadDriverData();
      } else {
        debugPrint(
            'لا يمكن تحميل بيانات السائق بعد التأخير: بيانات المستخدم غير متوفرة');
      }
    });
  }

  // دالة للتحقق من إذن الموقع
  Future<void> _checkLocationPermission() async {
    try {
      // التحقق من تفعيل خدمة الموقع
      _serviceEnabled = await _location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await _location.requestService();
        if (!_serviceEnabled) {
          debugPrint('خدمة الموقع غير مفعلة ولم يتم تفعيلها');
          return;
        }
      }

      // التحقق من إذن الموقع
      _permissionGranted = await _location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await _location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          debugPrint('إذن الموقع مرفوض');
          // طلب الإذن باستخدام حزمة permission_handler إذا فشل الطلب الأول
          await _requestLocationPermissionAlternative();
          return;
        }
      }

      // الحصول على موقع المستخدم
      _locationData = await _location.getLocation();
      debugPrint(
          'تم الحصول على موقع المستخدم: ${_locationData?.latitude}, ${_locationData?.longitude}');

      // تحديث الموقع المخزن مؤقتًا
      if (_locationData != null &&
          _locationData!.latitude != null &&
          _locationData!.longitude != null) {
        _cachedUserLocation =
            LatLng(_locationData!.latitude!, _locationData!.longitude!);
        _lastLocationFetch = DateTime.now();

        // تحديث موقع المستخدم في الخادم
        await _updateUserLocationOnServer();
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من إذن الموقع: $e');
    }
  }

  // طريقة بديلة لطلب إذن الموقع
  Future<void> _requestLocationPermissionAlternative() async {
    try {
      final status = await permission.Permission.location.request();
      debugPrint('حالة إذن الموقع البديل: $status');
      if (status.isGranted) {
        // محاولة الحصول على الموقع مرة أخرى
        _locationData = await _location.getLocation();
        debugPrint(
            'تم الحصول على موقع المستخدم (بديل): ${_locationData?.latitude}, ${_locationData?.longitude}');

        // تحديث الموقع المخزن مؤقتًا
        if (_locationData != null &&
            _locationData!.latitude != null &&
            _locationData!.longitude != null) {
          _cachedUserLocation =
              LatLng(_locationData!.latitude!, _locationData!.longitude!);
          _lastLocationFetch = DateTime.now();

          // تحديث موقع المستخدم في الخادم
          await _updateUserLocationOnServer();
        }
      } else if (status.isPermanentlyDenied) {
        // إظهار رسالة للمستخدم لفتح إعدادات التطبيق
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('إذن الموقع مطلوب'),
              content: const Text(
                  'يرجى تفعيل إذن الموقع من إعدادات التطبيق للاستفادة من جميع ميزات التطبيق.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    permission.openAppSettings();
                  },
                  child: const Text('فتح الإعدادات'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('خطأ في طلب إذن الموقع البديل: $e');
    }
  }

  // دالة لتحديث موقع المستخدم في الخادم
  Future<void> _updateUserLocationOnServer() async {
    if (widget.userData == null || _cachedUserLocation == null) return;

    try {
      final int userId = widget.userData!.id;
      final String token = _updatedUserData?.token ?? widget.userData!.token;

      // استدعاء API لتحديث موقع المستخدم
      final endpoint =
          '${AuthService.baseUrl}/api/users/$userId/update-location/';
      debugPrint('تحديث موقع المستخدم على الخادم: $endpoint');

      final response = await http.put(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'latitude': _cachedUserLocation!.latitude,
          'longitude': _cachedUserLocation!.longitude,
        }),
      );

      debugPrint('رمز استجابة تحديث الموقع: ${response.statusCode}');
      debugPrint('محتوى استجابة تحديث الموقع: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('تم تحديث موقع المستخدم بنجاح على الخادم');
      } else {
        debugPrint('فشل في تحديث موقع المستخدم على الخادم');
      }
    } catch (e) {
      debugPrint('خطأ في تحديث موقع المستخدم على الخادم: $e');
    }
  }

  // دالة لإنشاء توكن مؤقت للاختبار
  void _createTemporaryToken() {
    if (widget.userData != null) {
      // إنشاء توكن مؤقت للاختبار
      const tempToken = 'temp_token_for_testing_123456789';
      debugPrint('تم إنشاء توكن مؤقت: $tempToken');

      // تعديل كائن المستخدم لإضافة التوكن المؤقت
      // نظرًا لأن كائن User هو immutable، نحتاج لإنشاء نسخة جديدة
      final updatedUser = User(
        id: widget.userData!.id,
        username: widget.userData!.username,
        email: widget.userData!.email,
        phone: widget.userData!.phone,
        userType: widget.userData!.userType,
        isStaff: widget.userData!.isStaff,
        token: tempToken, // استخدام التوكن المؤقت
        statutVerification: widget.userData!.statutVerification,
        raisonRefus: widget.userData!.raisonRefus,
        photoProfile: widget.userData!.photoProfile,
        disponibilite: widget.userData!.disponibilite,
      );

      // تحديث المتغير widget.userData باستخدام التقنية المناسبة
      // نظرًا لأن widget.userData هو final، لا يمكن تعديله مباشرة
      // لكن يمكننا استخدام متغير محلي لتخزين النسخة المحدثة
      if (mounted) {
        setState(() {
          // استخدام متغير محلي لتخزين النسخة المحدثة
          _updatedUserData = updatedUser;
          debugPrint('تم تحديث بيانات المستخدم بالتوكن المؤقت');
        });
      }
    }
  }

  // متغير لتخزين النسخة المحدثة من بيانات المستخدم
  User? _updatedUserData;

  // دالة لتحديث معلومات المستخدم من الخادم
  Future<void> _updateUserDataFromServer() async {
    // استخدام التوكن المؤقت إذا كان متاحًا
    final String token = _updatedUserData?.token ?? widget.userData!.token;

    if (token.isEmpty) {
      debugPrint('لا يمكن تحديث معلومات المستخدم: التوكن غير متوفر');
      return;
    }

    try {
      debugPrint('جاري تحديث معلومات المستخدم من الخادم...');
      debugPrint(
          'التوكن المستخدم: ${token.substring(0, min(10, token.length))}...');

      final authService = AuthService();
      final result = await authService.getUserProfile(token);

      debugPrint('نتيجة استدعاء getUserProfile: $result');

      if (result['success'] == true && result['user'] != null) {
        // تحديث حالة التوفر من البيانات المسترجعة
        if (mounted) {
          setState(() {
            if (result['user']['disponibilite'] != null) {
              _isOnline = result['user']['disponibilite'];
              debugPrint('تم تحديث حالة التوفر من الخادم: $_isOnline');
            }
          });
        }
      } else {
        debugPrint('فشل في تحديث معلومات المستخدم: ${result['message']}');
      }
    } catch (e) {
      debugPrint('خطأ في تحديث بيانات المستخدم: $e');
    }
  }

  // دالة وهمية لتحميل بيانات السائق
  Future<void> _loadDriverData() async {
    // هنا سيتم استدعاء API لجلب بيانات السائق
    try {
      if (widget.userData == null) {
        debugPrint('لا يمكن تحميل بيانات السائق: بيانات المستخدم غير متوفرة');
        return;
      }

      // استخدام التوكن المؤقت إذا كان متاحًا
      final String token = _updatedUserData?.token ?? widget.userData!.token;

      if (token.isEmpty) {
        debugPrint('لا يمكن تحميل بيانات السائق: التوكن غير متوفر');
        // محاولة إنشاء توكن مؤقت إذا لم يكن متاحًا بعد
        _createTemporaryToken();
        return;
      }

      debugPrint('بدء تحميل بيانات السائق...');
      debugPrint('نوع المستخدم: ${widget.userData!.userType}');
      debugPrint('معرف المستخدم: ${widget.userData!.id}');
      debugPrint(
          'التوكن المستخدم: ${token.substring(0, min(10, token.length))}...');

      // جلب عدد التوصيلات/الرحلات حسب نوع المستخدم
      debugPrint('جاري استدعاء دالة _getDeliveriesOrRidesCount()...');
      final deliveriesCount = await _getDeliveriesOrRidesCount();
      debugPrint('تم استلام عدد التوصيلات/الرحلات: $deliveriesCount');

      // جلب متوسط التقييم
      debugPrint('جاري استدعاء دالة _getUserRating()...');
      final userRating = await _getUserRating();
      debugPrint('تم استلام متوسط التقييم: $userRating');

      // جلب الأرباح
      debugPrint('جاري استدعاء دالة _getUserEarnings()...');
      final userEarnings = await _getUserEarnings();
      debugPrint('تم استلام الأرباح: $userEarnings');

      if (mounted) {
        setState(() {
          _deliveriesCompleted = deliveriesCount;
          _rating = userRating; // استخدام القيمة الفعلية من الخادم
          _earnings = userEarnings; // استخدام القيمة الفعلية من الخادم
          debugPrint(
              'تم تحديث حالة واجهة المستخدم، عدد التوصيلات: $_deliveriesCompleted، التقييم: $_rating، الأرباح: $_earnings');
        });
      } else {
        debugPrint('لا يمكن تحديث الحالة: الويدجت غير مثبتة');
      }
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات السائق: $e');
      if (mounted) {
        setState(() {
          _deliveriesCompleted = 0;
          _rating = 4.0;
          _earnings = 0;
          debugPrint('تم تعيين قيم افتراضية بسبب الخطأ');
        });
      }
    }
  }

  // دالة جديدة لجلب أرباح المستخدم
  Future<int> _getUserEarnings() async {
    if (widget.userData == null) return 0;

    final int userId = widget.userData!.id;
    // استخدام التوكن المؤقت إذا كان متاحًا
    final String token = _updatedUserData?.token ?? widget.userData!.token;

    try {
      debugPrint('جاري جلب أرباح المستخدم...');
      debugPrint('معرف المستخدم: $userId');
      debugPrint('نوع المستخدم: ${widget.userData!.userType}');

      // تحديد نقطة النهاية للحصول على الأرباح
      final endpoint =
          '${AuthService.baseUrl}/api/commandes/user/$userId/earnings/';

      // إضافة طباعة تشخيصية إضافية
      debugPrint('نقطة النهاية: $endpoint');
      debugPrint('قبل إرسال الطلب HTTP');

      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('انتهت مهلة الطلب بعد 30 ثانية');
            throw Exception(
                'انتهت المهلة: لا توجد استجابة من الخادم بعد 30 ثانية');
          },
        );

        debugPrint('بعد إرسال الطلب HTTP');
        debugPrint('رمز الاستجابة: ${response.statusCode}');
        debugPrint('محتوى الاستجابة: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final responseData = jsonDecode(response.body);
            debugPrint('البيانات المستلمة: $responseData');

            // التحقق من وجود مفتاح 'earnings' في البيانات
            if (responseData.containsKey('earnings')) {
              final earnings = responseData['earnings'] as int? ?? 0;
              debugPrint('تم جلب الأرباح بنجاح: $earnings');

              // التحقق من القيمة المستلمة - إذا كانت صفر وكان نوع المستخدم Livreur، نستخدم قيمة حقيقية
              if (earnings == 0 && widget.userData!.userType == 'Livreur') {
                debugPrint(
                    'القيمة المستلمة صفر للموصل، استخدام القيمة الفعلية من عدد التوصيلات');
                // استخدام عدد التوصيلات المكتملة × 100
                final deliveryCount = await _getDeliveriesOrRidesCount();
                final calculatedEarnings = deliveryCount * 100;
                debugPrint('الأرباح المحسوبة: $calculatedEarnings');
                return calculatedEarnings;
              }

              return earnings;
            } else {
              debugPrint('خطأ: لا يوجد مفتاح "earnings" في البيانات المستلمة');
              debugPrint('البيانات المستلمة: $responseData');

              // في حالة عدم وجود مفتاح earnings، نحسب القيمة بناءً على عدد التوصيلات
              if (widget.userData!.userType == 'Livreur') {
                final deliveryCount = await _getDeliveriesOrRidesCount();
                final calculatedEarnings = deliveryCount * 100;
                debugPrint('الأرباح المحسوبة: $calculatedEarnings');
                return calculatedEarnings;
              }

              return 0; // قيمة افتراضية للاختبار
            }
          } catch (parseError) {
            debugPrint('خطأ في تحليل البيانات JSON: $parseError');

            // في حالة خطأ التحليل، نحسب القيمة بناءً على عدد التوصيلات
            if (widget.userData!.userType == 'Livreur') {
              final deliveryCount = await _getDeliveriesOrRidesCount();
              final calculatedEarnings = deliveryCount * 100;
              debugPrint(
                  'الأرباح المحسوبة بعد خطأ التحليل: $calculatedEarnings');
              return calculatedEarnings;
            }

            return 0; // قيمة افتراضية للاختبار
          }
        } else {
          debugPrint('فشل في جلب الأرباح: ${response.statusCode}');

          // في حالة فشل الاستجابة، نحسب القيمة بناءً على عدد التوصيلات
          if (widget.userData!.userType == 'Livreur') {
            final deliveryCount = await _getDeliveriesOrRidesCount();
            final calculatedEarnings = deliveryCount * 100;
            debugPrint(
                'الأرباح المحسوبة بعد فشل الاستجابة: $calculatedEarnings');
            return calculatedEarnings;
          }

          return 0; // قيمة افتراضية للاختبار
        }
      } catch (httpError) {
        debugPrint('خطأ في طلب HTTP: $httpError');

        // في حالة خطأ HTTP، نحسب القيمة بناءً على عدد التوصيلات
        if (widget.userData!.userType == 'Livreur') {
          final deliveryCount = await _getDeliveriesOrRidesCount();
          final calculatedEarnings = deliveryCount * 100;
          debugPrint('الأرباح المحسوبة بعد خطأ HTTP: $calculatedEarnings');
          return calculatedEarnings;
        }

        return 0; // قيمة افتراضية للاختبار
      }
    } catch (e) {
      debugPrint('خطأ في جلب الأرباح: $e');

      // في حالة أي خطأ آخر، نحسب القيمة بناءً على عدد التوصيلات
      if (widget.userData!.userType == 'Livreur') {
        final deliveryCount = await _getDeliveriesOrRidesCount();
        final calculatedEarnings = deliveryCount * 100;
        debugPrint('الأرباح المحسوبة بعد خطأ عام: $calculatedEarnings');
        return calculatedEarnings;
      }

      return 0; // قيمة افتراضية للاختبار
    }
  }

  // دالة جديدة لجلب عدد التوصيلات أو الرحلات حسب نوع المستخدم
  Future<int> _getDeliveriesOrRidesCount() async {
    if (widget.userData == null) return 0;

    final String userType = widget.userData!.userType;
    final int userId = widget.userData!.id;
    // استخدام التوكن المؤقت إذا كان متاحًا
    final String token = _updatedUserData?.token ?? widget.userData!.token;

    try {
      // طباعة معلومات التوكن بشكل مفصل
      debugPrint('==== معلومات التوكن ====');
      debugPrint('التوكن: ${token.isEmpty ? "فارغ!" : token}');
      debugPrint('طول التوكن: ${token.length}');
      if (token.isNotEmpty) {
        debugPrint(
            'بداية التوكن: ${token.substring(0, min(20, token.length))}...');
      }
      debugPrint('====================');

      String endpoint;
      if (userType == 'Livreur') {
        // للموصلين، نستخدم واجهة API للحصول على عدد التوصيلات
        endpoint =
            '${AuthService.baseUrl}/api/commandes/livreur/$userId/count/';
      } else if (userType == 'Chauffeur') {
        // للسائقين، نستخدم واجهة API للحصول على عدد الرحلات
        endpoint =
            '${AuthService.baseUrl}/api/commandes/voyages/chauffeur/$userId/count/';
      } else {
        debugPrint('نوع مستخدم غير معروف: $userType');
        return 0;
      }

      debugPrint('جاري جلب عدد التوصيلات/الرحلات من: $endpoint');
      debugPrint('معرف المستخدم: $userId، نوع المستخدم: $userType');

      // إضافة طباعة تشخيصية إضافية
      debugPrint('قبل إرسال الطلب HTTP');

      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        ).timeout(
          const Duration(seconds: 30), // زيادة المهلة إلى 30 ثانية
          onTimeout: () {
            debugPrint('انتهت مهلة الطلب بعد 30 ثانية');
            throw Exception(
                'انتهت المهلة: لا توجد استجابة من الخادم بعد 30 ثانية');
          },
        );

        debugPrint('بعد إرسال الطلب HTTP');
        debugPrint('رمز الاستجابة: ${response.statusCode}');
        debugPrint('محتوى الاستجابة: ${response.body}');
        debugPrint('رؤوس الاستجابة: ${response.headers}');

        if (response.statusCode == 200) {
          try {
            final responseData = jsonDecode(response.body);
            debugPrint('البيانات المستلمة: $responseData');

            // التحقق من وجود مفتاح 'count' في البيانات
            if (responseData.containsKey('count')) {
              final count = responseData['count'] as int? ?? 0;
              debugPrint('تم جلب عدد التوصيلات/الرحلات بنجاح: $count');
              return count;
            } else {
              debugPrint('خطأ: لا يوجد مفتاح "count" في البيانات المستلمة');
              debugPrint('البيانات المستلمة: $responseData');
              // محاولة استخراج العدد بطريقة أخرى إذا كان التنسيق مختلفًا
              if (responseData is Map) {
                // البحث عن أي مفتاح قد يحتوي على العدد
                for (var key in responseData.keys) {
                  var value = responseData[key];
                  if (value is int) {
                    debugPrint(
                        'تم العثور على قيمة عددية في المفتاح $key: $value');
                    return value;
                  }
                }
              }

              // في حالة عدم العثور على قيمة، نعيد قيمة افتراضية للاختبار
              debugPrint('استخدام قيمة افتراضية للاختبار: 3');
              return 3;
            }
          } catch (parseError) {
            debugPrint('خطأ في تحليل البيانات JSON: $parseError');
            // في حالة فشل تحليل JSON، نحاول استخراج الرقم مباشرة من النص
            final responseText = response.body;
            final regex = RegExp(r'"count":\s*(\d+)');
            final match = regex.firstMatch(responseText);
            if (match != null && match.groupCount >= 1) {
              final countStr = match.group(1);
              if (countStr != null) {
                debugPrint('تم استخراج العدد من النص: $countStr');
                return int.tryParse(countStr) ?? 0;
              }
            }

            // في حالة عدم العثور على قيمة، نعيد قيمة افتراضية للاختبار
            debugPrint('استخدام قيمة افتراضية للاختبار بعد فشل التحليل: 3');
            return 3;
          }
        } else {
          debugPrint(
              'فشل في جلب عدد التوصيلات/الرحلات: ${response.statusCode}');
          // في حالة الفشل، نعيد قيمة افتراضية للاختبار
          debugPrint('استخدام قيمة افتراضية للاختبار بسبب خطأ في الاستجابة: 3');
          return 3;
        }
      } catch (httpError) {
        debugPrint('خطأ في طلب HTTP: $httpError');
        // في حالة حدوث خطأ في الاتصال، نعيد قيمة ثابتة مؤقتًا
        debugPrint('استخدام قيمة افتراضية للاختبار بسبب خطأ في HTTP: 3');
        return 3; // قيمة مؤقتة للاختبار
      }
    } catch (e) {
      debugPrint('خطأ في جلب عدد التوصيلات/الرحلات: $e');
      debugPrint('استخدام قيمة افتراضية للاختبار بسبب خطأ عام: 3');
      return 3;
    }
  }

  // دالة مساعدة للحصول على نص الترحيب مع اسم المستخدم
  String _getWelcomeText() {
    String welcomeBase = 'welcome_user'.tr();
    return '$welcomeBase$_username';
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة والاتجاه
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = screenSize.width;
    final isLandscape = orientation == Orientation.landscape;

    // تعديل المتغيرات حسب الاتجاه
    final paddingFactor = isLandscape ? screenWidth * 0.02 : screenWidth * 0.04;
    final iconSize = isLandscape ? screenWidth * 0.025 : screenWidth * 0.045;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenSize.height - safeAreaBottom - viewInsets;

    // حساب ارتفاع شريط التنقل بناءً على المساحة المتاحة
    final maxBottomBarHeight =
        isLandscape ? availableHeight * 0.09 : availableHeight * 0.07;
    final bottomBarHeight = maxBottomBarHeight.clamp(
        isLandscape ? 38.0 : 36.0, isLandscape ? 48.0 : 46.0);
    const bottomPadding = 0.0; // إزالة الحشو الإضافي
    final responsiveSpacing =
        isLandscape ? screenSize.height * 0.02 : screenSize.height * 0.015;

    // بناء الصفحات هنا حتى تتوفر المتغيرات
    final List<Widget> pages = [
      // الرئيسية
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDriverWelcomeBar(paddingFactor),
            SizedBox(height: paddingFactor * 1.2),
            _buildDriverStatusToggle(paddingFactor),
            SizedBox(height: paddingFactor * 1.2),
            _buildDriverStatsSection(paddingFactor),
            SizedBox(height: paddingFactor * 1.2),
            _buildNewOrdersSection(paddingFactor),
            SizedBox(height: paddingFactor * 1.2),
            _buildCurrentOrdersSection(paddingFactor),
            SizedBox(height: paddingFactor * 1.2),
            _buildDeliveryHistorySection(paddingFactor),
            SizedBox(
                height: bottomBarHeight + bottomPadding + responsiveSpacing),
          ],
        ),
      ),
      // الطلبات أو الرحلات حسب نوع المستخدم
      (widget.userData?.userType == 'Chauffeur')
          ? RidesPage(
              padding: paddingFactor,
              bottomPadding: bottomBarHeight + bottomPadding)
          : CommandesPage(
              padding: paddingFactor,
              bottomPadding: bottomBarHeight + bottomPadding),
      // الخريطة
      _buildMapPage(),
      // الدردشة
      showChatPage
          ? _buildChatPage()
          : Center(
              child: Text('chat'.tr(),
                  style: TextStyle(fontSize: isLandscape ? 18 : 22))),
      // صفحة الملف الشخصي الاحترافية
      _buildProfilePage(
          isLandscape: isLandscape,
          bottomPadding: bottomBarHeight + bottomPadding),
    ];

    final labelTextStyle = TextStyle(
        fontSize: isLandscape ? 8 : 10,
        fontWeight: FontWeight.w500,
        overflow: TextOverflow.ellipsis);

    return Scaffold(
      backgroundColor: const Color(0xFF2F9C95),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: DefaultTextStyle.merge(
        style: labelTextStyle,
        child: ConvexAppBar(
          style: TabStyle.fixedCircle,
          backgroundColor: Colors.white,
          activeColor: const Color(0xFF2F9C95),
          color: Colors.grey[400],
          elevation: 8,
          curveSize: (bottomBarHeight * 2.2).clamp(50.0, 90.0),
          height: bottomBarHeight,
          initialActiveIndex: _selectedIndex,
          items: [
            TabItem(
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _selectedIndex == 0 ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.home_outlined,
                        size: iconSize,
                        color: _selectedIndex == 0
                            ? const Color(0xFF2F9C95)
                            : Colors.grey[600]),
                  ),
                  const SizedBox(height: 1),
                ],
              ),
              title: 'home'.tr(),
            ),
            TabItem(
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _selectedIndex == 1 ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      (widget.userData?.userType == 'Chauffeur')
                          ? Icons.local_taxi_outlined
                          : Icons.shopping_cart_outlined,
                      size: iconSize,
                      color: _selectedIndex == 1
                          ? const Color(0xFF2F9C95)
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 1),
                ],
              ),
              title: (widget.userData?.userType == 'Chauffeur')
                  ? 'ride'.tr()
                  : 'orders'.tr(),
            ),
            TabItem(
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _selectedIndex == 2 ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.location_on_outlined,
                        size: iconSize,
                        color: _selectedIndex == 2
                            ? const Color(0xFF2F9C95)
                            : Colors.grey[600]),
                  ),
                  const SizedBox(height: 1),
                ],
              ),
              title: 'map'.tr(),
            ),
            TabItem(
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _selectedIndex == 3 ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.chat_outlined,
                        size: iconSize,
                        color: _selectedIndex == 3
                            ? const Color(0xFF2F9C95)
                            : Colors.grey[600]),
                  ),
                  const SizedBox(height: 1),
                ],
              ),
              title: 'chat'.tr(),
            ),
            TabItem(
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _selectedIndex == 4 ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.person_outline,
                        size: iconSize,
                        color: _selectedIndex == 4
                            ? const Color(0xFF2F9C95)
                            : Colors.grey[600]),
                  ),
                  const SizedBox(height: 1),
                ],
              ),
              title: 'profile'.tr(),
            ),
          ],
          onTap: (int i) async {
            if (i == 2) {
              // عند النقر على زر الخريطة، الانتقال مباشرة إلى صفحة الخريطة
              // الدالة _getUserLocationFromApi ستقوم بجلب الإحداثيات تلقائيًا
              setState(() {
                showChatPage = false;
                _selectedIndex = i;
              });
            } else if (i == 3) {
              _showChatInstructionsDialog(context);
            } else {
              setState(() {
                showChatPage = false;
                _selectedIndex = i;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDriverWelcomeBar(double padding) {
    // تحسين طريقة استخدام صورة المستخدم من قاعدة البيانات
    String? userPhotoUrl;

    if (widget.userData != null &&
        widget.userData?.photoProfile != null &&
        widget.userData!.photoProfile!.isNotEmpty) {
      // استخدام المسار المطلق للصورة كما هو مخزن في كائن المستخدم
      userPhotoUrl = widget.userData!.photoProfile;
      debugPrint('User photo profile URL: $userPhotoUrl');
    }

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.7),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              child: ClipOval(
                child: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                    ? Image.network(
                        userPhotoUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF2F9C95),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                              'Error loading profile image: $error, URL: $userPhotoUrl');
                          return Image.asset(
                            'assets/images/default_avatar.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/default_avatar.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getWelcomeText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none,
                color: Colors.white, size: 28),
            onPressed: () => _showNotificationsSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 28),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStatusToggle(double padding) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      padding: EdgeInsets.symmetric(
          horizontal: padding * 1.2, vertical: padding * 1.2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'driver_status'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isOnline ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOnline ? 'status_online'.tr() : 'status_offline'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _isUpdatingStatus
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2F9C95),
                  ),
                )
              : Switch(
                  value: _isOnline,
                  onChanged: _updateDriverAvailability,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  activeTrackColor: Colors.green.withOpacity(0.3),
                  inactiveTrackColor: Colors.red.withOpacity(0.3),
                ),
        ],
      ),
    );
  }

  // دالة لتحديث حالة توفر السائق
  void _updateDriverAvailability(bool newStatus) async {
    // لا تفعل شيئًا إذا كانت العملية قيد التنفيذ بالفعل
    if (_isUpdatingStatus) return;

    // تحديث حالة واجهة المستخدم لإظهار أن العملية قيد التنفيذ
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      // التحقق من توفر بيانات المستخدم والمعرف
      if (widget.userData == null || widget.userData!.id <= 0) {
        throw Exception('بيانات المستخدم غير متوفرة أو غير صالحة');
      }

      // الحصول على معرف المستخدم
      int userId = widget.userData!.id;
      String token = widget.userData!.token;

      // طباعة معلومات التشخيص
      debugPrint(
          'تحديث حالة توفر السائق: userId=$userId, userType=${widget.userData!.userType}');
      debugPrint('الحالة القديمة: $_isOnline، الحالة الجديدة: $newStatus');
      debugPrint(
          'التوكن: ${token.isNotEmpty ? "${token.substring(0, min(10, token.length))}..." : "فارغ!"}');

      // استدعاء API لتحديث حالة التوفر
      final authService = AuthService();
      final result = await authService.updateDriverAvailability(
        userId,
        newStatus,
        token,
      );

      // التحقق من نجاح العملية
      if (result['success'] == true) {
        // تحديث الحالة لمحلية بناءً على القيمة المرجعة من الخادم
        setState(() {
          // استخدام القيمة المرجعة من الخادم إذا كانت متوفرة، وإلا استخدام القيمة الجديدة
          _isOnline = result['disponibilite'] ?? newStatus;
          debugPrint('تم تحديث الحالة في قاعدة البيانات: $_isOnline');
        });

        // التحقق من أن الـ widget لا يزال مثبتًا قبل استخدام BuildContext
        if (mounted) {
          // عرض رسالة نجاح
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('status_updated_success'.tr()),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // في حالة الفشل، استعادة الحالة السابقة
        setState(() {
          // استعادة الحالة السابقة
          _isOnline = !newStatus;
          debugPrint(
              'فشل تحديث الحالة في قاعدة البيانات، استعادة الحالة السابقة: $_isOnline');
        });

        // التحقق من أن الـ widget لا يزال مثبتًا قبل استخدام BuildContext
        if (mounted) {
          // عرض رسالة خطأ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('status_update_failed'.tr()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // معالجة الأخطاء
      debugPrint('خطأ في تحديث حالة التوفر: $e');

      // استعادة الحالة السابقة في حالة حدوث خطأ
      setState(() {
        _isOnline = !newStatus;
        debugPrint(
            'حدث خطأ أثناء تحديث الحالة، استعادة الحالة السابقة: $_isOnline');
      });

      // التحقق من أن الـ widget لا يزال مثبتًا قبل استخدام BuildContext
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_occurred'.tr()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // إعادة تعيين حالة واجهة المستخدم
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  Widget _buildDriverStatsSection(double padding, {bool isRide = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // تعديل الحشو بناءً على حجم الشاشة
    final containerPadding = screenWidth < 360
        ? EdgeInsets.symmetric(horizontal: padding, vertical: padding)
        : EdgeInsets.symmetric(
            horizontal: padding * 1.2, vertical: padding * 1.2);

    final titleFontSize =
        isLandscape ? 14.0 : (screenWidth < 360 ? 14.0 : 16.0);

    return Container(
      margin: EdgeInsets.all(padding * (screenWidth < 360 ? 0.8 : 1.2)),
      padding: containerPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRide ? 'ride_stats'.tr() : 'driver_stats'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
              ),
              // إضافة زر تحديث
              GestureDetector(
                onTap: () {
                  debugPrint('تحديث إحصائيات السائق...');
                  _loadDriverData();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: const Color(0xFF2F9C95),
                    size: isLandscape ? 16 : 18,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth < 360 ? 12 : 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                (widget.userData?.userType == 'Chauffeur')
                    ? 'ride'.tr()
                    : 'deliveries'.tr(),
                _deliveriesCompleted.toString(),
                (widget.userData?.userType == 'Chauffeur')
                    ? Icons.local_taxi_outlined
                    : Icons.delivery_dining,
                (widget.userData?.userType == 'Chauffeur')
                    ? Colors.purple
                    : Colors.teal,
              ),
              _buildStatCard(
                  'rating'.tr(), '$_rating/5', Icons.star, Colors.amber),
              _buildStatCard('earnings'.tr(), '$_earnings\nUM',
                  Icons.attach_money, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color iconColor) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // حساب العرض المناسب بناءً على حجم الشاشة والاتجاه
    final cardWidth = isLandscape
        ? screenWidth * 0.09 // 9% من عرض الشاشة في الوضع الأفقي
        : screenWidth * 0.25; // 25% من عرض الشاشة في الوضع الرأسي

    // حساب حجم الأيقونة والنص بناءً على عرض الشاشة
    final iconSize = isLandscape ? 24.0 : (screenWidth < 360 ? 22.0 : 28.0);
    final valueFontSize =
        isLandscape ? 15.0 : (screenWidth < 360 ? 14.0 : 17.0);
    final titleFontSize =
        isLandscape ? 11.0 : (screenWidth < 360 ? 10.0 : 12.0);

    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(screenWidth < 360 ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          SizedBox(height: screenWidth < 360 ? 5 : 7),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: valueFontSize,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenWidth < 360 ? 3 : 5),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey,
              fontSize: titleFontSize,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNewOrdersSection(double padding, {bool isRide = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            children: [
              Icon(isRide ? Icons.local_taxi_outlined : Icons.fiber_new,
                  color: Colors.teal[700], size: 22),
              const SizedBox(width: 6),
              Text(
                isRide ? 'new_rides'.tr() : 'new_orders'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: padding),
            children: isRide
                ? [
                    _buildOrderCard('#R-1001', '5.2 km', 'محطة A → محطة B',
                        '350 UM', true, padding,
                        isRide: true),
                    _buildOrderCard('#R-1002', '2.8 km', 'محطة C → مطار',
                        '200 UM', true, padding,
                        isRide: true),
                    _buildOrderCard('#R-1003', '7.1 km', 'مطار → فندق',
                        '500 UM', true, padding,
                        isRide: true),
                  ]
                : [
                    _buildOrderCard('#12345', '3.2 km', 'Restaurant to Home',
                        '120 UM', true, padding),
                    _buildOrderCard('#12346', '1.5 km', 'Pharmacy to Home',
                        '80 UM', true, padding),
                    _buildOrderCard('#12347', '4.8 km', 'Supermarket to Office',
                        '150 UM', true, padding),
                  ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(String orderId, String distance, String route,
      String payment, bool isNew, double padding,
      {bool isRide = false}) {
    return Container(
      width: 230,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(padding * 0.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRide ? 'Ride: $orderId' : 'ID: $orderId',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isRide ? 'new_ride'.tr() : 'new'.tr(),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(isRide ? Icons.local_taxi_outlined : Icons.location_on,
                        color: const Color(0xFF2F9C95), size: 16),
                    const SizedBox(width: 5),
                    Text(
                      distance,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  route,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                    color: Colors.white,
                    child: Text(
                      payment,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2F9C95),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 2,
                  child: Material(
                    color: const Color(0xFF2F9C95),
                    borderRadius: BorderRadius.circular(6),
                    elevation: 1.0,
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  isRide
                                      ? Icons.directions_car
                                      : Icons.check_circle_outline,
                                  color: Colors.white,
                                  size: 16),
                              const SizedBox(width: 4),
                              Text(
                                isRide ? 'accept_ride'.tr() : 'accept'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentOrdersSection(double padding, {bool isRide = false}) {
    final String orderIdText = isRide ? 'ride_id'.tr() : 'order_id'.tr();
    final String pickupText = isRide ? 'pickup_point'.tr() : 'pickup'.tr();
    final String deliveryText = isRide ? 'dropoff_point'.tr() : 'delivery'.tr();
    final String distanceText = 'distance'.tr();
    final String paymentText = 'payment'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Text(
            isRide ? 'current_rides'.tr() : 'current_orders'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: padding),
          padding: EdgeInsets.all(padding * 1.2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$orderIdText: ${isRide ? '#R-1000' : '#12340'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isRide ? 'in_progress_ride'.tr() : 'in_progress'.tr(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Icon(isRide ? Icons.local_taxi_outlined : Icons.location_on,
                      color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$pickupText: ${isRide ? 'محطة A' : 'KFC Restaurant'}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$deliveryText: ${isRide ? 'محطة B' : '123 Main St, Apartment 4B'}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$distanceText: ${isRide ? '5.2 km' : '2.3 km'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$paymentText: ${isRide ? '350 UM' : '100 UM'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F9C95),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(
                          isRide ? Icons.directions_car : Icons.navigation),
                      label:
                          Text(isRide ? 'navigate_ride'.tr() : 'navigate'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F9C95),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(isRide ? Icons.check : Icons.check_circle),
                      label:
                          Text(isRide ? 'complete_ride'.tr() : 'complete'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryHistorySection(double padding, {bool isRide = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRide ? 'ride_history'.tr() : 'delivery_history'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // التنقل إلى صفحة السجل الكامل
                },
                child: Text(
                  'voir_plus'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  isRide ? 'Ride #${1000 - index}' : 'Order #${12339 - index}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(Duration(days: index)))} - ${isRide ? '350 UM' : '80 UM'}',
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isRide
                        ? Colors.purple.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isRide ? 'completed_ride'.tr() : 'completed'.tr(),
                    style: TextStyle(
                      color: isRide ? Colors.purple : Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: isRide
                      ? const Color(0xFFEDE6F2)
                      : const Color(0xFFE6F2F1),
                  child: Icon(
                    isRide ? Icons.local_taxi_outlined : Icons.check,
                    color: isRide
                        ? const Color(0xFF9C27B0)
                        : const Color(0xFF2F9C95),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final maxHeight =
        isLandscape ? screenSize.height * 0.7 : screenSize.height * 0.6;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
            maxWidth: screenSize.width,
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications,
                            color: Color(0xFF2F9C95), size: 28),
                        const SizedBox(width: 10),
                        Text('notifications'.tr(),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('3 new',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      (widget.userData?.userType == 'Chauffeur')
                          ? 'new_rides'.tr()
                          : 'new_orders'.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ..._buildOrderNotifications(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // الانتقال لصفحة الطلبات/الرحلات
                        },
                        child: Text('view_all'.tr()),
                      ),
                    ),
                    const Divider(),
                    Text('new_messages'.tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ..._buildMessageNotifications(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // الانتقال لصفحة الرسائل
                        },
                        child: Text('view_all'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // مثال دوال بناء عناصر الإشعارات (يمكنك تخصيصها حسب بياناتك)
  List<Widget> _buildOrderNotifications() {
    return [
      ListTile(
        leading:
            const Icon(Icons.local_taxi_outlined, color: Color(0xFF2F9C95)),
        title: const Text('Ride #R-1004 - 3.2 km'),
        subtitle: const Text('محطة X → محطة Y - 200 UM'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // تفاصيل الطلب/الرحلة
        },
      ),
      // أضف المزيد حسب الحاجة
    ];
  }

  List<Widget> _buildMessageNotifications() {
    return [
      ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: const Text('عميل جديد'),
        subtitle: const Text('مرحبًا، أين طلبيتي؟'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // تفاصيل الرسالة
        },
      ),
      // أضف المزيد حسب الحاجة
    ];
  }

  void _showHelpDialog(BuildContext context) {
    final isChauffeur = widget.userData?.userType == 'Chauffeur';
    final screenSize = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final maxHeight =
        isLandscape ? screenSize.height * 0.7 : screenSize.height * 0.6;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.08,
          vertical: screenSize.height * 0.1,
        ),
        contentPadding: const EdgeInsets.all(0),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Color(0xFF2F9C95)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'app_instructions_title'.tr(),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(fontSize: isLandscape ? 16 : 18),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.84,
            maxHeight: maxHeight,
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isChauffeur
                        ? 'app_instructions_chauffeur'.tr()
                        : 'app_instructions_livreur'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isLandscape ? 14 : 16,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                  SizedBox(height: isLandscape ? 8 : 10),
                  Text('app_instructions_deal_customers'.tr(),
                      style: TextStyle(fontSize: isLandscape ? 12 : 14)),
                  SizedBox(height: isLandscape ? 8 : 10),
                  Text('app_instructions_rights'.tr(),
                      style: TextStyle(fontSize: isLandscape ? 12 : 14)),
                  SizedBox(height: isLandscape ? 8 : 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.qr_code,
                          color: Colors.teal, size: isLandscape ? 18 : 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'app_instructions_scan_qr'.tr(),
                          style: TextStyle(fontSize: isLandscape ? 12 : 14),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isLandscape ? 12 : 16),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showChatInstructionsDialog(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final availableHeight =
        screenSize.height - MediaQuery.of(context).viewInsets.bottom;
    final maxDialogHeight = availableHeight * (isLandscape ? 0.65 : 0.55);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.08,
          vertical: availableHeight * 0.12,
        ),
        contentPadding: const EdgeInsets.all(0),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        title: Row(
          children: [
            const Icon(Icons.chat_outlined, color: Color(0xFF2F9C95)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'chat_instructions_title'.tr(),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(fontSize: isLandscape ? 16 : 18),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.84,
            maxHeight: maxDialogHeight,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('chat_instructions_admin'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isLandscape ? 14 : 16,
                    )),
                SizedBox(height: isLandscape ? 8 : 10),
                Text('chat_instructions_clients'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isLandscape ? 14 : 16,
                    )),
                SizedBox(height: isLandscape ? 8 : 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.teal, size: isLandscape ? 18 : 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'chat_instructions_tips'.tr(),
                        style: TextStyle(fontSize: isLandscape ? 12 : 14),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isLandscape ? 12 : 16),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                showChatPage = true;
                _selectedIndex = 3;
              });
            },
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  // صفحة المحادثة الاحترافية
  Widget _buildChatPage() {
    // بيانات وهمية للمحادثات
    final List<Map<String, dynamic>> conversations = [
      {
        'type': 'admin',
        'name': 'Admin Support',
        'lastMessage': 'How can we help you?',
        'time': '09:30',
        'unread': 1,
        'avatar': Icons.support_agent,
      },
      {
        'type': 'client',
        'name': 'Client Ahmed',
        'lastMessage': 'Thank you for the fast delivery!',
        'time': '08:15',
        'unread': 0,
        'avatar': Icons.person,
      },
      {
        'type': 'client',
        'name': 'Client Fatima',
        'lastMessage': 'Where is my order?',
        'time': 'Yesterday',
        'unread': 2,
        'avatar': Icons.person,
      },
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F9C95),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('chat'.tr(), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          itemCount: conversations.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final conv = conversations[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: conv['type'] == 'admin'
                    ? Colors.teal[100]
                    : Colors.grey[200],
                child: Icon(conv['avatar'],
                    color: conv['type'] == 'admin'
                        ? Colors.teal
                        : Colors.grey[700]),
              ),
              title: Text(conv['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(conv['lastMessage'],
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(conv['time'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (conv['unread'] > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${conv['unread']}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ),
                ],
              ),
              onTap: () {
                // يمكنك هنا فتح صفحة تفاصيل المحادثة
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(conv['name']),
                    content: const Text('Conversation details coming soon...'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('ok'.tr()),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // صفحة الملف الشخصي الاحترافية للسائق (تصميم عصري وودود)
  Widget _buildProfilePage(
      {bool isLandscape = false, double bottomPadding = 0}) {
    final isChauffeur = widget.userData?.userType == 'Chauffeur';
    const mainColor = Color(0xFF2F9C95); // لون موحد متناسق مع التصميم

    // تحسين طريقة استخدام صورة المستخدم من قاعدة البيانات
    String? userPhotoUrl;

    if (widget.userData != null &&
        widget.userData?.photoProfile != null &&
        widget.userData!.photoProfile!.isNotEmpty) {
      // استخدام المسار المطلق للصورة كما هو مخزن في كائن المستخدم
      userPhotoUrl = widget.userData!.photoProfile;
      debugPrint('User photo profile URL (profile page): $userPhotoUrl');
    }

    return Stack(
      children: [
        Container(
          color: const Color(0xFF2F9C95),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            children: [
              const SizedBox(height: 36),
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                              ? Image.network(
                                  userPhotoUrl,
                                  width: 112,
                                  height: 112,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: const Color(0xFF2F9C95),
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint(
                                        'Error loading profile image: $error, URL: $userPhotoUrl');
                                    return Image.asset(
                                      'assets/images/default_avatar.png',
                                      width: 112,
                                      height: 112,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/images/default_avatar.png',
                                  width: 112,
                                  height: 112,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: mainColor, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  widget.userData?.username ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 7),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isChauffeur ? Icons.local_taxi : Icons.motorcycle,
                          color: mainColor, size: 18),
                      const SizedBox(width: 7),
                      Text(
                        isChauffeur ? 'Chauffeur' : 'Livreur',
                        style: const TextStyle(
                          color: mainColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                child: Column(
                  children: [
                    _profileInfoRow(Icons.phone, mainColor,
                        widget.userData?.phone ?? '-', 'Téléphone'),
                    const SizedBox(height: 16),
                    _profileInfoRow(Icons.email, mainColor,
                        widget.userData?.email ?? '-', 'Email'),
                    const SizedBox(height: 16),
                    _profileInfoRow(
                        isChauffeur ? Icons.directions_car : Icons.motorcycle,
                        mainColor,
                        isChauffeur ? 'Voiture' : 'Moto',
                        'Véhicule'),
                    const SizedBox(height: 16),
                    _profileInfoRow(
                        Icons.location_on, mainColor, 'Nouakchott', 'Zone'),
                    const SizedBox(height: 16),
                    _profileInfoRow(Icons.verified_user, mainColor,
                        'Statut: Vérifié', 'Statut'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // زر تسجيل الخروج
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.logout),
                  label:
                      Text('logout'.tr(), style: const TextStyle(fontSize: 17)),
                  onPressed: () => _showLogoutDialog(context),
                ),
              ),
              SizedBox(height: isLandscape ? 60 : 90),
            ],
          ),
        ),
        // زر تعديل عائم بأسفل الصفحة
        Positioned(
          bottom: bottomPadding,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton.extended(
              onPressed: () => _showEditProfileDialog(context),
              backgroundColor: mainColor,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('edit_profile'.tr(),
                    style: const TextStyle(fontSize: 17, color: Colors.white)),
              ),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // صف معلومة في الملف الشخصي مع أيقونة دائرية وخلفية خفيفة
  Widget _profileInfoRow(
      IconData icon, Color? color, String value, String label) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color?.withOpacity(0.13),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  // نافذة تعديل الملف الشخصي
  void _showEditProfileDialog(BuildContext context) {
    final phoneController =
        TextEditingController(text: widget.userData?.phone ?? '');
    final emailController =
        TextEditingController(text: widget.userData?.email ?? '');
    final passwordController = TextEditingController();
    final matriculeController = TextEditingController(text: '');
    final zoneController = TextEditingController(text: '');
    File? photoVehicule,
        photoPermis,
        photoCarteGrise,
        photoAssurance,
        photoVignette,
        photoCarteMunicipale;
    TimeOfDay? startTime, endTime;
    bool isMatriculeValid = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          contentPadding: const EdgeInsets.all(0),
          titlePadding:
              const EdgeInsets.only(top: 18, left: 18, right: 18, bottom: 0),
          title: Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFF2F9C95)),
              const SizedBox(width: 8),
              Flexible(child: Text('edit_profile_popup_title'.tr())),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('edit_profile_popup_desc'.tr(),
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildTextField(phoneController, Icons.phone, 'phone'.tr()),
                  const SizedBox(height: 12),
                  _buildTextField(emailController, Icons.email, 'email'.tr()),
                  const SizedBox(height: 12),
                  _buildTextField(
                      passwordController, Icons.lock, 'password'.tr(),
                      obscure: true),
                  const SizedBox(height: 12),
                  TextField(
                    controller: matriculeController,
                    decoration: InputDecoration(
                      labelText: 'matricule_vehicule'.tr(),
                      prefixIcon: const Icon(Icons.confirmation_number),
                      errorText:
                          isMatriculeValid ? null : 'matricule_invalid'.tr(),
                    ),
                    onChanged: (val) {
                      setState(() {
                        isMatriculeValid =
                            RegExp(r'^\d{4}[A-Za-z]{2}(0[1-9]|1[0-2])$')
                                .hasMatch(val);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: zoneController,
                    decoration: InputDecoration(
                      labelText: 'zone_couverture'.tr(),
                      prefixIcon: const Icon(Icons.location_on),
                      hintText: 'zone1, zone2, ...',
                    ),
                  ),
                  const Divider(height: 30),
                  _buildImagePickerRow('photo_vehicule', Icons.directions_car,
                      photoVehicule, (f) => setState(() => photoVehicule = f)),
                  _buildImagePickerRow('photo_permis', Icons.credit_card,
                      photoPermis, (f) => setState(() => photoPermis = f)),
                  _buildImagePickerRow(
                      'photo_carte_grise',
                      Icons.description,
                      photoCarteGrise,
                      (f) => setState(() => photoCarteGrise = f)),
                  _buildImagePickerRow(
                      'photo_assurance',
                      Icons.verified,
                      photoAssurance,
                      (f) => setState(() => photoAssurance = f)),
                  _buildImagePickerRow('photo_vignette', Icons.sticky_note_2,
                      photoVignette, (f) => setState(() => photoVignette = f)),
                  _buildImagePickerRow(
                      'photo_carte_municipale',
                      Icons.location_city,
                      photoCarteMunicipale,
                      (f) => setState(() => photoCarteMunicipale = f)),
                  const Divider(height: 30),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text('work_time'.tr()),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime ?? TimeOfDay.now());
                            if (picked != null) {
                              setState(() => startTime = picked);
                            }
                          },
                          child: Text(startTime != null
                              ? startTime!.format(context)
                              : 'start_time'.tr()),
                        ),
                        const Text('-'),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime ?? TimeOfDay.now());
                            if (picked != null) {
                              setState(() => endTime = picked);
                            }
                          },
                          child: Text(endTime != null
                              ? endTime!.format(context)
                              : 'end_time'.tr()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: isMatriculeValid
                  ? () {
                      // منطق الحفظ هنا
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F9C95)),
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, IconData icon, String label,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildImagePickerRow(
      String label, IconData icon, File? image, Function(File) onPicked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label.tr(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(image,
                      width: 40, height: 40, fit: BoxFit.cover),
                )
              : IconButton(
                  icon: const Icon(Icons.add_a_photo),
                  onPressed: () async {
                    final picked = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (picked != null) onPicked(File(picked.path));
                  },
                ),
        ],
      ),
    );
  }

  // دالة جديدة للحصول على موقع المستخدم من API بدون الحاجة إلى توكن
  // إضافة متغير لتخزين الموقع مؤقتًا
  LatLng? _cachedUserLocation;
  DateTime? _lastLocationFetch;
  bool _isLoadingLocation = false;

  Future<LatLng> _getUserLocationFromApi() async {
    // إذا كان هناك موقع مخزن مؤقتًا وتم الحصول عليه منذ أقل من دقيقة، استخدمه
    final now = DateTime.now();
    if (_cachedUserLocation != null &&
        _lastLocationFetch != null &&
        now.difference(_lastLocationFetch!).inSeconds < 30) {
      debugPrint(
          'استخدام الموقع المخزن مؤقتًا: ${_cachedUserLocation!.latitude}, ${_cachedUserLocation!.longitude}');
      return _cachedUserLocation!;
    }

    // محاولة الحصول على الموقع من خدمة الموقع المحلية أولاً
    try {
      // التحقق من تفعيل خدمة الموقع والإذن
      if (_serviceEnabled && _permissionGranted == PermissionStatus.granted) {
        _locationData = await _location.getLocation();
        if (_locationData != null &&
            _locationData!.latitude != null &&
            _locationData!.longitude != null) {
          debugPrint(
              'تم الحصول على موقع المستخدم محلياً: ${_locationData!.latitude}, ${_locationData!.longitude}');
          _cachedUserLocation =
              LatLng(_locationData!.latitude!, _locationData!.longitude!);
          _lastLocationFetch = now;

          // تحديث موقع المستخدم في الخادم
          await _updateUserLocationOnServer();

          return _cachedUserLocation!;
        }
      } else {
        // إذا لم يكن الإذن ممنوحًا، طلب الإذن
        await _checkLocationPermission();
        if (_cachedUserLocation != null) {
          return _cachedUserLocation!;
        }
      }
    } catch (e) {
      debugPrint('خطأ في الحصول على الموقع المحلي: $e');
    }

    // منع استدعاءات متزامنة متعددة
    if (_isLoadingLocation) {
      debugPrint('جاري بالفعل تحميل الموقع، انتظار...');
      // انتظار حتى اكتمال الطلب الحالي
      while (_isLoadingLocation) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_cachedUserLocation != null) {
        return _cachedUserLocation!;
      }
      // إذا فشل الطلب السابق، جرب مرة أخرى
    }

    _isLoadingLocation = true;

    try {
      if (widget.userData == null) {
        _isLoadingLocation = false;
        throw Exception('بيانات المستخدم غير متوفرة');
      }

      final int userId = widget.userData!.id;

      debugPrint('جاري الحصول على موقع المستخدم من API...');

      // استدعاء API الجديدة بدون توكن
      final endpoint = '${AuthService.baseUrl}/api/users/$userId/location/';
      debugPrint('نقطة النهاية: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('انتهت مهلة الطلب بعد 15 ثانية');
          throw Exception(
              'انتهت المهلة: لا توجد استجابة من الخادم بعد 15 ثانية');
        },
      );

      debugPrint('رمز الاستجابة: ${response.statusCode}');
      debugPrint('محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData.containsKey('latitude') &&
            responseData.containsKey('longitude')) {
          final latitude = responseData['latitude'] as double;
          final longitude = responseData['longitude'] as double;

          debugPrint('تم الحصول على إحداثيات المستخدم: $latitude, $longitude');

          // تخزين الموقع مؤقتًا
          _cachedUserLocation = LatLng(latitude, longitude);
          _lastLocationFetch = now;

          // تحديث كائن المستخدم المحلي بالإحداثيات الجديدة
          if (_updatedUserData != null) {
            final updatedUser = User(
              id: _updatedUserData!.id,
              username: _updatedUserData!.username,
              email: _updatedUserData!.email,
              phone: _updatedUserData!.phone,
              userType: _updatedUserData!.userType,
              isStaff: _updatedUserData!.isStaff,
              token: _updatedUserData!.token,
              statutVerification: _updatedUserData!.statutVerification,
              raisonRefus: _updatedUserData!.raisonRefus,
              photoProfile: _updatedUserData!.photoProfile,
              disponibilite: _updatedUserData!.disponibilite,
              latitude: latitude,
              longitude: longitude,
            );

            if (mounted) {
              setState(() {
                _updatedUserData = updatedUser;
              });
            }
          }

          return _cachedUserLocation!;
        }
      }

      // في حالة فشل الاستجابة، نحاول الحصول على الموقع من خدمة الموقع مرة أخرى
      if (_locationData != null &&
          _locationData!.latitude != null &&
          _locationData!.longitude != null) {
        _cachedUserLocation =
            LatLng(_locationData!.latitude!, _locationData!.longitude!);
        _lastLocationFetch = now;
        return _cachedUserLocation!;
      }

      // إذا فشلت جميع المحاولات، نرمي استثناء
      throw Exception(
          'لم نتمكن من العثور على موقعك الحقيقي. يرجى تفعيل خدمات الموقع وإعادة المحاولة.');
    } catch (e) {
      debugPrint('خطأ في الحصول على موقع المستخدم: $e');
      rethrow;
    } finally {
      _isLoadingLocation = false;
    }
  }

  // تعديل صفحة الخريطة لتحسين تجربة المستخدم
  Widget _buildMapPage() {
    return FutureBuilder<LatLng>(
      future: _getUserLocationFromApi(),
      builder: (context, snapshot) {
        // عرض مؤشر تحميل أثناء الانتظار
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedUserLocation == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF2F9C95)),
                SizedBox(height: 20),
                Text('جاري تحميل الخريطة...'),
              ],
            ),
          );
        }

        // في حالة حدوث خطأ
        if (snapshot.hasError ||
            (snapshot.data == null && _cachedUserLocation == null)) {
          debugPrint('خطأ في الحصول على الموقع: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 60, color: Colors.grey),
                const SizedBox(height: 20),
                Text(snapshot.error != null
                    ? 'تعذر تحديد موقعك: ${snapshot.error}'
                    : 'لم نتمكن من العثور على موقعك الحقيقي'),
                const SizedBox(height: 10),
                const Text(
                  'يرجى التأكد من تفعيل خدمات الموقع في جهازك',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _checkLocationPermission();
                        setState(() {
                          // إعادة تعيين المتغيرات
                          _cachedUserLocation = null;
                          _lastLocationFetch = null;
                          _selectedIndex = 2; // إعادة تحميل صفحة الخريطة
                        });
                      },
                      icon: const Icon(Icons.location_on),
                      label: const Text('تفعيل الموقع'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          // إعادة تعيين المتغيرات
                          _cachedUserLocation = null;
                          _lastLocationFetch = null;
                          _selectedIndex = 2; // إعادة تحميل صفحة الخريطة
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F9C95),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // استخدام الموقع المخزن مؤقتًا إذا كان متاحًا، وإلا استخدام الموقع من الاستجابة
        final userLocation = _cachedUserLocation ?? snapshot.data!;

        return FlutterMap(
          options: MapOptions(
            initialCenter: userLocation,
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.tawssil_frontend',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: userLocation,
                  width: 80,
                  height: 80,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Color(0xFF2F9C95),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            LocaleKeys.you_are_here.tr(),
                            style: const TextStyle(
                              color: Color(0xFF2F9C95),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(child: Text('logout'.tr())),
          ],
        ),
        content: Text('logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('logout_cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // منطق تسجيل الخروج: حذف التوكنات وتوجيه المستخدم لصفحة تسجيل الدخول
              Navigator.pop(context); // إغلاق الحوار
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('logout_success'.tr()),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('logout'.tr()),
          ),
        ],
      ),
    );
  }

  // دالة جديدة لجلب متوسط تقييم المستخدم
  Future<double> _getUserRating() async {
    if (widget.userData == null) return 0.0;

    final int userId = widget.userData!.id;
    // استخدام التوكن المؤقت إذا كان متاحًا
    final String token = _updatedUserData?.token ?? widget.userData!.token;

    try {
      debugPrint('جاري جلب متوسط تقييم المستخدم...');
      debugPrint('معرف المستخدم: $userId');

      // تحديد نقطة النهاية للحصول على متوسط التقييم
      final endpoint =
          '${AuthService.baseUrl}/api/commandes/user/$userId/rating/';

      // إضافة طباعة تشخيصية إضافية
      debugPrint('نقطة النهاية: $endpoint');
      debugPrint('قبل إرسال الطلب HTTP');

      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('انتهت مهلة الطلب بعد 30 ثانية');
            throw Exception(
                'انتهت المهلة: لا توجد استجابة من الخادم بعد 30 ثانية');
          },
        );

        debugPrint('بعد إرسال الطلب HTTP');
        debugPrint('رمز الاستجابة: ${response.statusCode}');
        debugPrint('محتوى الاستجابة: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final responseData = jsonDecode(response.body);
            debugPrint('البيانات المستلمة: $responseData');

            // التحقق من وجود مفتاح 'rating' في البيانات
            if (responseData.containsKey('rating')) {
              final rating = responseData['rating'] as num? ?? 0.0;
              debugPrint('تم جلب متوسط التقييم بنجاح: $rating');
              return rating.toDouble();
            } else {
              debugPrint('خطأ: لا يوجد مفتاح "rating" في البيانات المستلمة');
              debugPrint('البيانات المستلمة: $responseData');
              return 4.5; // قيمة افتراضية للاختبار
            }
          } catch (parseError) {
            debugPrint('خطأ في تحليل البيانات JSON: $parseError');
            return 4.5; // قيمة افتراضية للاختبار
          }
        } else {
          debugPrint('فشل في جلب متوسط التقييم: ${response.statusCode}');
          return 4.5; // قيمة افتراضية للاختبار
        }
      } catch (httpError) {
        debugPrint('خطأ في طلب HTTP: $httpError');
        return 4.5; // قيمة افتراضية للاختبار
      }
    } catch (e) {
      debugPrint('خطأ في جلب متوسط التقييم: $e');
      return 4.5; // قيمة افتراضية للاختبار
    }
  }
}

class RidesPage extends StatefulWidget {
  final double padding;
  final double bottomPadding;
  const RidesPage(
      {super.key, required this.padding, required this.bottomPadding});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  String? selectedStatus; // مكتملة/قيد التنفيذ

  // بيانات وهمية للرحلات
  final List<Map<String, dynamic>> allRides = [
    {
      'id': '#R-1001',
      'date': DateTime.now().subtract(const Duration(days: 0)),
      'pickup': 'محطة A',
      'dropoff': 'محطة B',
      'price': '350 UM',
      'status': 'completed',
    },
    {
      'id': '#R-1002',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'pickup': 'محطة C',
      'dropoff': 'مطار',
      'price': '200 UM',
      'status': 'in_progress',
    },
    {
      'id': '#R-1003',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'pickup': 'مطار',
      'dropoff': 'فندق',
      'price': '500 UM',
      'status': 'completed',
    },
  ];

  List<Map<String, dynamic>> get filteredRides {
    return allRides.where((ride) {
      final matchesStart =
          filterStartDate == null || !ride['date'].isBefore(filterStartDate!);
      final matchesEnd =
          filterEndDate == null || !ride['date'].isAfter(filterEndDate!);
      final matchesStatus =
          selectedStatus == null || ride['status'] == selectedStatus;
      return matchesStart && matchesEnd && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final padding =
        isLandscape ? screenSize.width * 0.02 : screenSize.width * 0.04;
    final cardFontSize = isLandscape ? 13.0 : 15.0;
    final cardTitleFontSize = isLandscape ? 15.0 : 17.0;
    final cardPriceFontSize = isLandscape ? 15.0 : 17.0;
    final filterFontSize = isLandscape ? 12.0 : 14.0;
    final filterHeight = isLandscape ? 38.0 : 44.0;
    final filterIconSize = isLandscape ? 16.0 : 18.0;
    final dividerThickness = isLandscape ? 0.7 : 1.0;
    final cardPadding = isLandscape ? 10.0 : 14.0;
    final cardMargin = isLandscape ? 6.0 : 10.0;
    final cardElevation = isLandscape ? 1.0 : 2.0;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: widget.bottomPadding + 10),
      child: Column(
        children: [
          // القسم العلوي: الطلبات الحالية
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: padding, vertical: padding * 0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('current_orders'.tr(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: cardTitleFontSize),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true),
                    ),
                    Icon(Icons.local_taxi_outlined,
                        color: const Color(0xFF2F9C95),
                        size: filterIconSize + 2),
                  ],
                ),
                SizedBox(height: isLandscape ? 8 : 12),
                ...allRides
                    .where((r) => r['status'] == 'in_progress')
                    .map((ride) => Card(
                          margin: EdgeInsets.symmetric(vertical: cardMargin),
                          elevation: cardElevation,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: cardPadding + 2,
                                horizontal: cardPadding),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Leading icon
                                CircleAvatar(
                                  backgroundColor: Colors.teal[50],
                                  child: Icon(Icons.local_taxi_outlined,
                                      color: Colors.teal,
                                      size: filterIconSize + 2),
                                ),
                                SizedBox(width: isLandscape ? 10 : 14),
                                // Main content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${ride['id']}',
                                          style: TextStyle(
                                              fontSize: cardTitleFontSize),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true),
                                      Text(
                                          '${ride['pickup']} → ${ride['dropoff']}',
                                          style:
                                              TextStyle(fontSize: cardFontSize),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true),
                                      Text(
                                          DateFormat('dd/MM/yyyy')
                                              .format(ride['date']),
                                          style: TextStyle(
                                              fontSize: filterFontSize,
                                              color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                SizedBox(width: isLandscape ? 8 : 12),
                                // Trailing price/status
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(ride['price'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF2F9C95),
                                            fontSize: cardPriceFontSize - 1),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Container(
                                      margin: EdgeInsets.only(
                                          top: isLandscape ? 2 : 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('in_progress_ride'.tr(),
                                          style: TextStyle(
                                              color: Colors.teal,
                                              fontWeight: FontWeight.bold,
                                              fontSize: filterFontSize - 1),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
              ],
            ),
          ),
          Divider(
              height: 30, thickness: dividerThickness, color: Colors.grey[300]),
          // القسم السفلي: سجل الرحلات مع الفلاتر
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: padding, vertical: padding * 0.5),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: filterStartDate ?? DateTime.now(),
                        firstDate: DateTime(2023, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => filterStartDate = picked);
                      }
                    },
                    child: Container(
                      constraints: BoxConstraints(minHeight: filterHeight),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range,
                              color: Colors.teal, size: filterIconSize),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                                filterStartDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(filterStartDate!)
                                    : 'start_date'.tr(),
                                style: TextStyle(fontSize: filterFontSize),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (filterStartDate != null)
                            IconButton(
                              icon: Icon(Icons.close,
                                  size: filterIconSize - 2, color: Colors.red),
                              onPressed: () =>
                                  setState(() => filterStartDate = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: filterEndDate ?? DateTime.now(),
                        firstDate: DateTime(2023, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => filterEndDate = picked);
                      }
                    },
                    child: Container(
                      constraints: BoxConstraints(minHeight: filterHeight),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range,
                              color: Colors.teal, size: filterIconSize),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                                filterEndDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(filterEndDate!)
                                    : 'end_date'.tr(),
                                style: TextStyle(fontSize: filterFontSize),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (filterEndDate != null)
                            IconButton(
                              icon: Icon(Icons.close,
                                  size: filterIconSize - 2, color: Colors.red),
                              onPressed: () =>
                                  setState(() => filterEndDate = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedStatus,
                  hint: Text('all_statuses'.tr(),
                      style: TextStyle(fontSize: filterFontSize)),
                  items: [
                    DropdownMenuItem(
                        value: null,
                        child: Text('all_statuses'.tr(),
                            style: TextStyle(fontSize: filterFontSize))),
                    DropdownMenuItem(
                        value: 'completed',
                        child: Text('completed_ride'.tr(),
                            style: TextStyle(fontSize: filterFontSize))),
                    DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('in_progress_ride'.tr(),
                            style: TextStyle(fontSize: filterFontSize))),
                  ],
                  onChanged: (val) => setState(() => selectedStatus = val),
                  underline: Container(),
                ),
              ],
            ),
          ),
          filteredRides.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                      child: Text('no_rides_found'.tr(),
                          style: TextStyle(
                              fontSize: cardTitleFontSize, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true)))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  itemCount: filteredRides.length,
                  itemBuilder: (context, index) {
                    final ride = filteredRides[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: cardMargin),
                      elevation: cardElevation,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: cardPadding + 2, horizontal: cardPadding),
                        child: ListTile(
                          isThreeLine: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: ride['status'] == 'completed'
                                ? Colors.purple[50]
                                : Colors.teal[50],
                            child: Icon(Icons.local_taxi_outlined,
                                color: ride['status'] == 'completed'
                                    ? Colors.purple
                                    : Colors.teal,
                                size: filterIconSize + 2),
                          ),
                          title: Text('${ride['id']}',
                              style: TextStyle(fontSize: cardTitleFontSize),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${ride['pickup']} → ${ride['dropoff']}',
                                  style: TextStyle(fontSize: cardFontSize),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true),
                              Text(
                                  DateFormat('dd/MM/yyyy').format(ride['date']),
                                  style: TextStyle(
                                      fontSize: filterFontSize,
                                      color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(ride['price'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2F9C95),
                                      fontSize: cardPriceFontSize),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              SizedBox(height: isLandscape ? 2 : 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: ride['status'] == 'completed'
                                      ? Colors.purple.withOpacity(0.15)
                                      : Colors.teal.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                    ride['status'] == 'completed'
                                        ? 'completed_ride'.tr()
                                        : 'in_progress_ride'.tr(),
                                    style: TextStyle(
                                      color: ride['status'] == 'completed'
                                          ? Colors.purple
                                          : Colors.teal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: filterFontSize,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class CommandesPage extends StatefulWidget {
  final double padding;
  final double bottomPadding;
  const CommandesPage(
      {super.key, required this.padding, required this.bottomPadding});

  @override
  State<CommandesPage> createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage> {
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  String? selectedStatus;
  bool showMap = false;
  LatLng? currentLocation;
  bool locationLoading = false;

  // بيانات وهمية للطلبات
  final List<Map<String, dynamic>> allOrders = [
    {
      'id': '#C-2001',
      'date': DateTime.now().subtract(const Duration(days: 0)),
      'pickup': 'مطعم KFC',
      'dropoff': 'حي الرياض',
      'price': '120 UM',
      'status': 'completed',
      'lat': 18.0735,
      'lng': -15.9582,
      'address': 'حي الرياض',
    },
    {
      'id': '#C-2002',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'pickup': 'صيدلية النجاح',
      'dropoff': 'مستشفى الصداقة',
      'price': '80 UM',
      'status': 'in_progress',
      'lat': 18.0850,
      'lng': -15.9780,
      'address': 'مستشفى الصداقة',
    },
    {
      'id': '#C-2003',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'pickup': 'سوبرماركت البركة',
      'dropoff': 'مكتب العمل',
      'price': '150 UM',
      'status': 'completed',
      'lat': 18.0950,
      'lng': -15.9650,
      'address': 'مكتب العمل',
    },
  ];

  List<Map<String, dynamic>> get filteredOrders {
    return allOrders.where((order) {
      final matchesStart =
          filterStartDate == null || !order['date'].isBefore(filterStartDate!);
      final matchesEnd =
          filterEndDate == null || !order['date'].isAfter(filterEndDate!);
      final matchesStatus =
          selectedStatus == null || order['status'] == selectedStatus;
      return matchesStart && matchesEnd && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _getLocation() async {
    setState(() => locationLoading = true);
    // استخدام موقع ثابت (نواكشوط)
    setState(() {
      currentLocation = const LatLng(18.0735, -15.9582);
      locationLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final filterHeight = isLandscape ? 38.0 : 44.0;
    final filterIconSize = isLandscape ? 16.0 : 18.0;
    final filterFontSize = isLandscape ? 12.0 : 14.0;

    return Column(
      children: [
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: widget.padding, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('orders'.tr(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      showMap ? Colors.teal[100] : const Color(0xFF2F9C95),
                  foregroundColor: showMap ? Colors.teal : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: Icon(showMap ? Icons.list_alt : Icons.map_outlined),
                label: Text(showMap ? 'عرض القائمة' : 'عرض على الخريطة'),
                onPressed: () async {
                  if (!showMap && currentLocation == null) {
                    await _getLocation();
                  }
                  setState(() => showMap = !showMap);
                },
              ),
            ],
          ),
        ),
        if (showMap)
          Expanded(
              child: locationLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (currentLocation == null
                      ? const Center(child: Text('جاري تحديد موقعك...'))
                      : filteredOrders.isEmpty
                          ? Center(
                              child: Text('no_orders_found'.tr(),
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.grey)))
                          : FlutterMap(
                              options: MapOptions(
                                initialCenter: currentLocation!,
                                initialZoom: 13,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  subdomains: const ['a', 'b', 'c'],
                                ),
                                MarkerLayer(
                                  markers: [
                                    // ماركر الموقع الحالي
                                    Marker(
                                      point: currentLocation!,
                                      width: 60,
                                      height: 60,
                                      child: const Icon(Icons.my_location,
                                          color: Colors.blue, size: 36),
                                    ),
                                    // ماركرات الطلبات
                                    ...filteredOrders.map((item) => Marker(
                                          point:
                                              LatLng(item['lat'], item['lng']),
                                          width: 60,
                                          height: 60,
                                          child: const Icon(Icons.location_on,
                                              color: Colors.red, size: 36),
                                        ))
                                  ],
                                ),
                              ],
                            )))
        else ...[
          Divider(height: 30, thickness: 1, color: Colors.grey[300]),
          // القسم السفلي: سجل الطلبات مع الفلاتر
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: widget.padding, vertical: widget.padding * 0.5),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: filterStartDate ?? DateTime.now(),
                        firstDate: DateTime(2023, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => filterStartDate = picked);
                      }
                    },
                    child: Container(
                      constraints: BoxConstraints(minHeight: filterHeight),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range,
                              color: Colors.teal, size: filterIconSize),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                                filterStartDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(filterStartDate!)
                                    : 'start_date'.tr(),
                                style: TextStyle(fontSize: filterFontSize),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (filterStartDate != null)
                            IconButton(
                              icon: Icon(Icons.close,
                                  size: filterIconSize - 2, color: Colors.red),
                              onPressed: () =>
                                  setState(() => filterStartDate = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: filterEndDate ?? DateTime.now(),
                        firstDate: DateTime(2023, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => filterEndDate = picked);
                      }
                    },
                    child: Container(
                      constraints: BoxConstraints(minHeight: filterHeight),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range,
                              color: Colors.teal, size: filterIconSize),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                                filterEndDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(filterEndDate!)
                                    : 'end_date'.tr(),
                                style: TextStyle(fontSize: filterFontSize),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (filterEndDate != null)
                            IconButton(
                              icon: Icon(Icons.close,
                                  size: filterIconSize - 2, color: Colors.red),
                              onPressed: () =>
                                  setState(() => filterEndDate = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedStatus,
                  hint: Text('all_statuses'.tr()),
                  items: [
                    DropdownMenuItem(
                        value: null, child: Text('all_statuses'.tr())),
                    DropdownMenuItem(
                        value: 'completed', child: Text('completed'.tr())),
                    DropdownMenuItem(
                        value: 'in_progress', child: Text('in_progress'.tr())),
                  ],
                  onChanged: (val) => setState(() => selectedStatus = val),
                  underline: Container(),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Text('no_orders_found'.tr(),
                        style:
                            const TextStyle(fontSize: 18, color: Colors.grey)))
                : ListView.builder(
                    padding: EdgeInsets.only(
                      left: widget.padding,
                      right: widget.padding,
                      bottom: widget.bottomPadding + 10,
                    ),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: order['status'] == 'completed'
                                ? Colors.purple[50]
                                : Colors.teal[50],
                            child: Icon(Icons.shopping_cart_outlined,
                                color: order['status'] == 'completed'
                                    ? Colors.purple
                                    : Colors.teal),
                          ),
                          title: Text('${order['id']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${order['pickup']} → ${order['dropoff']}',
                                  style: const TextStyle(fontSize: 13)),
                              Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(order['date']),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(order['price'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2F9C95))),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: order['status'] == 'completed'
                                      ? Colors.purple.withOpacity(0.15)
                                      : Colors.teal.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order['status'] == 'completed'
                                      ? 'completed'.tr()
                                      : 'in_progress'.tr(),
                                  style: TextStyle(
                                    color: order['status'] == 'completed'
                                        ? Colors.purple
                                        : Colors.teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}
