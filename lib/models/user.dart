import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Représente un utilisateur du système MuniciPay
@HiveType(typeId: 2)
@JsonSerializable()
class User extends HiveObject {
  /// Identifiant unique de l'utilisateur
  @HiveField(0)
  final String id;

  /// Nom complet de l'utilisateur
  @HiveField(1)
  final String name;

  /// Numéro de téléphone de l'utilisateur (format international)
  @HiveField(2)
  final String phone;

  /// Adresse email de l'utilisateur (optionnelle)
  @HiveField(3)
  final String? email;

  /// Rôle de l'utilisateur (ex: admin, agent, contribuable)
  @HiveField(4)
  final String role;

  /// Zone géographique associée à l'utilisateur (optionnelle)
  @HiveField(5)
  final String? zone;

  /// Activité professionnelle ou domaine d'activité de l'utilisateur (optionnelle)
  @HiveField(7)
  final String? activity;

  /// Zone d'activité (ex: marché, quartier) associée à l'activité (optionnelle)
  @HiveField(8)
  final String? activityZone;

  /// Date d'enregistrement de l'utilisateur dans le système
  @HiveField(6)
  final DateTime registrationDate;

  /// Crée une nouvelle instance de [User]
  /// 
  /// Lance une [ArgumentError] si les paramètres requis ne sont pas valides
  User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.zone,
    this.activity,
    this.activityZone,
    required this.registrationDate,
  }) {
    // Validation des entrées
    if (id.isEmpty) {
      throw ArgumentError('L\'identifiant ne peut pas être vide');
    }
    
    if (name.isEmpty) {
      throw ArgumentError('Le nom ne peut pas être vide');
    }
    
    if (!_isValidPhoneNumber(phone)) {
      throw ArgumentError('Le numéro de téléphone n\'est pas valide');
    }
    
    if (email != null && !_isValidEmail(email!)) {
      throw ArgumentError('L\'adresse email n\'est pas valide');
    }
    
    if (role.isEmpty) {
      throw ArgumentError('Le rôle ne peut pas être vide');
    }
  }

  /// Crée un utilisateur à partir d'une Map JSON
  ///
  /// Cette fabrique assainit les valeurs reçues (convertit `null` en
  /// chaîne vide ou valeur par défaut) afin d'éviter des erreurs de
  /// cast (ex: `Null` n'est pas un `String`) lorsque le backend
  /// renvoie des champs manquants.
  factory User.fromJson(Map<String, dynamic> json) {
    final sanitized = <String, dynamic>{};

    sanitized['id'] = json['id'] != null ? json['id'].toString() : '';
    sanitized['name'] = json['name'] != null ? json['name'].toString() : '';
    sanitized['phone'] = json['phone'] != null ? json['phone'].toString() : '';
    sanitized['email'] = json['email'] != null ? json['email'].toString() : null;
    sanitized['role'] = json['role'] != null ? json['role'].toString() : '';
    sanitized['zone'] = json['zone'] != null ? json['zone'].toString() : null;
    sanitized['activity'] = json['activity'] != null ? json['activity'].toString() : null;
    sanitized['activityZone'] = json['activityZone'] != null ? json['activityZone'].toString() : null;
    // registrationDate must be a valid ISO string for DateTime.parse.
    if (json['registrationDate'] != null) {
      sanitized['registrationDate'] = json['registrationDate'].toString();
    } else {
      sanitized['registrationDate'] = DateTime.now().toIso8601String();
    }

    return _$UserFromJson(sanitized);
  }
  
  /// Convertit l'utilisateur en Map JSON
  Map<String, dynamic> toJson() => _$UserToJson(this);
  
  /// Crée une copie de l'utilisateur avec les champs modifiés
  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? zone,
    String? activity,
    String? activityZone,
    DateTime? registrationDate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      zone: zone ?? this.zone,
      activity: activity ?? this.activity,
      activityZone: activityZone ?? this.activityZone,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }

  /// Vérifie si le numéro de téléphone est valide
  static bool _isValidPhoneNumber(String phone) {
    // Format international: + suivi de 8 à 15 chiffres
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Vérifie si l'email est valide
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
  
  /// Vérifie si l'utilisateur a un rôle administrateur
  bool get isAdmin => role.toLowerCase() == 'admin';
  
  /// Vérifie si l'utilisateur a un rôle agent
  bool get isAgent => role.toLowerCase() == 'agent';
  
  /// Vérifie si l'utilisateur est un contribuable
  bool get isTaxPayer => role.toLowerCase() == 'contribuable';
  
  @override
  String toString() {
    return 'User(id: $id, name: $name, role: $role, zone: $zone)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
