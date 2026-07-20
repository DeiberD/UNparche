import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_api_client.dart';
import '../../state/auth_state.dart';
import '../../main.dart';

/// Pantalla de verificación de correo.
/// Se muestra después de un registro exitoso o cuando el login detecta
/// que el correo aún no ha sido verificado.
class VerifyEmailScreen extends StatefulWidget {
  final String correoInstitucional;

  const VerifyEmailScreen({super.key, required this.correoInstitucional});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _ink = Color(0xFF263020);
  static const _background = Color(0xFFFBF5F2);
  static const _surface = Color(0xFFF3ECE8);

  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiClient = AuthApiClient();

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await _apiClient.verificarCorreo(
        widget.correoInstitucional,
        _codeController.text.trim(),
      );
      final token = result['token'] as String;
      final userData = result['usuario'];
      if (mounted) {
        final notifier = AuthProvider.of(context);
        await notifier.loginWithToken(token, userData);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
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

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      await _apiClient.reenviarCodigo(widget.correoInstitucional);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código reenviado. Revisa tu correo.')),
        );
        _startResendCooldown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        title: const Text('Verificar correo'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined, size: 56, color: _ink),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Revisa tu correo',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enviamos un código de 6 dígitos a\n${widget.correoInstitucional}',
                  style: TextStyle(fontSize: 14, color: _ink.withAlpha(160), height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de verificación',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8),
                  validator: (v) {
                    if (v == null || v.trim().length != 6) return 'Ingresa el código de 6 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verificar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: (_resendCooldown > 0 || _isResending) ? null : _resendCode,
                  child: _isResending
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          _resendCooldown > 0
                              ? 'Reenviar código en ${_resendCooldown}s'
                              : 'Reenviar código',
                          style: TextStyle(
                            color: _resendCooldown > 0 ? _ink.withAlpha(100) : _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
