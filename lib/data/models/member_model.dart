import 'package:hive/hive.dart';

part 'member_model.g.dart';

/// Rôle d'un membre au sein d'un budget ou d'une équipe.
///
/// Utiliser un enum plutôt qu'un `String` libre évite les incohérences
/// de saisie entre développeurs (ex: "Admin" vs "admin" vs "ADMIN").
@HiveType(typeId: 3)
enum MemberRole {
  /// Peut créer, modifier et supprimer budgets et dépenses, gérer les membres.
  @HiveField(0)
  admin,

  /// Peut consulter et ajouter des dépenses, mais pas gérer les membres ou budgets.
  @HiveField(1)
  member,

  /// Accès en lecture seule (consultation des budgets/dépenses uniquement).
  @HiveField(2)
  viewer,
}

/// Modèle représentant un membre (personnel ou d'une équipe).
///
/// Persisté localement via Hive. Chaque membre a un rôle ([MemberRole])
/// qui détermine ses permissions au sein des budgets partagés.
@HiveType(typeId: 2)
class MemberModel extends HiveObject {
  /// Identifiant unique du membre (clé utilisée dans la box Hive).
  @HiveField(0)
  String id;

  /// Nom affiché du membre.
  @HiveField(1)
  String name;

  /// Rôle du membre, détermine ses permissions.
  @HiveField(2)
  MemberRole role;

  /// Crée un nouveau membre.
  MemberModel({
    required this.id,
    required this.name,
    required this.role,
  });

  /// Retourne une copie du membre avec les champs fournis remplacés.
  ///
  /// `id` n'est volontairement pas modifiable ici : l'identité d'un membre
  /// ne change pas après création.
  MemberModel copyWith({
    String? name,
    MemberRole? role,
  }) {
    return MemberModel(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }

  /// Deux membres sont considérés égaux s'ils ont le même [id].
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  /// Hash basé sur [id], cohérent avec `operator ==`.
  @override
  int get hashCode => id.hashCode;

  /// Représentation textuelle utile pour le debug et les logs de test.
  @override
  String toString() => 'MemberModel(id: $id, name: $name, role: $role)';
}

/// Extension utilitaire pour afficher un [MemberRole] de façon lisible dans l'UI.
extension MemberRoleLabel on MemberRole {
  /// Nom du rôle formaté pour affichage (ex: dans un dropdown ou une liste).
  String get label {
    switch (this) {
      case MemberRole.admin:
        return 'Administrateur';
      case MemberRole.member:
        return 'Membre';
      case MemberRole.viewer:
        return 'Lecteur';
    }
  }
}
