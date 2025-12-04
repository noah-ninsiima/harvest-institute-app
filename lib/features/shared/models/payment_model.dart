import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String userId;
  final double amount;
  final String status; // 'completed', 'pending', 'failed'
  final DateTime date;
  final String paymentMethod;
  final String? description;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.date,
    required this.paymentMethod,
    this.description,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      date: (data['date'] as Timestamp).toDate(),
      paymentMethod: data['paymentMethod'] ?? 'Unknown',
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'status': status,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod,
      'description': description,
    };
  }
}

