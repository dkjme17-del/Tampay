import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/payment.dart';
import '../providers/payment_provider.dart';
import '../providers/tax_provider.dart';
import '../widgets/custom_widgets.dart';
import 'multi_channel_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taxProvider = Provider.of<TaxProvider>(context);
    final tax = taxProvider.selectedTax;

    if (tax == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paiement')),
        body: const Center(child: Text('Erreur: Taxe non sélectionnée')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement de taxe')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Résumé du paiement
              CustomCard(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Résumé du paiement',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Type de taxe:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          tax.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Zone:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          tax.zone,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Montant:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${tax.amount.toStringAsFixed(0)} CFA',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Formulaire de paiement
              Text(
                'Informations de paiement',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),

              // Nom
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: const Icon(Icons.person),
                  hintText: 'Entrez votre nom',
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Téléphone
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: const Icon(Icons.phone),
                  hintText: '+225 0702836421',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Méthode de paiement
              Text(
                'Méthode de paiement',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),

              Wrap(
                spacing: AppSpacing.md,
                children: [
                  _buildPaymentMethodButton('Mobile Money'),
                  _buildPaymentMethodButton('Virement'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Bouton de paiement
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _processPayment(context, tax),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isProcessing
                        ? 'Traitement en cours...'
                        : 'Confirmer le paiement',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Télécharger le reçu (si disponible)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final payment = context.read<PaymentProvider>().selectedPayment;
                    if (payment != null) {
                      _downloadReceipt(payment);
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Télécharger le reçu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodButton(String method) {
    final isSelected = _selectedPaymentMethod == method;
    return FilterChip(
      label: Text(method),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPaymentMethod = selected ? method : null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, dynamic tax) async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }
    // Si l'utilisateur choisit Mobile Money ou Carte bancaire, ouvrir l'écran multi-opérateur
    if (_selectedPaymentMethod == 'Mobile Money' ||
        _selectedPaymentMethod == 'Carte bancaire') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiChannelPaymentScreen(
            taxId: tax.id,
            taxName: tax.name,
            amount: tax.amount.toDouble(),
            userCountry: 'SN',
            payerName: _nameController.text,
            payerPhone: _phoneController.text,
          ),
        ),
      );
      return;
    }
    setState(() => _isProcessing = true);

    try {
      // Créer le paiement via le provider
      final paymentProvider = context.read<PaymentProvider>();
      // Map human-friendly label to canonical payment method key
      final methodKey = _mapPaymentMethod(_selectedPaymentMethod!);
      // ignore: use_build_context_synchronously
      final success = await paymentProvider.createPayment(
        taxId: tax.id,
        amount: tax.amount,
        paymentMethod: methodKey,
      );

      if (!mounted) return;
      if (!success) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
        return;
      }

      // Afficher le reçu
      final payment = paymentProvider.selectedPayment;
      if (payment != null) {
        setState(() => _isProcessing = false);
        _showReceiptDialog(context, payment);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  // Map display labels to canonical payment method identifiers
  String _mapPaymentMethod(String label) {
    final l = label.toLowerCase();
    if (l.contains('mobile')) return 'mobile_money';
    if (l.contains('virement') || l.contains('transfer') || l.contains('bank')) return 'bank_transfer';
    if (l.contains('carte') || l.contains('card') || l.contains('credit')) return 'credit_card';
    if (l.contains('cash')) return 'cash';
    // Fallback: try to normalize common separators
    switch (l) {
      case 'mobile money':
        return 'mobile_money';
      case 'carte bancaire':
        return 'credit_card';
      case 'virement':
        return 'bank_transfer';
      default:
        return l.replaceAll(' ', '_');
    }
  }

  void _showReceiptDialog(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.secondaryColor,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Paiement confirmé',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                CustomCard(
                  child: Column(
                    children: [
                      Text(
                        'Reçu électronique',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Container(
                          color: AppTheme.lightBackground,
                          alignment: Alignment.center,
                          child: payment.qrCode != null
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: QrImageView(
                                    data: payment.qrCode!,
                                    size: 180.0,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 100,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'QR CODE',
                                      style: Theme.of(context).textTheme.labelSmall
                                          ?.copyWith(color: AppTheme.greyText),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'ID: ${payment.id.substring(0, 8)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _receiptRow(context, 'Nom:', _nameController.text),
                      const SizedBox(height: AppSpacing.sm),
                      _receiptRow(context, 'Téléphone:', _phoneController.text),
                      const SizedBox(height: AppSpacing.sm),
                      _receiptRow(context, 'Taxe:', payment.taxName ?? ''),
                      const SizedBox(height: AppSpacing.sm),
                      _receiptRow(
                        context,
                        'Montant:',
                        '${payment.amount.toStringAsFixed(0)} CFA',
                        isBold: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _receiptRow(
                        context,
                        'Date:',
                        payment.createdAt.toString().split('.')[0],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('Retour à l\'accueil'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _downloadReceipt(payment);
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Télécharger le reçu (PDF)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadReceipt(Payment payment) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Reçu de paiement', style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 12),
                pw.Text('ID: ${payment.id}'),
                pw.Text('Nom: ${_nameController.text}'),
                pw.Text('Téléphone: ${_phoneController.text}'),
                pw.Text('Taxe: ${payment.taxName ?? ''}'),
                pw.Text('Montant: ${payment.amount.toStringAsFixed(0)} CFA'),
                pw.Text('Date: ${payment.createdAt.toString()}'),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.BarcodeWidget(
                    data: payment.qrCode ?? payment.id,
                    barcode: pw.Barcode.qrCode(),
                    width: 150,
                    height: 150,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(child: pw.Text('ID: ${payment.id.substring(0, 12)}')),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'recu_${payment.id}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur génération PDF: $e')),
        );
      }
    }
  }

  Widget _receiptRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
