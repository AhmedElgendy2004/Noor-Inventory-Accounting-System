import 'package:al_noor_gallery/features/inventory/logic/inventory_cubit.dart';
import 'package:al_noor_gallery/features/inventory/ui/product_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.large(
      shape: CircleBorder(side: BorderSide(color: Colors.blue, width: 3)),
      onPressed: () {
        context.push('/add-product');
      },
      child: const Text(
        "   اضافه\nمنتج جديد",
        style: TextStyle(fontWeight: .bold),
      ),
    );
  }
}

class CustomFloatingActionButtonProductScreen extends StatelessWidget {
  const CustomFloatingActionButtonProductScreen({
    super.key,
    required this.widget,
    required TextEditingController searchController,
  }) : _searchController = searchController;

  final ProductListScreen widget;
  final TextEditingController _searchController;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.large(
      shape: CircleBorder(side: BorderSide(color: Colors.blue, width: 3)),

      onPressed: () async {
        // 1. خزن الـ Cubit في متغير قبل الـ async عشان تضمن الوصول ليه حتى لو الشاشة اتدمرت
        final inventoryCubit = context.read<InventoryCubit>();

        // 2. التنقل للشاشة الأخرى
        await context.push('/add-product');

        // 3. التحقق من أن الـ context لا يزال موجوداً (Async Gap Guard)
        if (!context.mounted) return;

        // 4. تنفيذ التحديث
        final categoryId = widget.categoryId == 'all'
            ? null
            : widget.categoryId;

        inventoryCubit.fetchProducts(
          categoryId: categoryId,
          query: _searchController.text,
        );
      },
      child: const Text(
        "   اضافه\nمنتج جديد",
        style: TextStyle(fontWeight: .bold),
      ),
    );
  }
}
