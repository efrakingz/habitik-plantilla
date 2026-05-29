import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: const _LoginScreenContent(),
    );
  }
}

class _LoginScreenContent extends StatelessWidget {
  const _LoginScreenContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.green700, Color(0xFF00695C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.green500,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.green500, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
                    ),
                    child: const Icon(Icons.eco, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('Habitik', style: TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900,
                  )),
                  const SizedBox(height: 4),
                  const Text('Tu hogar sustentable', style: TextStyle(
                    color: AppTheme.green200, fontSize: 14,
                  )),
                  const SizedBox(height: 32),

                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.error != null) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: auth.error!.contains('Revisa') 
                              ? AppTheme.amber400.withValues(alpha: 0.3) 
                              : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(auth.error!, style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
                          )),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  if (controller.isSignUp) _buildField(context, controller.nombreController, 'Nombre', Icons.person_outline, false),
                  const SizedBox(height: 12),
                  _buildField(context, controller.emailController, 'Correo electrónico', Icons.email_outlined, false),
                  const SizedBox(height: 12),
                  _buildField(context, controller.passController, 'Contraseña', Icons.lock_outline, true),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.loading ? null : () => controller.submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.amber400,
                        foregroundColor: AppTheme.textDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      child: controller.loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(controller.isSignUp ? 'Crear cuenta' : 'Iniciar sesión'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Row(children: [
                    Expanded(child: Divider(color: AppTheme.green500)),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o continuar con', style: TextStyle(color: AppTheme.green200, fontSize: 12))),
                    Expanded(child: Divider(color: AppTheme.green500)),
                  ]),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => controller.signInWithGoogle(context),
                      icon: _googleIcon(),
                      label: const Text('Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.green500),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextButton(
                    onPressed: () => controller.toggleSignUp(context),
                    child: Text(
                      controller.isSignUp ? '¿Ya tienes cuenta? Iniciar sesión' : '¿No tienes cuenta? Crear cuenta',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, TextEditingController ctrl, String label, IconData icon, bool isPassword) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.green500.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.black,
            selectionColor: AppTheme.green200,
            selectionHandleColor: AppTheme.green700,
          ),
        ),
        child: TextField(
          controller: ctrl,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.green700, size: 20),
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return Container(
      width: 20, height: 20,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(child: Text('G', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13))),
    );
  }
}
