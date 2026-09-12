import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  /// Identifiant unique de la dépense (clé utilisée dans la box Hive).
  @HiveField(0)
  String id;

  /// Titre ou description de la dépense.
  @HiveField(1)
  String title;

  /// Montant de la dépense.
  @HiveField(2)
  double amount;

  /// Catégorie de la dépense (ex: "Alimentation", "Transport", etc.).
  @HiveField(3)
  String category;

  /// Date de la dépense.
  @HiveField(4)
  DateTime date;

  /// Identifiant du membre qui a effectué la dépense.
  @HiveField(5)
  String memberId;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.memberId,
  });

  /// Retourne une copie de la dépense avec les champs fournis remplacés.
  /// Les champs non fournis conservent leur valeur actuelle.
  ExpenseModel copyWith({
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? memberId,
  }) {
    return ExpenseModel(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      memberId: memberId ?? this.memberId,
    );
  }

  /// Deux dépenses sont considérées égales si elles ont le même identifiant unique.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  /// Hash basé sur {id} pour garantir que deux dépenses avec le même identifiant ont le même hash.
  @override
  int get hashCode => id.hashCode;

  /// Représentation textuelle de la dépense pour faciliter le débogage et les logs.
  @override
  String toString() =>
      'ExpenseModel(id: $id, title: $title, amount: $amount, category: $category, date: $date, memberId: $memberId)';
}
