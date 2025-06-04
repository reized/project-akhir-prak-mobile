import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.register(
        _usernameController.text.trim(),
        _passwordController.text,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        AppTheme.showSuccessSnackBar(context, result.message);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        AppTheme.showErrorSnackBar(context, result.message);
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showErrorSnackBar(context, 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: AppTheme.getGradientBackground(isDark),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Title
                    Icon(
                      Icons.movie_outlined,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'Daftar Akun',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Buat akun baru untuk melanjutkan',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXXL),

                    // Username Field
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM),
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: AppTheme.getInputDecoration(
                            labelText: 'Username',
                            hintText: 'Masukkan username',
                            prefixIcon: Icons.person_outline,
                            isDark: isDark,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Username tidak boleh kosong';
                            }
                            if (value.trim().length < 3) {
                              return 'Username minimal 3 karakter';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Email Field
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM),
                        child: TextFormField(
                          controller: _emailController,
                          decoration: AppTheme.getInputDecoration(
                            labelText: 'Email (Opsional)',
                            hintText: 'Masukkan email',
                            prefixIcon: Icons.email_outlined,
                            isDark: isDark,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value.trim())) {
                                return 'Format email tidak valid';
                              }
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Password Field
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: AppTheme.getInputDecoration(
                            labelText: 'Password',
                            hintText: 'Masukkan password',
                            prefixIcon: Icons.lock_outline,
                            isDark: isDark,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password tidak boleh kosong';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Confirm Password Field
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: AppTheme.getInputDecoration(
                            labelText: 'Konfirmasi Password',
                            hintText: 'Masukkan ulang password',
                            prefixIcon: Icons.lock_outline,
                            isDark: isDark,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi password tidak boleh kosong';
                            }
                            if (value != _passwordController.text) {
                              return 'Password tidak cocok';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXL),

                    // Register Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: AppTheme.primaryButtonStyle,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Daftar'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Login Link
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: 'Sudah punya akun? '),
                            TextSpan(
                              text: 'Masuk di sini',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
