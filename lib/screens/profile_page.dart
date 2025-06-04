import 'package:flutter/material.dart';
import 'bookmark_list_page.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _authService.logout();
                if (mounted && Navigator.of(this.context).canPop()) {
                  Navigator.pushAndRemoveUntil(
                    this.context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                } else if (mounted) {
                  Navigator.pushReplacement(this.context,
                      MaterialPageRoute(builder: (_) => const LoginPage()));
                }
              },
              style: AppTheme.dangerButtonStyle,
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoadingDialog = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (buildContext, setStateDialog) {
          return AlertDialog(
            title: const Text('Hapus Akun'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Apakah Anda yakin ingin menghapus akun ini secara permanen? Tindakan ini tidak dapat diurungkan.'),
                  const SizedBox(height: AppTheme.spacingM),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Masukkan Password Anda',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoadingDialog ? null : () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isLoadingDialog
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setStateDialog(() => isLoadingDialog = true);
                          final result =
                              await _authService.deleteCurrentUserAccount(
                                  passwordController.text);

                          Navigator.pop(dialogContext);

                          if (mounted) {
                            if (result.success) {
                              AppTheme.showSuccessSnackBar(
                                  this.context, result.message);
                              Navigator.pushAndRemoveUntil(
                                this.context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                                (route) => false,
                              );
                            } else {
                              AppTheme.showErrorSnackBar(
                                  this.context, result.message);
                            }
                          }
                        }
                      },
                style: AppTheme.dangerButtonStyle,
                child: isLoadingDialog
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Hapus Akun'),
              ),
            ],
          );
        });
      },
    );
  }

  void _navigateToEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = _authService.currentUser;

    return Scaffold(
      body: Container(
        decoration: AppTheme.getGradientBackground(isDark),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  decoration: AppTheme.getCardDecoration(
                      isDark: isDark, borderRadius: AppTheme.radiusXL),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          user?.username.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        user?.username ?? 'Unknown User',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      if (user?.email != null && user!.email!.isNotEmpty)
                        Text(
                          user.email!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      const SizedBox(height: AppTheme.spacingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusCircular),
                        ),
                        child: Text(
                          'Bergabung ${_formatDate(user?.createdAt ?? DateTime.now())}',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingL),
                const Divider(),
                const SizedBox(height: AppTheme.spacingS),

                // Menu Options
                Expanded(
                  child: ListView(
                    children: [
                      _buildMenuOption(
                        context,
                        icon: Icons.bookmark_outline,
                        title: 'Bookmark Anime',
                        subtitle: 'Lihat daftar anime favorit Anda',
                        color: Colors.orange,
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BookmarkListPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildMenuOption(
                        context,
                        icon: Icons.person_outline,
                        title: 'Personal Data',
                        subtitle: 'Edit data personal Anda',
                        color: AppTheme.infoColor,
                        isDark: isDark,
                        onTap: _navigateToEditProfile,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildMenuOption(
                        context,
                        icon: Icons.delete_outline,
                        title: 'Hapus Akun',
                        subtitle: 'Hapus akun Anda secara permanen',
                        color: AppTheme.errorColor,
                        isDark: isDark,
                        onTap: () => _showDeleteAccountDialog(context),
                      ),
                    ],
                  ),
                ),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('LOGOUT'),
                    style: AppTheme.dangerButtonStyle.copyWith(
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusCircular),
                        ),
                      ),
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

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS + 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.spacingS + 2),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXS / 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
