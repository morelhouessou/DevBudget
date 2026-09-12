import 'package:flutter/material.dart';
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
  Hive.registerAdapter(MemberRoleAdapter());

  await Hive.openBox<ExpenseModel>('expenses');
  await Hive.openBox<BudgetModel>('budgets');
  await Hive.openBox<MemberModel>('members');

  runApp(const ProviderScope(child: DevBudgetApp()));
}

class DevBudgetApp extends StatelessWidget {
  const DevBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevBudget',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
