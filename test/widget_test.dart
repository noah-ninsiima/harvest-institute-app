import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:myapp/features/auth/repositories/auth_repository.dart';
import 'package:myapp/features/auth/screens/login_screen.dart';
import 'package:myapp/features/auth/widgets/role_check_wrapper.dart';
import 'package:myapp/features/shared/models/user_model.dart';

// Mock AuthRepository
class MockAuthRepository extends Mock implements AuthRepository {
  final MockUser? _user;
  MockAuthRepository(this._user);

  @override
  Stream<User?> get authStateChanges => Stream.value(_user);
  
  @override
  Future<UserModel?> getUserData(String uid) async {
    if (_user == null) return null;
    return UserModel(
      uid: _user!.uid,
      email: _user!.email!,
      fullName: 'Test User',
      role: UserRole.student,
      contact: '1234567890',
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  testWidgets('RoleCheckWrapper navigates to LoginScreen when no user is logged in', (WidgetTester tester) async {
    // Mock AuthRepository with no user
    final mockAuthRepository = MockAuthRepository(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
        child: const MaterialApp(
          home: RoleCheckWrapper(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify LoginScreen is displayed
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
