// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 4;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      id: fields[0] as String,
      taxId: fields[1] as String,
      amount: fields[2] as double,
      status: fields[3] as PaymentStatus?,
      paymentDate: fields[4] as DateTime?,
      method: fields[5] as PaymentMethod?,
      zone: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taxId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.paymentDate)
      ..writeByte(5)
      ..write(obj.method)
      ..writeByte(6)
      ..write(obj.zone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
      id: json['id'] as String,
      taxId: json['taxId'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: $enumDecodeNullable(_$PaymentStatusEnumMap, json['status']),
      paymentDate: json['paymentDate'] == null
          ? null
          : DateTime.parse(json['paymentDate'] as String),
      method: $enumDecodeNullable(_$PaymentMethodEnumMap, json['method']),
      paymentMethod: json['paymentMethod'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      verificationCode: json['verificationCode'] as String?,
      qrCode: json['qrCode'] as String?,
      taxName: json['taxName'] as String?,
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      zone: json['zone'] as String?,
      payerName: json['payerName'] as String?,
      payerPhone: json['payerPhone'] as String?,
    );

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
      'id': instance.id,
      'taxId': instance.taxId,
      'amount': instance.amount,
      'status': _$PaymentStatusEnumMap[instance.status]!,
      'paymentDate': instance.paymentDate.toIso8601String(),
      'method': _$PaymentMethodEnumMap[instance.method]!,
      'zone': instance.zone,
      'verificationCode': instance.verificationCode,
      'qrCode': instance.qrCode,
      'taxName': instance.taxName,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'payerName': instance.payerName,
      'payerPhone': instance.payerPhone,
      'createdAt': instance.createdAt.toIso8601String(),
      'paymentMethod': instance.paymentMethod,
    };

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.completed: 'completed',
  PaymentStatus.verified: 'verified',
  PaymentStatus.failed: 'failed',
  PaymentStatus.refunded: 'refunded',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.mobileMoney: 'mobile_money',
  PaymentMethod.creditCard: 'credit_card',
  PaymentMethod.bankTransfer: 'bank_transfer',
  PaymentMethod.cash: 'cash',
};
