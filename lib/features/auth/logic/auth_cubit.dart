import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(AuthInitial());

  /// Check Status on App Start
  Future<void> checkAuthStatus() async {
    // Check if user session exists
    final user = _authService.currentUser;
    if (user != null) {
      // Check approval
      emit(AuthLoading());
      try {
        final isApproved = await _authService.isUserApproved();
        if (isApproved) {
          emit(AuthAuthenticated(user.id));
        } else {
          emit(const AuthUnapproved());
        }
      } catch (e) {
        emit(AuthError('فشل التحقق من حالة الحساب: $e'));
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  /// Sign In Logic
  Future<void> signIn(String phone, String password) async {
    emit(AuthLoading());
    try {
      await _authService.signIn(phone: phone, password: password);

      // Perform Approval Check
      final isApproved = await _authService.isUserApproved();
      if (isApproved) {
        emit(AuthAuthenticated(_authService.currentUser!.id));
      } else {
        emit(const AuthUnapproved());
      }
    } catch (e) {
      emit(AuthError(_mapErrorMessage(e.toString())));
    }
  }

  /// Sign Up Logic
  Future<void> signUp({
    required String phone,
    required String password,
    required String fullName,
    required String shopName,
  }) async {
    emit(AuthLoading());
    try {
      await _authService.signUp(
        phone: phone,
        password: password,
        fullName: fullName,
        shopName: shopName,
      );
      // New users are unapproved by default
      emit(
        const AuthUnapproved(
          message: "تم إنشاء الحساب بنجاح. يرجى انتظار موافقة الإدارة.",
        ),
      );
    } catch (e) {
      emit(AuthError(_mapErrorMessage(e.toString())));
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _authService.signOut();
    emit(AuthUnauthenticated());
  }

  String _mapErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'رقم الهاتف أو كلمة المرور غير صحيحة';
    }
    if (error.contains('User already registered')) {
      return 'رقم الهاتف مسجل بالفعل';
    }
    return 'حدث خطأ غير متوقع: $error';
  }
}
