// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'history_screen.dart';
import '../providers/payment_provider.dart';
import '../services/payment_operators/payment_operators_manager.dart';
import '../services/payment_operators/card_payment_service.dart';
import '../models/payment.dart';

class MultiChannelPaymentScreen extends StatefulWidget {
  final String taxId;
  final String taxName;
  final double amount;
  final String userCountry;
  final String? payerName;
  final String? payerPhone;

  const MultiChannelPaymentScreen({
    Key? key,
    required this.taxId,
    required this.taxName,
    required this.amount,
    this.userCountry = 'SN',
    this.payerName,
    this.payerPhone,
  }) : super(key: key);

  @override
  State<MultiChannelPaymentScreen> createState() =>
      _MultiChannelPaymentScreenState();
}

class _MultiChannelPaymentScreenState extends State<MultiChannelPaymentScreen> {
  String? _selectedOperator;
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefill phone for non-card flows (Mobile Money) to avoid losing payer info.
    _phoneController.text = widget.payerPhone ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner le moyen de paiement'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations de la taxe
            _buildTaxInfoCard(),

            // Sélection de l'opérateur
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Méthode de paiement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Bouton pour recharger le portefeuille
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _showTopUpDialog,
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('Recharger mon compte'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOperatorGrid(),
                ],
              ),
            ),

            // Formulaire spécifique à l'opérateur
            if (_selectedOperator != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildOperatorForm(),
              ),

            // Bouton de paiement
            if (_selectedOperator != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPaymentButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxInfoCard() {
    final total = PaymentOperatorsManager.calculateTotal(
      _selectedOperator ?? 'orange_money',
      widget.amount,
    );
    final fees = PaymentOperatorsManager.calculateFees(
      _selectedOperator ?? 'orange_money',
      widget.amount,
    );

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.taxName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Montant:'),
                Text(
                  '${widget.amount.toStringAsFixed(0)} XOF',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_selectedOperator != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Frais:'),
                  Text(
                    '${fees.toStringAsFixed(0)} XOF',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${total.toStringAsFixed(0)} XOF',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorGrid() {
    final enabledOperators = PaymentOperatorsManager.getAvailableOperators(
      widget.userCountry,
    );
    final allOperators = PaymentOperatorsManager.supportedOperators;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: allOperators.map((operator) {
        final info = PaymentOperatorsManager.getOperatorInfo(operator);
        final isSelected = _selectedOperator == operator;
        final isEnabled = enabledOperators.contains(operator);

        return GestureDetector(
          onTap: () {
            if (!isEnabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${info?['name'] ?? operator} non disponible dans votre pays',
                  ),
                ),
              );
              return;
            }
            setState(() {
              _selectedOperator = operator;
            });
          },
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? Colors.blue.shade50 : Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    info?['icon'] ?? '💳',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info?['name'] ?? operator,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Frais: ${info?['fees']}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOperatorForm() {
    switch (_selectedOperator) {
      case 'card':
        return _buildCardForm();
      default:
        return _buildPhoneForm();
    }
  }

  Widget _buildPhoneForm() {
    // Obtenir les infos pour le message d'instruction
    final _ = PaymentOperatorsManager.getOperatorInfo(_selectedOperator!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de téléphone',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+225 70123456',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  PaymentOperatorsManager.getPaymentInstructions(
                    _selectedOperator!,
                  ),
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de carte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          maxLength: 19,
          decoration: InputDecoration(
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) {
            setState(() {}); // Rafraîchir pour voir le type de carte
          },
        ),
        const SizedBox(height: 8),
        Text(
          _cardNumberController.text.isEmpty
              ? 'Carte inconnue'
              : CardPaymentService.detectCardType(_cardNumberController.text),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 16),
        const Text(
          'Titulaire de la carte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cardHolderController,
          decoration: InputDecoration(
            hintText: 'Nom Prénom',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expiration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: InputDecoration(
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CVV',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '123',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock, color: Colors.amber, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '🔒 Vos données de carte sont sécurisées par 3D Secure',
                  style: TextStyle(fontSize: 13, color: Colors.amber),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: paymentProvider.isLoading ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: paymentProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Payer ${widget.amount.toStringAsFixed(0)} XOF',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _processPayment() async {
    if (_selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un moyen de paiement'),
        ),
      );
      return;
    }

    final paymentProvider = context.read<PaymentProvider>();

    try {
      Map<String, dynamic> operatorData = {};

      if (_selectedOperator == 'card') {
        if (_cardNumberController.text.isEmpty ||
            _cardHolderController.text.isEmpty ||
            _expiryController.text.isEmpty ||
            _cvvController.text.isEmpty) {
          throw Exception('Veuillez remplir tous les champs de la carte');
        }

        operatorData = {
          'cardNumber': _cardNumberController.text,
          'cardHolder': _cardHolderController.text,
          'expiryDate': _expiryController.text,
          'cvv': _cvvController.text,
          'country': widget.userCountry,
        };
      } else {
        if (_phoneController.text.isEmpty) {
          throw Exception('Veuillez entrer un numéro de téléphone');
        }

        // Mobile Money: include payer info in `metadata` so admin history can display it.
        operatorData = {
          'phoneNumber': _phoneController.text,
          'payerPhone': _phoneController.text,
          'payerName': widget.payerName,
          'name': widget.payerName,
        };
      }

      final success = await paymentProvider.createPaymentWithOperator(
        taxId: widget.taxId,
        amount: widget.amount,
        operator: _selectedOperator!,
        operatorData: operatorData,
      );

      if (!mounted) return;
      if (success) {
        // Récupérer le paiement sélectionné et montrer le reçu
        final payment = paymentProvider.selectedPayment;
        if (payment != null) {
          await _showReceiptDialog(payment);
          // Après fermeture du dialogue, aller à l'historique
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement initié avec succès'),
              duration: Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          Navigator.of(context).pop(true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${paymentProvider.error}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  Future<void> _showReceiptDialog(Payment payment) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 12),
                const Text('Paiement confirmé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: payment.qrCode != null
                            ? QrImageView(data: payment.qrCode!, size: 180.0)
                            : const Center(child: Icon(Icons.qr_code_2, size: 100)),
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${payment.id.isNotEmpty ? payment.id.substring(0, 8) : payment.id}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _receiptRow('Taxe:', payment.taxName ?? ''),
                        const SizedBox(height: 8),
                        _receiptRow('Montant:', '${payment.amount.toStringAsFixed(0)} XOF', isBold: true),
                        const SizedBox(height: 8),
                        _receiptRow('Date:', payment.createdAt.toString().split('.')[0]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Fermer seulement le dialogue; la navigation vers l'historique
                      // est gérée par l'appelant après await _showReceiptDialog
                      Navigator.pop(context);
                    },
                    child: const Text('Retour à l\'accueil'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  // Affiche un dialogue pour recharger le compte utilisateur
  Future<void> _showTopUpDialog() async {
    final paymentProvider = context.read<PaymentProvider>();
    String selectedOperator = PaymentOperatorsManager.supportedOperators.first;
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        // Liste des opérateurs disponibles pour affichage (avec état d'activation)
        final enabled = PaymentOperatorsManager.getAvailableOperators(
          widget.userCountry,
        );

        return AlertDialog(
          title: const Text('Recharger mon compte'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant',
                        hintText: '1000',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedOperator,
                      items: PaymentOperatorsManager.supportedOperators.map((
                        op,
                      ) {
                        final info = PaymentOperatorsManager.getOperatorInfo(
                          op,
                        );
                        final isEnabled = enabled.contains(op);
                        return DropdownMenuItem<String>(
                          value: op,
                          child: Row(
                            children: [
                              Text(info?['icon'] ?? ''),
                              const SizedBox(width: 8),
                              Text(info?['name'] ?? op),
                              const SizedBox(width: 8),
                              if (!isEnabled)
                                const Text(
                                  ' (non disponible)',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() {
                        selectedOperator = v ?? selectedOperator;
                      }),
                      decoration: const InputDecoration(labelText: 'Opérateur'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Numéro (si requis)',
                        hintText: '+2250102487848',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final raw = amountController.text.trim();
                final amount = double.tryParse(raw.replaceAll(',', '')) ?? 0.0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Montant invalide')),
                  );
                  return;
                }

                // Préparer les données opérateur
                final operatorData = <String, dynamic>{};
                if (selectedOperator == 'card') {
                  // Pour demo, on ouvre la page carte — ici on demande le numéro
                  operatorData['cardNumber'] = phoneController.text.trim();
                } else {
                  operatorData['phoneNumber'] = phoneController.text.trim();
                }

                Navigator.of(context).pop();

                // Utiliser createPaymentWithOperator avec taxId spécial 'topup'
                final success = await paymentProvider.createPaymentWithOperator(
                  taxId: 'topup',
                  amount: amount,
                  operator: selectedOperator,
                  operatorData: {
                    ...operatorData,
                    'amount': amount,
                    'transactionId': DateTime.now().millisecondsSinceEpoch
                        .toString(),
                  },
                );

                if (!mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rechargement initié')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${paymentProvider.error}')),
                  );
                }
              },
              child: const Text('Recharger'),
            ),
          ],
        );
      },
    );
  }
}
