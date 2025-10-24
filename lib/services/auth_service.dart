import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static const _kIsLoggedIn = 'is_logged_in';
  static const _kUserEmail = 'user_email';
  static const _kUserName = 'user_name';

  Future<void> signIn(String email, String password) async {
    if (email.isEmpty || password.length < 6) {
      throw Exception('Invalid credentials');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, true);
    await prefs.setString(_kUserEmail, email);
    // Provide a friendly default user name based on email if missing
    final existingName = prefs.getString(_kUserName);
    if (existingName == null || existingName.trim().isEmpty) {
      final localPart = email.split('@').first;
      final display = localPart.isNotEmpty
          ? localPart[0].toUpperCase() + localPart.substring(1)
          : 'User';
      await prefs.setString(_kUserName, display);
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    if (email.isEmpty || password.length < 6 || name.isEmpty) {
      throw Exception('Please fill all fields correctly');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserName, name);
    await prefs.setString(_kUserEmail, email);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, false);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsLoggedIn) ?? false;
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserName) ?? '';
  }

  Future<void> updateUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserName, name);
  }
}
