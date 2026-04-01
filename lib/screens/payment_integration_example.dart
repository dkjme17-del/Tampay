// Exemple d'intégration du système de paiement multicanal
// dans un écran de paiement existant

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tax_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/user_provider.dart';
import 'multi_channel_payment_screen.dart';
import 'payment_confirmation_screen.dart';

/// Exemple d'intégration dans un écran de paiement existant
class PaymentScreenWithMultiChannel extends StatefulWidget {
  final String? taxId;

  const PaymentScreenWithMultiChannel({Key? key, this.taxId}) : super(key: key);

  @override
  State<PaymentScreenWithMultiChannel> createState() =>
      _PaymentScreenWithMultiChannelState();
}

class _PaymentScreenWithMultiChannelState
    extends State<PaymentScreenWithMultiChannel> {
  String? _selectedTaxId;
  double? _selectedAmount;
  String? _selectedTaxName;

  @override
  void initState() {
    super.initState();
    _selectedTaxId = widget.taxId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Effectuer un paiement')),
      body: Column(
        children: [
          // Sélection de la taxe
          Expanded(child: _buildTaxesList()),

          // Bouton de paiement
          if (_selectedTaxId != null && _selectedAmount != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildPaymentButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildTaxesList() {
    return Consumer<TaxProvider>(
      builder: (context, taxProvider, _) {
        if (taxProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (taxProvider.taxes.isEmpty) {
          return const Center(child: Text('Aucune taxe disponible'));
        }

        return ListView.builder(
          itemCount: taxProvider.taxes.length,
          itemBuilder: (context, index) {
            final tax = taxProvider.taxes[index];
            final isSelected = _selectedTaxId == tax.id;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isSelected ? Colors.blue.shade50 : Colors.white,
              child: ListTile(
                leading: Radio<String?>(
                  value: tax.id,
                  groupValue: _selectedTaxId,
                  onChanged: (value) {
                    setState(() {
                      _selectedTaxId = value;
                      _selectedAmount = double.tryParse(tax.amount.toString());
                      _selectedTaxName = tax.name;
                    });
                  },
                ),
                title: Text(tax.name),
                subtitle: Text(tax.description),
                trailing: Text(
                  '${tax.amount.toStringAsFixed(0)} XOF',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentButton() {
    return Consumer2<PaymentProvider, UserProvider>(
      builder: (context, paymentProvider, userProvider, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _navigateToPaymentMethod(context, userProvider),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Payer ${_selectedAmount?.toStringAsFixed(0)} XOF',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToPaymentMethod(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    if (_selectedTaxId == null || _selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une taxe')),
      );
      return;
    }

    final user = userProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur non connecté')));
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MultiChannelPaymentScreen(
          taxId: _selectedTaxId!,
          taxName: _selectedTaxName ?? 'Taxe',
          amount: _selectedAmount!,
          userCountry: user.zone ?? 'SN',
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text('Paiement effectué avec succès'),
          duration: Duration(seconds: 3),
        ),
      );
      // Recharger la liste des paiements
      context.read<PaymentProvider>().loadPayments(
            userId: user.role.toLowerCase() == 'admin' ? null : user.id,
          );
    }
  }
}

/// Exemple pour appeler depuis un écran existant
class PaymentIntegrationExample {
  /// Fonction pour initier un paiement multicanal
  static Future<void> initiateMultiChannelPayment(
    BuildContext context, {
    required String taxId,
    required String taxName,
    required double amount,
    required String userCountry,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MultiChannelPaymentScreen(
          taxId: taxId,
          taxName: taxName,
          amount: amount,
          userCountry: userCountry,
        ),
      ),
    );
    if (!context.mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Paiement réussi')));
    }
  }

  /// Fonction pour afficher le statut de paiement
  static void showPaymentStatus(
    BuildContext context, {
    required String paymentId,
    required String operator,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PaymentConfirmationScreen(paymentId: paymentId, operator: operator),
      ),
    );
  }
}
