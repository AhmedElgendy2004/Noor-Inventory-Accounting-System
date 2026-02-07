import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/dashboard_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade400],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // توسيط عمودي
                  children: [
                    const Icon(Icons.store, size: 60, color: Colors.white54),
                    const SizedBox(
                      width: 10,
                    ), // مسافة بسيطة بين الأيقونة والكلمة
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'النور',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 35, // كبرنا الخط شوية عشان يبقى واضح
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'الشيخ محمود قطب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15, // كبرنا الخط شوية عشان يبقى واضح
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
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

                // 3. Sales Invoices History
                DashboardCard(
                  title: 'فواتير البيع',
                  icon: Icons.receipt_long, // or description
                  color: Colors.teal,
                  onTap: () => context.push('/sales-history'),
                ),

                // 4. Purchase Invoices (Placeholder)
                DashboardCard(
                  title: 'فواتير الشراء',
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

                // 5. Accounts (Placeholder)
                DashboardCard(
                  title: 'الحسابات',
                  icon: Icons.calculate,
                  color: Colors.brown,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('قريباً: إدارة الحسابات')),
                    );
                  },
                ),
                // 6. Purchases (Placeholder)
                DashboardCard(
                  title: 'شراء',
                  icon: Icons.shopping_cart,
                  color: Colors.brown,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('قريباً: إدارة الشراء')),
                    );
                  },
                ),

                // 7. Customers (Placeholder)
                DashboardCard(
                  title: 'العملاء',
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
                  title: 'الموردين',
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
