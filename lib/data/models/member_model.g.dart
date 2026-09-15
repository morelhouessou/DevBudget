// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemberModelAdapter extends TypeAdapter<MemberModel> {
  @override
  final int typeId = 2;

  @override
  MemberModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemberModel(
      id: fields[0] as String,
      name: fields[1] as String,
      role: fields[2] as MemberRole,
    );
  }

  @override
  void write(BinaryWriter writer, MemberModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.role);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MemberRoleAdapter extends TypeAdapter<MemberRole> {
  @override
  final int typeId = 3;

  @override
  MemberRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MemberRole.admin;
      case 1:
        return MemberRole.member;
      case 2:
        return MemberRole.viewer;
      default:
        return MemberRole.admin;
    }
  }

  @override
  void write(BinaryWriter writer, MemberRole obj) {
    switch (obj) {
      case MemberRole.admin:
        writer.writeByte(0);
        break;
      case MemberRole.member:
        writer.writeByte(1);
        break;
      case MemberRole.viewer:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
