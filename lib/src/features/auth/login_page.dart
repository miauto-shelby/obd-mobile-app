import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onGoogleLogin});

  final Future<void> Function() onGoogleLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('LoginPage: before onGoogleLogin');
      await widget.onGoogleLogin();
      debugPrint('LoginPage: onGoogleLogin completed');
    } catch (error) {
      debugPrint('LoginPage: onGoogleLogin error -> $error');
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 420;
    final logoSize = isCompact ? 102.0 : 112.0;
    final circleSize = logoSize + 22;
    final fieldWidth = isCompact ? double.infinity : 320.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _LogoBadge(
                            size: circleSize,
                            innerSize: logoSize,
                            borderColor: const Color(0xFFD80000),
                            borderWidth: 5,
                            assetPath: 'assets/images/brand_logo.png',
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'MY AUTO',
                            style: TextStyle(
                              color: const Color(0xFF8A8A8A),
                              fontSize: isCompact ? 9.5 : 10,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Correo',
                            style: TextStyle(
                              color: const Color(0xFF8C8C8C),
                              fontSize: isCompact ? 22 : 24,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(
                                color: Color(0xFF1C1C1E),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor: const Color(0xFFD80000),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8F8F8),
                                hintText: 'Escribe tu correo aquí',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9A9A9A),
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF9D9D9D),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.3,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD80000),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: isCompact ? 230 : 240,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _submit,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF202124),
                                side: const BorderSide(
                                  color: Color(0xFFDADCE0),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                  ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Color(0xFF202124),
                                      ),
                                    )
                                  : Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF4285F4),
                                            Color(0xFFEA4335),
                                            Color(0xFFFBBC05),
                                            Color(0xFF34A853),
                                          ],
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'G',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                              label: _isLoading
                                  ? const Text('Iniciando...')
                                  : const Text('Continuar con Google'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: isCompact ? 230 : 240,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : () {},
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1D1D1F),
                                side: const BorderSide(
                                  color: Color(0xFFDADCE0),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              icon: const Icon(
                                Icons.apple,
                                size: 20,
                                color: Color(0xFF1D1D1F),
                              ),
                              label: const Text('Continuar con Apple'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: isCompact ? 230 : 240,
                            height: 44,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Registro por correo disponible en una siguiente etapa.',
                                          ),
                                        ),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFD80000),
                                textStyle: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Registrar con correo'),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 18),
                            _InlineMessage(message: _errorMessage!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({
    required this.size,
    required this.innerSize,
    required this.borderColor,
    required this.borderWidth,
    required this.assetPath,
  });

  final double size;
  final double innerSize;
  final Color borderColor;
  final double borderWidth;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Center(
          child: SizedBox(
            width: innerSize,
            height: innerSize,
            child: ClipOval(
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD80000).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD80000).withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF8B0000),
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
