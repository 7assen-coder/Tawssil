import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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

  Widget _buildCategoryItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F9C95),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'welcome'.tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _username,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Color(0xFF2F9C95)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.yellow,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                size: 30,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'demandez_deux_courses'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'offre_limitee'.tr(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'categorie'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCategoryItem(
                                Icons.format_list_bulleted, 'supermarché'.tr()),
                            _buildCategoryItem(
                                Icons.medical_services, 'pharmacies'.tr()),
                            _buildCategoryItem(Icons.motorcycle, 'course'.tr()),
                            _buildCategoryItem(
                                Icons.shopping_cart, 'restaurant'.tr()),
                            _buildCategoryItem(
                                Icons.restaurant, 'restaurant'.tr()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'voir_plus'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'restaurant_populaire'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildRestaurantCard('KFC', 'kfc', 4.0),
                              _buildRestaurantCard("DOMINO'S", 'dominos', 4.5),
                              _buildRestaurantCard(
                                  'BURGER KING', 'burger', 4.5),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, bottom: 100),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'voir_plus'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'supermarché_populaire'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildRestaurantCard(
                                  'CARREFOUR', 'carrefour', 4.5),
                              _buildRestaurantCard('MATCH', 'match', 4.0),
                              _buildRestaurantCard('AUCHAN', 'auchan', 4.0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 80,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'favorite',
                    backgroundColor: Colors.white,
                    onPressed: () {},
                    child: const Icon(Icons.favorite, color: Colors.pink),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'cart',
                    backgroundColor: Colors.white,
                    onPressed: () {},
                    child: const Icon(Icons.shopping_bag, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: 'orders'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.location_on),
            label: 'map'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: 'chat'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'profile'.tr(),
          ),
        ],
        selectedItemColor: const Color(0xFF2F9C95),
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildRestaurantCard(String name, String logo, double rating) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(left: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(top: 8.0),
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
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Icon(
                index < rating.floor()
                    ? Icons.star
                    : index < rating
                        ? Icons.star_half
                        : Icons.star_border,
                color: Colors.amber,
                size: 12,
              ),
            ),
          ),
          Text(
            rating.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
