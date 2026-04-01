import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../services/payment_operators/payment_operators_manager.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final String paymentId;
  final String operator;

  const PaymentConfirmationScreen({Key? key,
    required this.paymentId,
    required this.operator,
  }) : super(key: key);

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _verificationCodeController = TextEditingController();
  bool _isCheckingStatus = false;
  String? _paymentStatus;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Commencer à vérifier le statut toutes les 5 secondes
    _startStatusPolling();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _startStatusPolling() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      try {
        final paymentProvider = context.read<PaymentProvider>();
        // ignore: use_build_context_synchronously
        final status = await paymentProvider.checkTransactionStatus(
          'REF-${widget.paymentId}',
        );

        if (mounted) {
          setState(() {
            _paymentStatus = status['status'];
          });

          if (_paymentStatus == 'success') {
            _showSuccessDialog();
          }
        }
      } catch (e) {
        // Continuer les tentatives
        if (mounted) {
          _startStatusPolling();
        }
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✅ Paiement réussi'),
        content: const Text('Votre paiement a été traité avec succès.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialog
              Navigator.of(context).pop(true); // Revenir à l'écran précédent
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final operatorInfo = PaymentOperatorsManager.getOperatorInfo(
      widget.operator,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation du paiement'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animation du statut de paiement
              _buildStatusAnimation(),

              const SizedBox(height: 32),

              // Informations de l'opérateur
              _buildOperatorInfo(operatorInfo),

              const SizedBox(height: 32),

              // Instructions de confirmation
              _buildInstructions(),

              const SizedBox(height: 32),

              // Saisie du code de vérification
              _buildVerificationCodeForm(),

              const SizedBox(height: 32),

              // Boutons d'action
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAnimation() {
    return Column(
      children: [
        ScaleTransition(
          scale: Tween<double>(begin: 1, end: 1.2).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _paymentStatus == 'success' ? Icons.check_circle : Icons.pending,
              color: _paymentStatus == 'success' ? Colors.green : Colors.blue,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _paymentStatus == 'success'
              ? 'Paiement réussi'
              : 'Paiement en cours...',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildOperatorInfo(Map<String, dynamic>? info) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(info?['icon'] ?? '💳', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              info?['name'] ?? widget.operator,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${widget.paymentId}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    final instructions = PaymentOperatorsManager.getPaymentInstructions(
      widget.operator,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade900, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Instructions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            instructions,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade900,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCodeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Code de vérification',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _verificationCodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Entrez le code reçu sur votre téléphone',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCheckingStatus ? null : _confirmPayment,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
            ),
            child: _isCheckingStatus
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Confirmer le paiement',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _cancelPayment,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text(
              'Annuler le paiement',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmPayment() async {
    final code = _verificationCodeController.text;

    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un code à 6 chiffres')),
      );
      return;
    }

    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final paymentProvider = context.read<PaymentProvider>();
      final success = await paymentProvider.verifyPayment(
        widget.paymentId,
        verificationCode: code,
      );

      if (!mounted) return;
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Code incorrect')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  Future<void> _cancelPayment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le paiement?'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler ce paiement? Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      Navigator.of(context).pop(false);
    }
  }
}
