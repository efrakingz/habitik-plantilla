import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class LoginController extends ChangeNotifier {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final nombreController = TextEditingController();
  bool isSignUp = false;
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    nombreController.dispose();
    super.dispose();
  }

  void toggleSignUp(BuildContext context) {
    isSignUp = !isSignUp;
    context.read<AuthProvider>().clearError();
    notifyListeners();
  }

  Future<void> submit(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    loading = true;
    notifyListeners();

    if (isSignUp) {
      await auth.signUp(emailController.text.trim(), passController.text, nombreController.text.trim());
    } else {
      await auth.signInWithEmail(emailController.text.trim(), passController.text);
    }
    
    loading = false;
    notifyListeners();
  }

  void signInWithGoogle(BuildContext context) {
    context.read<AuthProvider>().signInWithGoogle();
  }
}
