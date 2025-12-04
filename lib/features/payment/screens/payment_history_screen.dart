import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../student/services/payment_service.dart';
import '../../shared/models/payment_model.dart';
import 'payment_screen.dart';

final paymentHistoryProvider = StreamProvider.autoDispose<List<PaymentModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return Stream.value([]);
  // Moodle user ID is int, but Firestore uses string 'moodle_ID'
  final firestoreUid = 'moodle_${user.userid}'; 
  return ref.watch(paymentServiceProvider).getPaymentHistory(firestoreUid);
});

final outstandingBalanceProvider = FutureProvider.autoDispose<double>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return 0.0;
  final firestoreUid = 'moodle_${user.userid}';
  return ref.watch(paymentServiceProvider).getOutstandingBalance(firestoreUid);
});

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(paymentHistoryProvider);
    final balanceAsync = ref.watch(outstandingBalanceProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuition & Payments'),
      ),
      body: Column(
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColorDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Outstanding Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                balanceAsync.when(
                  data: (balance) => Text(
                    currencyFormat.format(balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const CircularProgressIndicator(color: Colors.white),
                  error: (_, __) => const Text(
                    'Error loading balance',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Pay Tuition Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // History List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Payment History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: historyAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return const Center(
                    child: Text('No payment history found.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: payment.status == 'completed' 
                              ? Colors.green.withOpacity(0.1) 
                              : Colors.orange.withOpacity(0.1),
                          child: Icon(
                            payment.status == 'completed' ? Icons.check_circle : Icons.pending,
                            color: payment.status == 'completed' ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          currencyFormat.format(payment.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${DateFormat.yMMMd().format(payment.date)} • ${payment.paymentMethod}',
                        ),
                        trailing: Text(
                          payment.status.toUpperCase(),
                          style: TextStyle(
                            color: payment.status == 'completed' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

