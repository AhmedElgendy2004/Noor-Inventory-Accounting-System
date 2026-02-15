import 'package:al_noor_gallery/core/utils/my_card.dart';
import 'package:al_noor_gallery/features/home/ui/widgets/custom_drawer.dart';
import 'package:al_noor_gallery/features/home/ui/widgets/custom_home_appbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/services/auth_service.dart'; // Direct access for simplicity or via Cubit
import 'widgets/dashboard_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _shopName = 'al Noor POS'; // Default
  String _userName = 'مرحباً ';
  final _authService = AuthService(); // Instance

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final profile = await _authService.getUserProfile();
    if (profile != null && mounted) {
      setState(() {
        if (profile['shop_name'] != null &&
            profile['shop_name'].toString().isNotEmpty) {
          _shopName = profile['shop_name'];
        }
        if (profile['full_name'] != null &&
            profile['full_name'].toString().isNotEmpty) {
          _userName = 'مرحباً  ${profile['full_name']}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(userName: _userName, shopName: _shopName),
      body: CustomScrollView(
        slivers: [
          //AppBar
          CustomHomeAppBar(shopName: _shopName, userName: _userName),
          // Dashboard Grid
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                // 1. Point of Sale
                DashboardCard(
                  title: ' البيع',
                  icon: Icons.point_of_sale,
                  color: Colors.green.shade400,
                  onTap: () => context.push('/pos'),
                ),

                // 2. Inventory Management
                DashboardCard(
                  title: 'إدارة المخزن',
                  icon: Icons.inventory_2,
                  color: Colors.orange,
                  onTap: () => context.push('/inventory'),
                ),
                // 3. Sales Invoices History
                DashboardCard(
                  title: 'فواتير البيع',
                  icon: Icons.receipt_long, // or description
                  color: Colors.teal.shade700,
                  onTap: () => context.push('/sales-history'),
                ),
                // 4. Purchases (Placeholder)
                DashboardCard(
                  title: 'شراء\n(قريباً)',
                  icon: Icons.shopping_cart,
                  color: Colors.redAccent.shade400,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('قريباً: إدارة الشراء')),
                    );
                  },
                ),
                // 5. Accounts (Placeholder)
                DashboardCard(
                  title: 'الحسابات\n(قريباً)',
                  icon: Icons.calculate,
                  color: Colors.brown,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('قريباً: إدارة الحسابات')),
                    );
                  },
                ),

                // 6. Purchase Invoices (Placeholder)
                DashboardCard(
                  title: 'فواتير الشراء \n(قريباً)',
                  icon: Icons.receipt_long,
                  color: Colors.purple,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('قريباً: إدارة فواتير الشراء'),
                      ),
                    );
                  },
                ),

                // 7. Customers (Placeholder)
                DashboardCard(
                  title: 'العملاء\n(قريباً)',
                  icon: Icons.people,
                  color: Colors.blueAccent,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('قريباً: إدارة العملاء')),
                    );
                  },
                ),
                // 8. Suppliers (Placeholder)
                DashboardCard(
                  title: 'الموردين\n(قريباً)',
                  icon: Icons.people_outline,
                  color: Colors.blueGrey,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('قريباً: إدارة الموردين')),
                    );
                  },
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child:const MyCard()),
          SliverToBoxAdapter(child: const SizedBox(height: 50)),
        ],
      ),
    );
  }
}
