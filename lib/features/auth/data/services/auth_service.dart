import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Checks if the current user is approved by admin
  Future<bool> isUserApproved() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('profiles')
          .select('is_approved')
          .eq('id', user.id)
          .single();

      return response['is_approved'] as bool? ?? false;
    } catch (e) {
      // If profile doesn't exist or error, assume not approved
      return false;
    }
  }

  /// Sign Up with Phone (as Email identifier) and Password
  Future<AuthResponse> signUp({
    required String phone,
    required String password,
    required String fullName,
    required String shopName,
  }) async {
    // Using a fake email domain to support Phone+Password flow without SMS setup
    final email = '$phone@alnoor.com';

    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'phone': phone, 'full_name': fullName, 'shop_name': shopName},
    );

    // Create Profile Entry manually if Trigger is not set up
    // Ideally the SQL trigger handles this, but for robustness client-side:
    final user = response.user;
    if (user != null) {
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'phone': phone,
          'full_name': fullName,
          'shop_name': shopName,
          'is_approved': false,
        });
      } catch (e) {
        // Profile might already exist if trigger ran
      }
    }

    return response;
  }

  /// Get User Profile Data
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Sign In with Phone and Password
  Future<AuthResponse> signIn({
    required String phone,
    required String password,
  }) async {
    final email = '$phone@alnoor.com';
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get Current User
  User? get currentUser => _supabase.auth.currentUser;
}
