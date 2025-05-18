import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    // استخدام اسم المستخدم إذا كان متاحاً، وإلا استخدام المعرف
    _username = widget.userData?.username ?? 'مستخدم';

    // مستقبلاً: استرجاع بيانات السائق من API
    _loadDriverData();
  }

  // دالة وهمية لتحميل بيانات السائق
  Future<void> _loadDriverData() async {
    // هنا سيتم استدعاء API لجلب بيانات السائق
    // للآن سنستخدم قيم ثابتة
    setState(() {
      _deliveriesCompleted = 42;
      _rating = 4.7;
    });
  }

  // دالة مساعدة للحصول على نص الترحيب مع اسم المستخدم
  String _getWelcomeText() {
    String welcomeBase = 'welcome_user'.tr();
    return '$welcomeBase$_username';
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // تحديد حجم العناصر بناءً على حجم الشاشة
    final paddingFactor = screenWidth * 0.04; // عامل تباعد نسبي
    final iconSize = screenWidth * 0.06; // حجم الأيقونات النسبي

    return Scaffold(
      backgroundColor: const Color(0xFF2F9C95),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // شريط الترحيب بالسائق
                _buildDriverWelcomeBar(paddingFactor),

                // حالة السائق وزر التبديل
                _buildDriverStatusToggle(paddingFactor),

                // إحصائيات السائق
                _buildDriverStatsSection(paddingFactor),

                // عرض الطلبات الجديدة
                _buildNewOrdersSection(paddingFactor),

                // عرض الطلبات الحالية
                _buildCurrentOrdersSection(paddingFactor),

                // سجل التوصيلات
                _buildDeliveryHistorySection(paddingFactor),

                // مساحة إضافية في الأسفل
                SizedBox(height: screenHeight * 0.1),
              ],
            ),
          );
        }),
      ),
      // شريط التنقل السفلي المخصص للسائق
      bottomNavigationBar: _buildCustomBottomNavigationBar(iconSize),

      // زر عائم للطوارئ
      floatingActionButton: FloatingActionButton(
        heroTag: "sosBtn",
        onPressed: () {
          _showSosDialog(context);
        },
        backgroundColor: Colors.red,
        child: const Icon(
          Icons.sos,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildDriverWelcomeBar(double padding) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    const AssetImage('assets/images/default_avatar.png'),
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint('Error loading avatar image: $exception');
                },
                child: null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getWelcomeText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _rating.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.userIdentifier,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none,
                    color: Colors.white, size: 28),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.help_outline,
                    color: Colors.white, size: 28),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStatusToggle(double padding) {
    return Container(
      margin:
          EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.5),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
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
          Switch(
            value: _isOnline,
            onChanged: (value) {
              setState(() {
                _isOnline = value;
              });
              // مستقبلاً: تحديث حالة السائق في قاعدة البيانات
            },
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
            activeTrackColor: Colors.green.withOpacity(0.3),
            inactiveTrackColor: Colors.red.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStatsSection(double padding) {
    return Container(
      margin: EdgeInsets.all(padding),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'driver_stats'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'total_deliveries'.tr(),
                _deliveriesCompleted.toString(),
                Icons.delivery_dining,
              ),
              _buildStatCard(
                'rating'.tr(),
                '$_rating/5',
                Icons.star,
              ),
              _buildStatCard(
                'earnings'.tr(),
                '12500\nUM',
                Icons.attach_money,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF2F9C95),
            size: 24,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNewOrdersSection(double padding) {
    final String orderIdText = 'order_id'.tr();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Text(
            'new_orders'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: padding),
            children: [
              _buildOrderCard(
                '$orderIdText: #12345',
                '3.2 km',
                'Restaurant to Home',
                '120 UM',
                true,
              ),
              _buildOrderCard(
                '$orderIdText: #12346',
                '1.5 km',
                'Pharmacy to Home',
                '80 UM',
                true,
              ),
              _buildOrderCard(
                '$orderIdText: #12347',
                '4.8 km',
                'Supermarket to Office',
                '150 UM',
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(String orderId, String distance, String route,
      String payment, bool isNew) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      orderId,
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
                          'new'.tr(),
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
                    const Icon(Icons.location_on,
                        color: Color(0xFF2F9C95), size: 16),
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
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'accept'.tr(),
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

  Widget _buildCurrentOrdersSection(double padding) {
    final String orderIdText = 'order_id'.tr();
    final String pickupText = 'pickup'.tr();
    final String deliveryText = 'delivery'.tr();
    final String distanceText = 'distance'.tr();
    final String paymentText = 'payment'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Text(
            'current_orders'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: padding),
          padding: EdgeInsets.all(padding),
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
                    '$orderIdText: #12340',
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
                      'in_progress'.tr(),
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
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$pickupText: KFC Restaurant',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$deliveryText: 123 Main St, Apartment 4B',
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
                    '$distanceText: 2.3 km',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$paymentText: 100 UM',
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
                      icon: const Icon(Icons.navigation),
                      label: Text('navigate'.tr()),
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
                      icon: const Icon(Icons.check_circle),
                      label: Text('complete'.tr()),
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

  Widget _buildDeliveryHistorySection(double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'delivery_history'.tr(),
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
                  'Order #${12339 - index}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(Duration(days: index)))} - 80 UM',
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'completed'.tr(),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE6F2F1),
                  child: Icon(
                    Icons.check,
                    color: Color(0xFF2F9C95),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // شريط التنقل المخصص
  Widget _buildCustomBottomNavigationBar(double iconSize) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.08,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // الرئيسية: أهم زر
            _buildNavItem(0, Icons.home_outlined, 'home', iconSize),
            // الطلبات: ثاني أهم زر
            _buildNavItem(1, Icons.assignment_outlined, 'orders', iconSize),
            // الخريطة: ثالث أهم زر
            _buildNavItem(2, Icons.location_on_outlined, 'map', iconSize),
            // الأرباح: رابع أهم زر
            _buildNavItem(
                3, Icons.account_balance_wallet_outlined, 'earnings', iconSize),
            // الرسائل: بدلاً من الملف الشخصي
            _buildNavItem(4, Icons.chat_outlined, 'chat', iconSize),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, String label, double iconSize) {
    bool isSelected = _selectedIndex == index;
    Color activeColor = const Color(0xFF2F9C95);

    double itemWidth = MediaQuery.of(context).size.width / 5;

    return SizedBox(
      width: itemWidth,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isSelected
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    )
                  : Icon(
                      icon,
                      color: Colors.grey,
                      size: iconSize,
                    ),
              const SizedBox(height: 4),
              Text(
                label.tr(),
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey,
                  fontSize: MediaQuery.of(context).size.width * 0.03,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog SOS
  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'emergency'.tr(),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'emergency_desc'.tr(),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Call emergency number
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.phone),
                label: Text('call_emergency'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  // Send SOS alert
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.notifications_active),
                label: Text('send_sos'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'cancel'.tr(),
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
