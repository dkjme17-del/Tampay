import 'package:flutter/material.dart';
import '../models/tax.dart';
import '../services/sync_service.dart';

class TaxProvider extends ChangeNotifier {
  List<Tax> _taxes = [];
  Tax? _selectedTax;
  bool _isLoading = false;
  String? _error;
  final SyncService _syncService = SyncService();

  List<Tax> get taxes => _taxes;
  Tax? get selectedTax => _selectedTax;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TaxProvider() {
    loadTaxes();
  }

  /// Charger les taxes (avec sync automatique)
  Future<void> loadTaxes({String? category, String? zone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _taxes = await _syncService.getTaxes(category: category, zone: zone);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger une taxe spécifique
  Future<void> loadTax(String taxId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final tax = await _syncService.getTax(taxId);
      if (tax != null) {
        _selectedTax = tax;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Définir la taxe sélectionnée
  void setSelectedTax(Tax tax) {
    _selectedTax = tax;
    notifyListeners();
  }

  /// Récupérer les taxes par catégorie
  List<Tax> getTaxesByCategory(String category) {
    return _taxes.where((tax) => tax.category == category).toList();
  }

  /// Récupérer les taxes par zone
  List<Tax> getTaxesByZone(String zone) {
    return _taxes.where((tax) => tax.zone == zone).toList();
  }

  /// Rechercher les taxes
  List<Tax> searchTaxes(String query) {
    return _taxes
        .where(
          (tax) =>
              tax.name.toLowerCase().contains(query.toLowerCase()) ||
              tax.description.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  /// Effacer le message d'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
