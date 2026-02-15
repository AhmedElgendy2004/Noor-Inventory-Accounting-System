import 'package:al_noor_gallery/core/utils/my_card.dart';
import 'package:al_noor_gallery/features/auth/logic/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({
    super.key,
    required String userName,
    required String shopName,
  }) : _userName = userName,
       _shopName = shopName;

  final String _userName;
  final String _shopName;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: Image.asset(
              "assets/image/store.png",
              height: 100,
            ),
            decoration: const BoxDecoration(color: Color(0xFF1565C0)),
            accountName: Text(
              _userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(_shopName),
          ),
          // ListTile(
          //   leading: const Icon(Icons.inventory),
          //   title: const Text('المخزن'),
          //   onTap: () {
          //     context.pop();
          //     context.push('/inventory');
          //   },
          // ),
          //
          const Divider(),
          const MyCard(),
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
          const Divider(),
        ],
      ),
    );
  }
}
