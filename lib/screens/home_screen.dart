import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/tax_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_widgets.dart';
import 'payment_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    // Si l'utilisateur est admin, afficher le dashboard
    if (currentUser?.role == 'admin') {
      return const AdminDashboardScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tampay'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Text(
                currentUser?.name ?? 'Utilisateur',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bienvenue
              Text(
                'Bienvenue ${currentUser?.name ?? ''}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Card Info Rapide
              CustomCard(
                backgroundColor: AppTheme.primaryColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taxes à payer',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${_calculatePendingAmount(context)} CFA',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section Taxes disponibles
              Text(
                'Taxes disponibles',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),

              Consumer<TaxProvider>(
                builder: (context, taxProvider, _) {
                  final taxes = taxProvider.taxes;
                  if (taxes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'Aucune taxe disponible',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.greyText),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: taxes.length,
                    itemBuilder: (context, index) {
                      final tax = taxes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: TaxCard(
                          taxName: tax.name,
                          description: tax.description,
                          amount: tax.amount,
                          zone: tax.zone,
                          onTap: () {
                            taxProvider.setSelectedTax(tax);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaymentScreen(),
                              ),
                            );
                          },
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) async {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          } else if (index == 2) {
            // Déconnexion: appeler le provider puis retourner à l'écran de connexion
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            await userProvider.logout();
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Déconnexion',
          ),
        ],
      ),
    );
  }

  double _calculatePendingAmount(BuildContext context) {
    // Calculer le montant des taxes non payées
    final taxProvider = Provider.of<TaxProvider>(context, listen: false);
    return taxProvider.taxes.fold(0.0, (sum, tax) => sum + tax.amount);
  }
}
