// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetModelAdapter extends TypeAdapter<BudgetModel> {
  @override
  final int typeId = 1;

  @override
  BudgetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetModel(
      id: fields[0] as String,
      name: fields[1] as String,
      totalAmount: fields[2] as double,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime,
      ownerId: fields[5] as String,
      memberIds: (fields[6] as List?)?.cast<String>(),
      isShared: fields[7] as bool?,
      category: fields[8] as String?,
      recurring: fields[9] == null ? false : fields[9] as bool,
      currency: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.totalAmount)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.ownerId)
      ..writeByte(6)
      ..write(obj.memberIds)
      ..writeByte(7)
      ..write(obj.isShared)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.recurring)
      ..writeByte(10)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
