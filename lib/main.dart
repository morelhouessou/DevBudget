import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/models/expense_model.dart';
import 'data/models/budget_model.dart';
import 'data/models/member_model.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  Hive.registerAdapter(MemberModelAdapter());

  await Hive.openBox<ExpenseModel>('expenses');
  await Hive.openBox<BudgetModel>('budgets');
  await Hive.openBox<MemberModel>('members');

  runApp(const ProviderScope(child: DevBudgetApp()));
}

class DevBudgetApp extends StatefulWidget {
  const DevBudgetApp({super.key});

  @override
  State<DevBudgetApp> createState() => _DevBudgetAppState();
}

class _DevBudgetAppState extends State<DevBudgetApp> {
  ThemeMode _themeMode = ThemeMode.light;
  late final ValueNotifier<Currency> _currencyNotifier;

  @override
  void initState() {
    super.initState();
    _currencyNotifier = ValueNotifier(
      CurrencyService().findByCode('XAF')!,
    );
  }

  @override
  void dispose() {
    _currencyNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevBudget',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: CurrencyScope(
        notifier: _currencyNotifier,
        child: HomeScreen(
          isDarkMode: _themeMode == ThemeMode.dark,
          onThemeChanged: (isDark) => setState(
            () => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff087f73),
      brightness: brightness,
    );
    final base = ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor:
          isDark ? const Color(0xff0d1718) : const Color(0xfff5f8f7),
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: base.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xff152324) : Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xff122020) : Colors.white,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xff1d2d2e) : const Color(0xffedf3f1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}
