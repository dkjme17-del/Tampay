import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../constants/app_theme.dart';
import '../providers/payment_provider.dart';
import '../widgets/custom_widgets.dart';
import '../models/payment.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  bool _selectionMode = false;
  final Set<String> _selectedPaymentIds = <String>{};

  int get _selectedCount => _selectedPaymentIds.length;

  void _toggleSelection(Payment payment) {
    setState(() {
      if (_selectedPaymentIds.contains(payment.id)) {
        _selectedPaymentIds.remove(payment.id);
      } else {
        _selectedPaymentIds.add(payment.id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Load payments for current user
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = Provider.of<UserProvider>(context, listen: false).currentUser;
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      if (user != null) {
        await paymentProvider.loadPayments(userId: user.id);
      }
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historique des paiements')),
        body: Center(
          child: Text('Veuillez vous connecter pour voir votre historique.', style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des paiements'),
        actions: [
          if (_selectionMode)
            IconButton(
              tooltip: 'Annuler sélection',
              onPressed: () {
                setState(() {
                  _selectionMode = false;
                  _selectedPaymentIds.clear();
                });
              },
              icon: const Icon(Icons.close),
            ),
          if (_selectionMode && _selectedCount > 0)
            IconButton(
              tooltip: 'Supprimer la sélection',
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete),
            ),
          if (!_selectionMode)
            IconButton(
              tooltip: 'Sélectionner',
              onPressed: () {
                setState(() => _selectionMode = true);
              },
              icon: const Icon(Icons.check_box_outline_blank),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<PaymentProvider>(
              builder: (context, paymentProvider, _) {
                final payments = paymentProvider.payments;

                if (payments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: AppTheme.greyText),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Aucun paiement enregistré',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: AppTheme.greyText),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[payments.length - 1 - index];
                    final isSelected = _selectedPaymentIds.contains(payment.id);
                    final statusStr = payment.status is String
                        ? payment.status as String
                        : (payment.status is PaymentStatus
                            ? (payment.status as PaymentStatus).name
                            : payment.status.toString());

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectionMode)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(payment),
                              ),
                            ),
                          Expanded(
                            child: PaymentCard(
                              taxName: payment.taxName ?? '',
                              amount: payment.amount,
                              paymentDate: payment.createdAt,
                              status: statusStr,
                              onTap: () {
                                if (_selectionMode) {
                                  _toggleSelection(payment);
                                  return;
                                }
                                // Afficher les détails du paiement
                                _showPaymentDetails(context, payment);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _deleteSelected() async {
    if (_selectedPaymentIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la sélection'),
        content: Text(
          'Voulez-vous supprimer ${_selectedPaymentIds.length} paiement(s) de votre historique ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final pp = Provider.of<PaymentProvider>(context, listen: false);
    final ids = _selectedPaymentIds.toList(growable: false);

    for (final id in ids) {
      // Sequential to keep UI/provider state consistent.
      await pp.deletePayment(id, permanent: true);
      if (!mounted) return;
    }

    if (!mounted) return;
    setState(() {
      _selectionMode = false;
      _selectedPaymentIds.clear();
    });
  }

  void _showPaymentDetails(BuildContext context, Payment payment) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détails du paiement',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _detailRow(context, 'ID de paiement:', payment.id.length > 12 ? payment.id.substring(0, 12) : payment.id),
                  _detailRow(context, 'Taxe:', payment.taxName ?? ''),
                  _detailRow(context, 'Nom:', payment.payerName ?? ''),
                  _detailRow(context, 'Téléphone:', payment.payerPhone ?? ''),
                  _detailRow(
                    context,
                    'Montant:',
                    '${payment.amount.toStringAsFixed(0)} CFA',
                  ),
                  _detailRow(
                    context,
                    'Date:',
                    payment.createdAt.toString().split(' ')[0],
                  ),
                  _detailRow(context, 'Méthode:', payment.paymentMethod),
                  _detailRow(
                    context,
                    'Statut:',
                    (() {
                      final s = payment.status is String
                          ? payment.status as String
                          : (payment.status is PaymentStatus
                              ? (payment.status as PaymentStatus).name
                              : payment.status.toString());
                      return s.toUpperCase();
                    })(),
                  ),
                  _detailRow(context, 'Zone:', payment.zone ?? ''),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirmer la suppression définitive'),
                                content: const Text('Voulez-vous supprimer définitivement ce paiement ? Cette action supprimera l\'entrée localement et sur le serveur si disponible.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer définitivement')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final pp = Provider.of<PaymentProvider>(context, listen: false);
                              final success = await pp.deletePayment(payment.id, permanent: true);
                              if (!mounted) return;
                              Navigator.pop(context); // close bottom sheet
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Paiement supprimé définitivement' : 'Erreur suppression'),
                                  backgroundColor: success ? Colors.green : AppTheme.dangerColor,
                                ),
                              );
                            }
                          },
                          child: const Text('Supprimer définitivement'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.greyText),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
