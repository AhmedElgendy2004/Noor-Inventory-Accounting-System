import 'package:al_noor_gallery/features/inventory/logic/inventory_cubit.dart';
import 'package:al_noor_gallery/features/inventory/logic/inventory_state.dart';
import 'package:al_noor_gallery/features/inventory/ui/add_product_screen.dart';
import 'package:al_noor_gallery/features/inventory/ui/widget/custom_text_field.dart';
import 'package:al_noor_gallery/data/models/category_model.dart';
import 'package:al_noor_gallery/data/models/product_model.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock InventoryCubit
class MockInventoryCubit extends MockCubit<InventoryState>
    implements InventoryCubit {}

// Fake ProductModel for verification
class FakeProductModel extends Fake implements ProductModel {}

void main() {
  late MockInventoryCubit mockInventoryCubit;

  setUpAll(() {
    registerFallbackValue(FakeProductModel());
  });

  setUp(() {
    mockInventoryCubit = MockInventoryCubit();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<InventoryCubit>.value(
        value: mockInventoryCubit,
        child: const AddProductScreen(),
      ),
    );
  }

  testWidgets('renders AddProductScreen correctly', (tester) async {
    when(
      () => mockInventoryCubit.state,
    ).thenReturn(InventoryLoaded([], categories: []));
    when(() => mockInventoryCubit.loadCategories()).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('إضافة منتج جديد'), findsOneWidget);
    expect(find.text('البيانات الأساسية'), findsOneWidget);
    expect(find.text('الأسعار'), findsOneWidget);
    expect(find.text('المخزن'), findsOneWidget);
    expect(find.text('حفظ المنتج'), findsOneWidget);
  });

  testWidgets('shows validation errors when saving empty form', (tester) async {
    when(
      () => mockInventoryCubit.state,
    ).thenReturn(InventoryLoaded([], categories: []));
    when(() => mockInventoryCubit.loadCategories()).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());

    // Scroll to Save button manually to avoid ambiguity
    final saveButtonFinder = find.widgetWithText(ElevatedButton, 'حفظ المنتج');
    final scrollViewFinder = find.byKey(const Key('productFormScrollView'));

    // Drag up to reveal bottom
    await tester.drag(scrollViewFinder, const Offset(0, -500));
    await tester.pumpAndSettle();

    // Tap Save button without entering data
    await tester.tap(saveButtonFinder);
    await tester.pump(); // Rebuild for validation errors

    // Verify "This field is required" error messages
    expect(find.text('هذا الحقل مطلوب'), findsWidgets);
  });

  testWidgets('calls addProduct when form is valid and saved', (tester) async {
    final tCategoryId = 'cat1';
    final tCategories = [
      CategoryModel(id: tCategoryId, name: 'General', color: 0xFF000000),
    ];

    when(
      () => mockInventoryCubit.state,
    ).thenReturn(InventoryLoaded([], categories: tCategories));
    when(() => mockInventoryCubit.loadCategories()).thenAnswer((_) async {});
    when(() => mockInventoryCubit.addProduct(any())).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // For categories loading

    // Fill Form
    // Helper to find TextField by label
    Finder findField(String label) {
      return find.descendant(
        of: find.widgetWithText(CustomTextField, label),
        matching: find.byType(TextField),
      );
    }

    await tester.enterText(findField('اسم المنتج'), 'Test Product');
    await tester.enterText(findField('الباركود'), '123456789');

    // 3. Category
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    // Select item
    await tester.tap(find.text('General').last);
    await tester.pumpAndSettle();

    // 4. Prices
    await tester.enterText(findField('سعر الشراء'), '100');
    await tester.enterText(findField('سعر القطاعي'), '150');

    // 5. Stock
    await tester.enterText(findField('الكمية الحالية'), '10');

    // Scroll to Save button
    final saveButtonFinder = find.widgetWithText(ElevatedButton, 'حفظ المنتج');
    final scrollViewFinder = find.byKey(const Key('productFormScrollView'));

    await tester.drag(scrollViewFinder, const Offset(0, -500));
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(saveButtonFinder);
    await tester.pump();

    // Verify addProduct called
    verify(() => mockInventoryCubit.addProduct(any())).called(1);
  });
}
