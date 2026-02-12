import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/services/product_service.dart';
import 'data/services/sales_service.dart';
import 'features/inventory/logic/inventory_cubit.dart';
import 'features/sales/logic/sales_cubit.dart';
import 'features/sales_history/logic/sales_history_cubit.dart';
import 'features/auth/logic/auth_cubit.dart';
import 'features/auth/data/services/auth_service.dart';
import 'core/routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: ".env");
  // Initialize Supabase with environment variables
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthService _authService;
  late final AuthCubit _authCubit;
  late final ProductService _productService;
  late final SalesService _salesService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _authCubit = AuthCubit(_authService)..checkAuthStatus();
    _productService = ProductService();
    _salesService = SalesService();
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<InventoryCubit>(
          create: (context) => InventoryCubit(_productService),
        ),
        BlocProvider<SalesCubit>(
          create: (context) => SalesCubit(_salesService),
        ),
        BlocProvider<SalesHistoryCubit>(
          create: (context) =>
              SalesHistoryCubit(_salesService)..fetchInvoices(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: AppRouter.createRouter(_authCubit),
        debugShowCheckedModeBanner: false,
        title: 'Al Noor Gallery POS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        // Support RTL for Arabic
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      ),
    );
  }
}
