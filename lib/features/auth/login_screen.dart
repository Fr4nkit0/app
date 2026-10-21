import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/auth/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberCredentials = false;
  bool _credentialsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    _emailController.addListener(_onCredentialsEdited);
    _passwordController.addListener(_onCredentialsEdited);
  }

  Future<void> _loadRememberedCredentials() async {
    final saved = await ref
        .read(authControllerProvider.notifier)
        .loadRememberedCredentials();
    if (!mounted) return;
    setState(() {
      _rememberCredentials = saved.remember;
      if (saved.email != null) {
        _emailController.text = saved.email!;
      }
      if (saved.password != null) {
        _passwordController.text = saved.password!;
      }
      _credentialsLoaded = true;
    });
  }

  void _onCredentialsEdited() {
    ref.read(authControllerProvider.notifier).clearLoginError();
  }

  @override
  void dispose() {
    _emailController.removeListener(_onCredentialsEdited);
    _passwordController.removeListener(_onCredentialsEdited);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .login(
          _emailController.text.trim(),
          _passwordController.text,
          rememberCredentials: _rememberCredentials,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final tokens = MarilinTokens.of(context);
    final theme = Theme.of(context);

    if (!_credentialsLoaded) {
      return Scaffold(
        backgroundColor: tokens.scaffoldMuted,
        body: Center(child: CircularProgressIndicator(color: tokens.brandBlue)),
      );
    }

    return Scaffold(
      backgroundColor: tokens.scaffoldMuted,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Iniciar sesión',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: tokens.brandNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresá con tu cuenta de reparto',
                      style: tokens.subtitle,
                    ),
                    const SizedBox(height: 28),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: authState.error != null
                          ? _LoginErrorBanner(
                              key: ValueKey(authState.error),
                              message: authState.error!,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('login_no_error'),
                            ),
                    ),
                    if (authState.error != null) const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Ingresá tu correo';
                        }
                        if (!trimmed.contains('@')) {
                          return 'El correo no parece válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onLogin(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresá tu contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _rememberCredentials,
                      onChanged: authState.isLoading
                          ? null
                          : (value) {
                              setState(
                                () => _rememberCredentials = value ?? false,
                              );
                            },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'Recordarme',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens.brandNavy,
                        ),
                      ),
                      subtitle: Text(
                        'Solo se guarda tu correo en este dispositivo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _onLogin,
                        child: authState.isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Ingresar'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Podés seguir trabajando sin conexión; los datos se guardan en el dispositivo.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = MarilinTokens.of(context);

    return Semantics(
      liveRegion: true,
      container: true,
      label: 'Error al iniciar sesión: $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.destructive.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.destructive.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 22,
              color: tokens.destructive,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No pudimos iniciar sesión',
                    style: TextStyle(
                      color: tokens.destructive,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: tokens.brandNavy.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
