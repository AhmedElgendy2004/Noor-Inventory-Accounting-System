import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:al_noor_gallery/features/inventory/logic/inventory_cubit.dart';
import 'package:al_noor_gallery/features/inventory/logic/inventory_state.dart';
import 'package:al_noor_gallery/data/services/product_service.dart';
import 'package:al_noor_gallery/data/models/product_model.dart';
import 'package:al_noor_gallery/data/models/category_model.dart';

// 1. Mock the Service
class MockProductService extends Mock implements ProductService {}

void main() {
  late MockProductService mockProductService;
  late InventoryCubit inventoryCubit;

  // Mock Objects
  final tProduct = ProductModel(
    id: '1',
    name: 'Test Product',
    barcode: '123456',
    stockQuantity: 10,
    minStockLevel: 2,
    purchasePrice: 100,
    retailPrice: 150,
    wholesalePrice: 140,
    // createdAt removed based on model definition
  );

  final tCategory = CategoryModel(id: 'cat1', name: 'Test Cat');

  setUp(() {
    mockProductService = MockProductService();
    // Register fallback values
    registerFallbackValue(tProduct);

    inventoryCubit = InventoryCubit(mockProductService);
  });

  tearDown(() {
    inventoryCubit.close();
  });

  group('InventoryCubit Tests', () {
    test('initial state is InventoryInitial', () {
      expect(inventoryCubit.state, isA<InventoryInitial>());
    });

    // Test 1: loadInitialData (Success)
    blocTest<InventoryCubit, InventoryState>(
      'emits [InventoryLoading, InventoryLoaded] when loadInitialData succeeds',
      build: () {
        when(
          () => mockProductService.getCategories(),
        ).thenAnswer((_) async => [tCategory]);
        when(
          () => mockProductService.getTotalProductsCount(),
        ).thenAnswer((_) async => 50);

        when(
          () => mockProductService.getProducts(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => [tProduct]);

        when(
          () => mockProductService.getTotalProductsCount(lowStockOnly: true),
        ).thenAnswer((_) async => 5);
        return inventoryCubit;
      },
      act: (cubit) => cubit.loadInitialData(),
      expect: () => [
        isA<InventoryLoading>(),
        isA<InventoryLoaded>()
            .having((state) => state.categories.length, 'categories length', 1)
            .having((state) => state.globalProductCount, 'global count', 50),
      ],
    );

    // Test 2: addProduct Success
    blocTest<InventoryCubit, InventoryState>(
      'emits [InventoryLoading, InventorySuccess, InventoryLoaded] after adding product',
      build: () {
        when(() => mockProductService.addProduct(any())).thenAnswer(
          (_) async => tProduct,
        ); // Must return a Future<ProductModel>
        // No need to stub getCategories here if addProduct doesn't call it,
        // but if it does (e.g. implicitly via loadInitialData), we need it.
        // Based on code reading, addProduct relies on _cachedCategories or manual emit.
        return inventoryCubit;
      },
      act: (cubit) => cubit.addProduct(tProduct),
      expect: () => [
        isA<InventoryLoading>(), // addProduct loading
        isA<InventorySuccess>(), // success message
        isA<InventoryLoaded>(), // manual reload
      ],
    );

    // Test 3: Error (Duplicate Barcode)
    blocTest<InventoryCubit, InventoryState>(
      'emits [InventoryLoading, InventoryError] when addProduct fails (Duplicate)',
      build: () {
        when(() => mockProductService.addProduct(any())).thenThrow(
          Exception(
            'duplicate key value violates unique constraint "products_barcode_key"',
          ),
        );
        return inventoryCubit;
      },
      act: (cubit) => cubit.addProduct(tProduct),
      expect: () => [
        isA<InventoryLoading>(),
        isA<InventoryError>().having(
          (state) => state.message,
          'message',
          contains('duplicate key'),
        ),
      ],
    );
  });
}
