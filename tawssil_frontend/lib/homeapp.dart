import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'services/auth_service.dart';

class HomeApp extends StatefulWidget {
  final String userIdentifier; // يمكن أن يكون بريد إلكتروني أو رقم هاتف
  final User? userData; // بيانات المستخدم كاملة (اختياري)

  const HomeApp({
    super.key,
    required this.userIdentifier,
    this.userData,
  });

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  int _selectedIndex = 0;
  late String _username;

  @override
  void initState() {
    super.initState();
    // استخدام اسم المستخدم إذا كان متاحاً، وإلا استخدام المعرف
    _username = widget.userData?.username ?? widget.userIdentifier;
  }

  @override
  Widget build(BuildContext context) {
    // استخدام MediaQuery للحصول على أبعاد الشاشة
    final screenSize = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // حساب الأحجام المتجاوبة
    final paddingHorizontal = screenSize.width * 0.05;
    final paddingVertical = screenSize.height * 0.02;
    final categoryIconSize =
        isLandscape ? screenSize.height * 0.08 : screenSize.width * 0.15;

    // تعديل أبعاد البطاقات بناءً على اتجاه الشاشة
    final restaurantCardWidth =
        isLandscape ? screenSize.width * 0.18 : screenSize.width * 0.28;
    final restaurantCardHeight =
        isLandscape ? screenSize.height * 0.38 : screenSize.width * 0.4;

    // تعديل أحجام الخطوط والأيقونات
    final titleFontSize = isLandscape ? 18.0 : 16.0;
    final subtitleFontSize = isLandscape ? 16.0 : 14.0;
    final smallFontSize = isLandscape ? 14.0 : 12.0;
    final iconSize = isLandscape ? 28.0 : 24.0;
    final starSize = isLandscape ? 14.0 : 12.0;

    // متغيرات شريط التنقل السفلي
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenSize.height - safeAreaBottom - viewInsets;
    final bottomNavIconSize = isLandscape ? 22.0 : 20.0;

    // حساب ارتفاع شريط التنقل بناءً على المساحة المتاحة
    final maxBottomBarHeight =
        isLandscape ? availableHeight * 0.09 : availableHeight * 0.07;
    final bottomBarHeight = maxBottomBarHeight.clamp(
        isLandscape ? 38.0 : 36.0, isLandscape ? 48.0 : 46.0);
    final labelTextStyle = TextStyle(
        fontSize: isLandscape ? 8 : 10,
        fontWeight: FontWeight.w500,
        overflow: TextOverflow.ellipsis);

    // تحديد مسار الصورة الشخصية وتجربة مسارات مختلفة
    String? userPhotoUrl;

    if (widget.userData != null &&
        widget.userData?.photoProfile != null &&
        widget.userData!.photoProfile!.isNotEmpty) {
      // استخدام المسار المطلق للصورة كما هو مخزن في كائن المستخدم
      userPhotoUrl = widget.userData!.photoProfile;
      debugPrint('User photo profile URL (homeapp): $userPhotoUrl');
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2F9C95),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قسم الترحيب والملف الشخصي
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: paddingHorizontal,
                        vertical: paddingVertical),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // صورة المستخدم والترحيب
                        Row(
                          children: [
                            CircleAvatar(
                              radius: isLandscape ? 25 : 22,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: userPhotoUrl != null &&
                                        userPhotoUrl.isNotEmpty
                                    ? Image.network(
                                        userPhotoUrl,
                                        width: isLandscape ? 50 : 44,
                                        height: isLandscape ? 50 : 44,
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
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          debugPrint(
                                              'Error loading profile image: $error, URL: $userPhotoUrl');
                                          return Image.asset(
                                            'assets/images/default_avatar.png',
                                            width: isLandscape ? 50 : 44,
                                            height: isLandscape ? 50 : 44,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        'assets/images/default_avatar.png',
                                        width: isLandscape ? 50 : 44,
                                        height: isLandscape ? 50 : 44,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            SizedBox(width: paddingHorizontal * 0.5),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'welcome'.tr(),
                                  style: TextStyle(
                                    fontSize: smallFontSize,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _username.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // أيقونة الإشعارات
                        CircleAvatar(
                          radius: isLandscape ? 20 : 18,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              Icons.notifications_none,
                              color: Colors.black,
                              size: isLandscape ? 22 : 18,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: paddingVertical),

                  // بطاقة العرض الخاص
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: paddingHorizontal),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(paddingHorizontal * 0.8),
                        child: Row(
                          children: [
                            // صورة الشخص
                            Image.asset(
                              'assets/images/delivery_person.png',
                              width: screenSize.width * 0.2,
                              height: screenSize.width * 0.2,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: screenSize.width * 0.2,
                                height: screenSize.width * 0.2,
                                color: Colors.amber,
                                child: Icon(Icons.person, size: iconSize),
                              ),
                            ),
                            SizedBox(width: paddingHorizontal * 0.5),
                            // تفاصيل العرض
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'demandez_deux_courses'.tr(),
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'offre_limitee'.tr(),
                                    style: TextStyle(
                                      fontSize: smallFontSize,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'jusqu\'à la fin de la semaine',
                                    style: TextStyle(
                                      fontSize: smallFontSize,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '+222 44524345',
                                    style: TextStyle(
                                      fontSize: smallFontSize,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // أيقونة الهدية
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '🎁',
                                style: TextStyle(
                                  fontSize: isLandscape ? 24 : 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: paddingVertical * 1.5),

                  // قسم الفئات
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: paddingHorizontal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'categorie'.tr(),
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: paddingVertical),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCategoryItem(Icons.restaurant,
                                'restaurant'.tr(), categoryIconSize),
                            _buildCategoryItem(Icons.local_pharmacy,
                                'pharmacies'.tr(), categoryIconSize),
                            _buildCategoryItem(Icons.delivery_dining,
                                'course'.tr(), categoryIconSize),
                            _buildCategoryItem(Icons.shopping_cart,
                                'supermarché'.tr(), categoryIconSize),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: paddingVertical * 1.5),

                  // قسم المطاعم الشائعة
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: paddingHorizontal),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'restaurant_populaire'.tr(),
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'voir_plus'.tr(),
                                style: TextStyle(
                                  fontSize: smallFontSize,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: paddingVertical * 0.5),
                        SizedBox(
                          height: restaurantCardHeight,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildRestaurantCard(
                                  'KFC',
                                  'assets/images/KFC.png',
                                  4.0,
                                  restaurantCardWidth,
                                  starSize,
                                  isLandscape),
                              _buildRestaurantCard(
                                  "DOMINO'S",
                                  'assets/images/Dominos.png',
                                  4.5,
                                  restaurantCardWidth,
                                  starSize,
                                  isLandscape),
                              _buildRestaurantCard(
                                  'BURGER KING',
                                  'assets/images/Burger-King-Logo.png',
                                  4.5,
                                  restaurantCardWidth,
                                  starSize,
                                  isLandscape),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: paddingVertical),

                  // قسم السوبرماركت الشائعة
                  Padding(
                    padding: EdgeInsets.only(
                        left: paddingHorizontal,
                        right: paddingHorizontal,
                        bottom: paddingVertical * 6),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'supermarché_populaire'.tr(),
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'voir_plus'.tr(),
                                style: TextStyle(
                                  fontSize: smallFontSize,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: paddingVertical * 0.5),
                        SizedBox(
                          height: restaurantCardHeight,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildRestaurantCard(
                                  'CARREFOUR',
                                  'assets/images/Carrefour-Logo.png',
                                  4.5,
                                  restaurantCardWidth,
                                  starSize,
                                  isLandscape),
                              _buildRestaurantCard(
                                  'MATCH',
                                  'assets/images/Match.png',
                                  4.0,
                                  restaurantCardWidth,
                                  starSize,
                                  isLandscape),
                              _buildRestaurantCard(
                                  'AUCHAN',
                                  'assets/images/Auchan.png',
                                  4.0,
                                  restaurantCardWidth,
                                  starSize,
                                  isLandscape),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // أزرار عائمة
            Positioned(
              bottom: screenSize.height * 0.1,
              right: paddingHorizontal,
              child: Column(
                children: [
                  // زر المفضلة
                  Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () {},
                    ),
                  ),
                  // زر السلة
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.shopping_bag, color: Colors.black),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                        size: bottomNavIconSize,
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
                      Icons.shopping_cart_outlined,
                      size: bottomNavIconSize,
                      color: _selectedIndex == 1
                          ? const Color(0xFF2F9C95)
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 1),
                ],
              ),
              title: 'orders'.tr(),
            ),
            TabItem(
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _selectedIndex == 2 ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.location_on_outlined,
                        size: bottomNavIconSize,
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
                        size: bottomNavIconSize,
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
                        size: bottomNavIconSize,
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
          onTap: (int i) {
            setState(() {
              _selectedIndex = i;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, double size) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(String name, String logoPath, double rating,
      double width, double starSize, bool isLandscape) {
    // تعديل ارتفاع البطاقة بناءً على اتجاه الشاشة
    final cardHeight = isLandscape ? width * 1.1 : width * 1.2;

    return Container(
      width: width,
      height: cardHeight,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            SizedBox(
              height: constraints.maxHeight * 0.5,
              child: Center(
                child: Image.asset(
                  logoPath,
                  width: constraints.maxWidth * 0.6,
                  height: constraints.maxHeight * 0.4,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: constraints.maxWidth * 0.6,
                    height: constraints.maxHeight * 0.4,
                    color: Colors.grey.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // اسم المطعم
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isLandscape ? 10 : 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),

            // تقييم النجوم
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (index) => Icon(
                  index < rating.floor()
                      ? Icons.star
                      : index < rating
                          ? Icons.star_half
                          : Icons.star_border,
                  color: Colors.amber,
                  size: starSize * 0.7,
                ),
              ),
            ),

            // رقم التقييم
            Text(
              rating.toString(),
              style: TextStyle(
                fontSize: isLandscape ? 9 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }),
    );
  }
}
