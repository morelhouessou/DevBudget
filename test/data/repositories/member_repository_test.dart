import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:devbudget/data/models/member_model.dart';
import 'package:devbudget/data/repositories/member_repository.dart';

void main() {
  late Directory hiveDirectory;
  late Box<MemberModel> box;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('devbudget_test_');
    Hive.init(hiveDirectory.path);

    /// Enregistre l'adaptateur pour le modèle MemberModel afin que Hive puisse sérialiser et désérialiser les objets MemberModel.
    Hive.registerAdapter(MemberModelAdapter());

    /// Enregistre l'adaptateur pour le type énuméré MemberRole afin que Hive puisse sérialiser et désérialiser les rôles des membres.
    Hive.registerAdapter(MemberRoleAdapter());
    box = await Hive.openBox<MemberModel>('members');
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  group('MemberRepository', () {
    late MemberRepository memberRepository;

    setUp(() async {
      await box.clear();
      memberRepository = MemberRepository();
    });

    test('add stores a member and getAll returns it', () async {
      /// Crée deux instances de MemberModel pour tester l'ajout et la récupération des membres.
      final member1 = MemberModel(
        id: '1',
        name: 'Member Test 1',
        role: MemberRole.admin,
      );
      final member2 = MemberModel(
        id: '2',
        name: 'Member Test 2',
        role: MemberRole.member,
      );

      await memberRepository.add(member1);
      await memberRepository.add(member2);

      final members = memberRepository.getAll();

      expect(members.length, 2);
      expect(members, containsAll([member1, member2]));
    });

    test('getById returns the correct member, or null if absent', () async {
      /// Crée une instance de MemberModel pour tester la récupération par ID.
      final member = MemberModel(
        id: '1',
        name: 'Member Test 1',
        role: MemberRole.viewer,
      );

      await memberRepository.add(member);

      /// Tente de récupérer le membre ajouté par son ID pour vérifier que la méthode retourne bien l'objet correct.
      final foundMember = memberRepository.getById('1');

      /// Tente de récupérer un membre avec un ID qui n'existe pas pour vérifier que la méthode retourne null.
      final missingMember = memberRepository.getById('unknown');

      expect(foundMember, member);
      expect(missingMember, isNull);
    });

    test('delete removes a member from the box', () async {
      /// Crée une instance de MemberModel pour tester la suppression.
      final member = MemberModel(
        id: '1',
        name: 'Member Test 1',
        role: MemberRole.admin,
      );

      /// Ajoute le membre à la box via le repository et vérifie qu'il est bien présent avant de le supprimer.
      await memberRepository.add(member);

      /// Vérifie que le membre a été ajouté correctement.
      expect(memberRepository.getById('1'), isNotNull);

      await memberRepository.delete('1');

      /// Vérifie que le membre a été supprimé correctement et que la box est vide après la suppression.
      expect(memberRepository.getById('1'), isNull);

      /// Vérifie que la box est vide après la suppression du membre.
      expect(memberRepository.getAll(), isEmpty);
    });
  });
}
