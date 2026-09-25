import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/models/expense_model.dart';
import 'data/models/budget_model.dart';
import 'data/models/member_model.dart';
import 'logic/providers/budget_provider.dart';
import 'logic/providers/currency_provider.dart';
import 'logic/providers/expense_provider.dart';
import 'logic/providers/member_provider.dart';
import 'logic/sync/sync_service.dart';
import 'logic/notifications.dart';
import 'presentation/app_gate.dart';
import 'presentation/brand.dart';
import 'presentation/screens/home_screen.dart' show CurrencyScope;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  Hive.registerAdapter(MemberModelAdapter());
  Hive.registerAdapter(MemberRoleAdapter());

  await Hive.openBox<ExpenseModel>('expenses');
  await Hive.openBox<BudgetModel>('budgets');
  await Hive.openBox<MemberModel>('members');
  await Hive.openBox<String>('settings');
  await initNotifications();
  await SyncService.instance.init();

  runApp(const ProviderScope(child: DevBudgetApp()));
}

class DevBudgetApp extends StatefulWidget {
  const DevBudgetApp({super.key});

  @override
  State<DevBudgetApp> createState() => _DevBudgetAppState();
}

class _DevBudgetAppState extends State<DevBudgetApp> {
  // Les réglages sont persistés si la box `settings` est ouverte (main).
  Box<String>? get _settings =>
      Hive.isBoxOpen('settings') ? Hive.box<String>('settings') : null;

  late ThemeMode _themeMode;
  late final ValueNotifier<Currency> _currencyNotifier;

  @override
  void initState() {
    super.initState();
    final settings = _settings;
    // Sombre par défaut (identité visuelle), sauf choix contraire mémorisé.
    _themeMode =
        settings?.get('theme') == 'light' ? ThemeMode.light : ThemeMode.dark;
    final code = settings?.get('currency') ?? 'XAF';
    _currencyNotifier = ValueNotifier(
      CurrencyService().findByCode(code) ?? CurrencyService().findByCode('XAF')!,
    );
    // La devise choisie alimente aussi les calculs (providers Riverpod).
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(displayCurrencyProvider.notifier).state =
        _currencyNotifier.value.code;
    _currencyNotifier.addListener(() {
      final code = _currencyNotifier.value.code;
      _settings?.put('currency', code);
      container.read(displayCurrencyProvider.notifier).state = code;
    });

    // Synchronisation : des données distantes rafraîchissent l'interface.
    SyncService.instance.onRemoteChanges = () {
      container.invalidate(expenseListProvider);
      container.invalidate(budgetListProvider);
      container.invalidate(memberListProvider);
    };
    if (settings != null && SyncService.instance.signedIn) {
      SyncService.instance.sync();
    }
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
        child: AppGate(
          isDarkMode: _themeMode == ThemeMode.dark,
          onThemeChanged: (isDark) {
            _settings?.put('theme', isDark ? 'dark' : 'light');
            setState(
              () => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light,
            );
          },
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: brightness,
    ).copyWith(primary: brandBlue, onPrimary: Colors.white);
    final base = ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? brandNavy : const Color(0xfff2f5fd),
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
        color: isDark ? brandCard : Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: isDark ? brandCardBorder : const Color(0xffe1e7f8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? brandCard : Colors.white,
        selectedColor: brandBlue,
        side: BorderSide(
            color: isDark ? brandCardBorder : const Color(0xffe1e7f8)),
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xff0c1330) : Colors.white,
        indicatorColor: brandBlue.withValues(alpha: 0.28),
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
        fillColor: isDark ? const Color(0xff141f45) : const Color(0xffe8edfb),
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
