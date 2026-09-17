import 'package:hive/hive.dart';
import '../models/member_model.dart';

/// Référentiel (repository) gérant l'accès aux données [MemberModel]
/// persistées dans la box Hive `members`.
class MemberRepository {
  final Box<MemberModel> _box = Hive.box<MemberModel>('members');

  /// Retourne la liste de tous les membres enregistrés.
  List<MemberModel> getAll() => _box.values.toList();

  /// Retourne le membre correspondant à [id], ou `null` s'il n'existe pas.
  MemberModel? getById(String id) => _box.get(id);

  /// Ajoute (ou remplace si l'id existe déjà) un membre dans la box.
  Future<void> add(MemberModel member) async {
    await _box.put(member.id, member);
  }

  /// Met à jour un membre déjà présent dans la box.
  ///
  /// Nécessite que [member] ait été récupéré depuis la box (via [getAll]
  /// ou [getById]), car `.save()` s'appuie sur la référence Hive interne
  /// de l'objet.
  Future<void> update(MemberModel member) async {
    await member.save();
  }

  /// Supprime le membre correspondant à [id] de la box.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
