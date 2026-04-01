// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaxAdapter extends TypeAdapter<Tax> {
  @override
  final int typeId = 3;

  @override
  Tax read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tax(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      zone: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Tax obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.zone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaxAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tax _$TaxFromJson(Map<String, dynamic> json) => Tax(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      zone: json['zone'] as String,
      category: json['category'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$TaxToJson(Tax instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'amount': instance.amount,
      'zone': instance.zone,
      'category': instance.category,
      'description': instance.description,
    };
