import 'package:flutter/material.dart';
import '../../services/auth_api_client.dart';
import 'login_screen.dart';

/// Pantalla de restablecimiento de contraseña.
/// Paso 1: el usuario ingresa su correo y se le envía un código.
/// Paso 2: el usuario ingresa el código y su nueva contraseña.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _ink = Color(0xFF263020);
  static const _background = Color(0xFFFBF5F2);
  static const _surface = Color(0xFFF3ECE8);

  final _apiClient = AuthApiClient();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _codeSent = false; // true cuando ya se envió el código
  String _correoEnviado = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _apiClient.olvidePassword(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _correoEnviado = _emailController.text.trim();
          _codeSent = true;
        });
      }
    } catch (e) {
      // olvidePassword siempre debería responder ok, pero por si acaso:
      if (mounted) {
        setState(() {
          _correoEnviado = _emailController.text.trim();
          _codeSent = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _apiClient.restablecerPassword(
        _correoEnviado,
        _codeController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada. Ya puedes iniciar sesión.'),
            backgroundColor: Color(0xFF263020),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.lock_reset, size: 56, color: _ink),
          ),
          const SizedBox(height: 24),
          const Text(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu correo institucional y te enviaremos un código para restablecer tu contraseña.',
            style: TextStyle(fontSize: 13, color: _ink.withAlpha(160), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Correo Institucional', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              if (!v.endsWith('@unal.edu.co')) return 'Debe ser @unal.edu.co';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enviar código', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.key_outlined, size: 56, color: _ink),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nueva contraseña',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa el código enviado a $_correoEnviado y tu nueva contraseña.',
            style: TextStyle(fontSize: 13, color: _ink.withAlpha(160), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Código de 6 dígitos',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8),
            validator: (v) {
              if (v == null || v.trim().length != 6) return 'Código de 6 dígitos requerido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerida';
              if (v.length < 8) return 'Mínimo 8 caracteres';
              if (!v.contains(RegExp(r'[A-Z]'))) return 'Debe contener al menos una mayúscula';
              if (!v.contains(RegExp(r'[a-z]'))) return 'Debe contener al menos una minúscula';
              if (!v.contains(RegExp(r'[0-9]'))) return 'Debe contener al menos un número';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Restablecer contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() { _codeSent = false; _codeController.clear(); _passwordController.clear(); }),
            child: Text('Cambiar correo', style: TextStyle(color: _ink.withAlpha(160))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        title: const Text('Restablecer contraseña'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _codeSent ? _buildStep2() : _buildStep1(),
          ),
        ),
      ),
    );
  }
}
