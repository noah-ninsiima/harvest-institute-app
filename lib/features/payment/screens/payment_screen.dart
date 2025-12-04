import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:uuid/uuid.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../student/services/payment_service.dart';

enum PaymentMethod { card, mobileMoney }

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  PaymentMethod _selectedMethod = PaymentMethod.mobileMoney; // Default

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final moodleUser = ref.read(authControllerProvider).value;
    if (moodleUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Customer customer = Customer(
        name: moodleUser.fullName,
        phoneNumber: _phoneController.text,
        email: moodleUser.email,
      );

      // Dynamically set payment options based on selection
      // Note: Flutterwave allows comma-separated string for options
      String paymentOptions = "card, mobilemoneyuganda"; 
      if (_selectedMethod == PaymentMethod.card) {
          paymentOptions = "card";
      } else {
          paymentOptions = "mobilemoneyuganda";
      }

      final txRef = const Uuid().v1();

      final Flutterwave flutterwave = Flutterwave(
        publicKey: "FLWPUBK_TEST-SANDBOX", // Placeholder
        currency: "UGX",
        redirectUrl: "https://google.com",
        txRef: txRef,
        amount: _amountController.text,
        customer: customer,
        paymentOptions: paymentOptions,
        customization: Customization(title: "Harvest Institute Tuition"),
        isTestMode: true,
      );

      final ChargeResponse response = await flutterwave.charge(context);

      if (response.success == true) {
        // Record payment in Firestore
        final userId = 'moodle_${moodleUser.userid}';
        await ref.read(paymentServiceProvider).recordPayment(
          userId: userId,
          amount: double.tryParse(_amountController.text) ?? 0.0,
          paymentMethod: _selectedMethod == PaymentMethod.card ? 'Card' : 'Mobile Money',
          txRef: response.txRef ?? txRef,
        );

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Payment Successful!'),
              content: Text('Transaction Ref: ${response.txRef}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to history
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog("Transaction Failed");
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("Error: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Tuition'),
      ),
      body: SingleChildScrollView( // Added scroll view for smaller screens
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter Payment Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Payment Method Selection
              const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<PaymentMethod>(
                      title: const Text('Mobile Money'),
                      value: PaymentMethod.mobileMoney,
                      groupValue: _selectedMethod,
                      onChanged: (PaymentMethod? value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<PaymentMethod>(
                      title: const Text('Card'),
                      value: PaymentMethod.card,
                      groupValue: _selectedMethod,
                      onChanged: (PaymentMethod? value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                       contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (UGX)',
                  border: OutlineInputBorder(),
                  prefixText: 'UGX ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone number field - only show/require if Mobile Money is selected or if we want to collect it anyway
              // Flutterwave usually requires phone for MM, but optional for Card
              if (_selectedMethod == PaymentMethod.mobileMoney)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (for Mobile Money)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 2567...',
                  ),
                  validator: (value) {
                    if (_selectedMethod == PaymentMethod.mobileMoney && (value == null || value.isEmpty)) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green, // Harvest Institute brand color approximation
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _selectedMethod == PaymentMethod.card 
                            ? 'Pay with Card' 
                            : 'Pay with Mobile Money',
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
