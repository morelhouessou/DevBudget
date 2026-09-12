import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 1)
class BudgetModel extends HiveObject {
  /// Identifiant unique du budget (clé utilisée dans la box Hive).
  @HiveField(0)
  String id;

  /// Nom du budget.
  @HiveField(1)
  String name;

  /// Montant total  alloué au budget.
  @HiveField(2)
  double totalAmount;

  /// Date de début du budget.
  @HiveField(3)
  DateTime startDate;

  /// Date de fin du budget.
  @HiveField(4)
  DateTime endDate;

  /// Identifiant de l'owner du budget.
  @HiveField(5)
  String ownerId;

  /// Liste des identifiants des membres avec qui le budget est partagé.
  /// Vide si le budget est personnel.
  @HiveField(6)
  List<String> memberIds;

  /// Indique si le budget est partagé (true) ou personnel (false).
  /// Calculé automatiquement à partir de `memberIds` si non précisé.
  @HiveField(7)
  bool isShared;

  /// Crée un nouveau budget.
  ///
  /// [memberIds] et [isShared] sont optionnels : si `memberIds` est fourni
  /// et non vide, `isShared` sera automatiquement `true` sauf indication contraire.

  BudgetModel({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.startDate,
    required this.endDate,
    required this.ownerId,
    List<String>? memberIds,
    bool? isShared,
  })  : memberIds = memberIds ?? [],
        isShared = isShared ?? (memberIds != null && memberIds.isNotEmpty);

  BudgetModel copyWith({
    String? name,
    double? totalAmount,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? memberIds,
    bool? isShared,
  }) {
    return BudgetModel(
      id: id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      ownerId: ownerId,
      memberIds: memberIds ?? this.memberIds,
      isShared: isShared ?? this.isShared,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BudgetModel(id: $id, name: $name, totalAmount: $totalAmount, startDate: $startDate, endDate: $endDate, ownerId: $ownerId, memberIds: $memberIds, isShared: $isShared)';
}
