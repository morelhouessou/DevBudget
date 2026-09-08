import 'package:hive/hive.dart';

part 'member_model.g.dart';

@HiveType(typeId: 2)
class MemberModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String role;

  MemberModel({
    required this.id,
    required this.name,
    required this.role,
  });
}
