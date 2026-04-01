import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tax.g.dart';

/// Représente une taxe dans le système MuniciPay
@HiveType(typeId: 3)
@JsonSerializable()
class Tax extends HiveObject {
  /// Identifiant unique de la taxe
  @HiveField(0)
  final String id;

  /// Nom de la taxe (ex: "Taxe commerciale", "Taxe de transport")
  @HiveField(1)
  final String name;

  /// Montant de la taxe en FCFA
  @HiveField(2)
  final double amount;

  /// Zone géographique où s'applique la taxe
  @HiveField(3)
  final String zone;
  /// Catégorie de la taxe (ex: 'commerciale', 'transport') — compatibilité
  final String category;

  /// Description textuelle de la taxe
  final String description;

  /// Crée une nouvelle instance de [Tax]
  /// 
  /// Lance une [ArgumentError] si les paramètres requis ne sont pas valides
  Tax({
    required this.id,
    required this.name,
    required this.amount,
    required this.zone,
    String? category,
    String? description,
  }) :
    category = category ?? '',
    description = description ?? '' {
    // Validation des entrées
    if (id.isEmpty) {
      throw ArgumentError('L\'identifiant de la taxe ne peut pas être vide');
    }
    
    if (name.isEmpty) {
      throw ArgumentError('Le nom de la taxe ne peut pas être vide');
    }
    
    if (amount <= 0) {
      throw ArgumentError('Le montant de la taxe doit être supérieur à 0');
    }
    
    if (zone.isEmpty) {
      throw ArgumentError('La zone ne peut pas être vide');
    }
  }

  /// Crée une taxe à partir d'une Map JSON
  factory Tax.fromJson(Map<String, dynamic> json) => _$TaxFromJson(json);
  
  /// Convertit la taxe en Map JSON
  Map<String, dynamic> toJson() => _$TaxToJson(this);
  
  /// Crée une copie de la taxe avec les champs modifiés
  Tax copyWith({
    String? id,
    String? name,
    double? amount,
    String? zone,
  }) {
    return Tax(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      zone: zone ?? this.zone,
    );
  }
  
  /// Formate le montant de la taxe avec le symbole FCFA
  String get formattedAmount => '${amount.toStringAsFixed(0)} FCFA';
  
  @override
  String toString() {
    return 'Tax(id: $id, name: $name, amount: $formattedAmount, zone: $zone)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tax && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
