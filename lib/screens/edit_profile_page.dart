// screens/edit_profile_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late TextEditingController _emailController;
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  String _username = '';

  @override
  void initState() {
    super.initState();
    final currentUser = _authService.currentUser;
    _username = currentUser?.username ?? 'N/A';
    _emailController = TextEditingController(text: currentUser?.email ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    String? newEmail = _emailController.text.trim();
    if (newEmail == _authService.currentUser?.email) {
      newEmail = null; // Tidak ada perubahan email
    }

    String? currentPassword = _currentPasswordController.text;
    String? newPassword = _newPasswordController.text;

    if (newPassword.isEmpty) {
      // Jika tidak ingin mengubah password
      newPassword = null;
      currentPassword = null;
    }

    final result = await _authService.updateUserDetails(
      newEmail: newEmail,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (mounted) {
      if (result.success) {
        AppTheme.showSuccessSnackBar(context, result.message);
        // Perbarui tampilan jika diperlukan, atau kembali ke halaman profil
        // AuthService sudah mengupdate _currentUser internalnya
        setState(() {
          // Jika ada perubahan email, controller akan diperbarui
          _emailController.text = _authService.currentUser?.email ?? '';
        });
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      } else {
        AppTheme.showErrorSnackBar(context, result.message);
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
      ),
      body: Container(
        decoration: AppTheme.getGradientBackground(isDark),
        child: SafeArea(
          child: Column(
            children: [
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Container(
                    decoration: AppTheme.getCardDecoration(
                      isDark: isDark,
                      borderRadius: AppTheme.radiusXL,
                    ),
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Username Section
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Username',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingXS),
                                Text(
                                  _username,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingXS),
                                Text(
                                  '(Username tidak dapat diubah)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.spacingXL),

                          // Email Section
                          _buildSectionTitle('Ubah Email'),
                          const SizedBox(height: AppTheme.spacingM),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurfaceColor
                                  : AppTheme.lightSurfaceColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              decoration: AppTheme.getInputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icons.email_outlined,
                                isDark: isDark,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value.trim())) {
                                    return 'Format email tidak valid';
                                  }
                                }
                                return null; // Email boleh kosong jika user tidak mau mengisinya
                              },
                            ),
                          ),

                          const SizedBox(height: AppTheme.spacingXL),

                          // Password Section
                          _buildSectionTitle('Ubah Password (Opsional)'),
                          const SizedBox(height: AppTheme.spacingM),

                          // Current Password
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurfaceColor
                                  : AppTheme.lightSurfaceColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            margin: const EdgeInsets.only(
                                bottom: AppTheme.spacingM),
                            child: TextFormField(
                              controller: _currentPasswordController,
                              obscureText: _obscureCurrentPassword,
                              decoration: AppTheme.getInputDecoration(
                                labelText: 'Password Saat Ini',
                                hintText:
                                    'Kosongkan jika tidak ingin mengubah password',
                                prefixIcon: Icons.lock_outline,
                                isDark: isDark,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureCurrentPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() =>
                                      _obscureCurrentPassword =
                                          !_obscureCurrentPassword),
                                ),
                              ),
                              validator: (value) {
                                // Validasi hanya jika field password baru diisi
                                if (_newPasswordController.text.isNotEmpty &&
                                    (value == null || value.isEmpty)) {
                                  return 'Password saat ini diperlukan untuk mengatur password baru';
                                }
                                return null;
                              },
                            ),
                          ),

                          // New Password
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurfaceColor
                                  : AppTheme.lightSurfaceColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            margin: const EdgeInsets.only(
                                bottom: AppTheme.spacingM),
                            child: TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscureNewPassword,
                              decoration: AppTheme.getInputDecoration(
                                labelText: 'Password Baru',
                                hintText:
                                    'Kosongkan jika tidak ingin mengubah password',
                                prefixIcon: Icons.lock_open_outlined,
                                isDark: isDark,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureNewPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() =>
                                      _obscureNewPassword =
                                          !_obscureNewPassword),
                                ),
                              ),
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length < 6) {
                                  return 'Password baru minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Confirm New Password
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurfaceColor
                                  : AppTheme.lightSurfaceColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: TextFormField(
                              controller: _confirmNewPasswordController,
                              obscureText: _obscureConfirmNewPassword,
                              decoration: AppTheme.getInputDecoration(
                                labelText: 'Konfirmasi Password Baru',
                                hintText:
                                    'Kosongkan jika tidak ingin mengubah password',
                                prefixIcon: Icons.lock_open_outlined,
                                isDark: isDark,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmNewPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() =>
                                      _obscureConfirmNewPassword =
                                          !_obscureConfirmNewPassword),
                                ),
                              ),
                              validator: (value) {
                                if (_newPasswordController.text.isNotEmpty &&
                                    value != _newPasswordController.text) {
                                  return 'Password baru tidak cocok';
                                }
                                if (_newPasswordController.text.isNotEmpty &&
                                    (value == null || value.isEmpty)) {
                                  return 'Konfirmasi password baru diperlukan';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: AppTheme.spacingXXL),

                          // Save Button
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveChanges,
                            style: AppTheme.primaryButtonStyle.copyWith(
                              minimumSize: const MaterialStatePropertyAll(
                                  Size(double.infinity, 60)),
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save_outlined),
                            label: Text(_isLoading
                                ? 'Menyimpan...'
                                : 'Simpan Perubahan'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
    );
  }
}
