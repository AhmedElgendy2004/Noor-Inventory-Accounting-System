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
                    Image.asset("assets/image/logo_store.png"),
                    const SizedBox(width: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'النور  ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'للشيخ محمود قطب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
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
