// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/payment_provider.dart';
import '../widgets/custom_widgets.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedFilter = 'all'; // all, pending, completed, verified

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Municipal'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await authService.logout();
              } catch (_) {}
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats principales
              Consumer<PaymentProvider>(
                builder: (context, paymentProvider, _) {
                  // Calculate totals dynamically from the current payments cache
                  final paymentsList = paymentProvider.payments;
                  final totalRevenue = paymentsList.fold<double>(0.0, (sum, p) => sum + (p.amount ?? 0.0));
                  final totalPayments = paymentsList.length;
                  final completedPayments = paymentProvider
                      .getPaymentsByStatus('completed')
                      .length;
                  final pendingPayments = paymentProvider
                      .getPaymentsByStatus('pending')
                      .length;

                  return Column(
                    children: [
                      // Revenue Card
                      CustomCard(
                        backgroundColor: AppTheme.primaryColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recettes totales',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${totalRevenue.toStringAsFixed(0)} CFA',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.2,
                        children: [
                          _buildStatCard(
                            context,
                            'Total',
                            totalPayments.toString(),
                            AppTheme.primaryColor,
                            Icons.payments,
                          ),
                          _buildStatCard(
                            context,
                            'Complétés',
                            completedPayments.toString(),
                            AppTheme.secondaryColor,
                            Icons.check_circle,
                          ),
                          _buildStatCard(
                            context,
                            'En attente',
                            pendingPayments.toString(),
                            AppTheme.accentColor,
                            Icons.pending_actions,
                          ),
                          _buildStatCard(
                            context,
                            'Vérifiés',
                            paymentProvider
                                .getPaymentsByStatus('verified')
                                .length
                                .toString(),
                            AppTheme.primaryColor,
                            Icons.verified,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Filtres
              Text(
                'Taxes payées',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  _buildFilterChip('Tous', 'all'),
                  _buildFilterChip('En attente', 'pending'),
                  _buildFilterChip('Complétés', 'completed'),
                  _buildFilterChip('Vérifiés', 'verified'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Liste des paiements
              Consumer<PaymentProvider>(
                builder: (context, paymentProvider, _) {
                  List<Payment> payments = paymentProvider.payments;

                  if (_selectedFilter != 'all') {
                    payments = paymentProvider.getPaymentsByStatus(
                      _selectedFilter,
                    );
                  }

                  if (payments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'Aucun paiement',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.greyText),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[payments.length - 1 - index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: CustomCard(
                          child: ListTile(
                            leading: Icon(
                              _getStatusIcon(payment.status),
                              color: _getStatusColor(payment.status),
                            ),
                            title: Text(payment.taxName ?? ''),
                            subtitle: Text(
                              '${payment.paymentMethod} • ${payment.payerName ?? payment.zone ?? ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${payment.amount.toStringAsFixed(0)} CFA',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (payment.status is String
                                          ? (payment.status as String)
                                          : payment.status.name)
                                      .toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: _getStatusColor(payment.status),
                                      ),
                                ),
                              ],
                            ),
                            onTap: () =>
                                _showPaymentDetailsAdmin(context, payment),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.greyText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
    );
  }

  IconData _getStatusIcon(dynamic status) {
    final s = status is String ? status : (status is PaymentStatus ? status.name : status.toString());
    switch (s) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending_actions;
      case 'verified':
        return Icons.verified;
      default:
        return Icons.error;
    }
  }

  Color _getStatusColor(dynamic status) {
    final s = status is String ? status : (status is PaymentStatus ? status.name : status.toString());
    switch (s) {
      case 'completed':
        return AppTheme.secondaryColor;
      case 'pending':
        return AppTheme.accentColor;
      case 'verified':
        return AppTheme.primaryColor;
      default:
        return AppTheme.dangerColor;
    }
  }

  void _showPaymentDetailsAdmin(BuildContext context, dynamic payment) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.25,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détails du paiement',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _detailRow(context, 'ID:', payment.id.length > 12 ? payment.id.substring(0, 12) : payment.id),
                      _detailRow(context, 'Payeur:', payment.payerName ?? 'N/A'),
                      _detailRow(context, 'Téléphone:', payment.payerPhone ?? 'N/A'),
                      _detailRow(context, 'Taxe:', payment.taxName ?? ''),
                      _detailRow(context, 'Montant:', '${payment.amount.toStringAsFixed(0)} CFA'),
                      _detailRow(context, 'Date:', payment.createdAt.toString().split(' ')[0]),
                      _detailRow(context, 'Zone:', payment.zone),
                      _detailRow(context, 'Méthode:', payment.paymentMethod),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final paymentProvider = context.read<PaymentProvider>();
                                bool success = false;
                                try {
                                  success = await paymentProvider.verifyPayment(payment.id, verificationCode: null);
                                } catch (e) {
                                  success = false;
                                }
                                if (!mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Paiement vérifié' : 'Erreur lors de la vérification'),
                                    backgroundColor: success ? AppTheme.secondaryColor : AppTheme.dangerColor,
                                  ),
                                );
                              },
                              child: const Text('Vérifier le paiement'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor, foregroundColor: Colors.white),
                              onPressed: () async {
                                final paymentProvider = context.read<PaymentProvider>();
                                final success = await paymentProvider.deletePayment(payment.id);
                                if (!mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Paiement supprimé' : 'Erreur suppression'),
                                    backgroundColor: success ? AppTheme.secondaryColor : AppTheme.dangerColor,
                                  ),
                                );
                              },
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
