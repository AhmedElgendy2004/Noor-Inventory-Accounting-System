import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/data/services/auth_service.dart'; // Direct access for simplicity or via Cubit
import 'widgets/dashboard_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _shopName = 'معرض النور'; // Default
  String _userName = 'مرحباً بك';
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
          _userName = 'مرحباً، أستاذ ${profile['full_name']}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1565C0)),
              accountName: Text(
                _userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(_shopName),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.store, color: Color(0xFF1565C0), size: 30),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('المخزن'),
              onTap: () {
                context.pop();
                context.push('/inventory');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('سجل المبيعات'),
              onTap: () {
                context.pop();
                context.push('/sales-history');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await context.read<AuthCubit>().signOut();
              },
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          //AppBar
          SliverAppBar(
            expandedHeight: 125.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1565C0), Colors.blue.shade400],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image.asset("assets/image/logo_store.png"), // Can keep or replace
                    const Icon(
                      Icons.storefront,
                      size: 50,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shopName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                  color: Colors.green,
                  onTap: () => context.push('/pos'),
                ),

                // 2. Inventory Management
                DashboardCard(
                  title: 'إدارة المخزن',
                  icon: Icons.inventory_2,
                  color: Colors.orange,
                  onTap: () => context.push('/inventory'),
                ),

                // 3. Purchases (Placeholder)
                DashboardCard(
                  title: 'شراء\n(قريباً)',
                  icon: Icons.shopping_cart,
                  color: Colors.redAccent,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('قريباً: إدارة الشراء')),
                    );
                  },
                ),
                // 4. Accounts (Placeholder)
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
                // 5. Sales Invoices History
                DashboardCard(
                  title: 'فواتير البيع',
                  icon: Icons.receipt_long, // or description
                  color: Colors.teal,
                  onTap: () => context.push('/sales-history'),
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

                SizedBox(height: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
