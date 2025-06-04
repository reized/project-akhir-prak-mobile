// screens/profile_page.dart
import 'package:flutter/material.dart';
import 'bookmark_list_page.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';

// 1. Ubah menjadi StatefulWidget
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 2. Buat State class
  final AuthService _authService = AuthService(); // Simpan instance AuthService

  // Metode _showLogoutDialog dan _showDeleteAccountDialog bisa tetap di sini
  // atau dipindahkan ke dalam _ProfilePageState jika mereka memodifikasi state lokal.
  // Untuk saat ini, kita anggap mereka tidak memodifikasi state lokal ProfilePage
  // selain navigasi atau menampilkan dialog.

  void _showLogoutDialog(BuildContext context) {
    // ... (implementasi _showLogoutDialog tetap sama)
    // Gunakan widget.key jika diperlukan, atau context yang di-pass
    showDialog(
      context: context, // context dari build method atau parameter
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _authService.logout(); // Gunakan instance _authService
                // Gunakan context dari widget, bukan parameter yg mungkin sudah tidak valid
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    // ... (implementasi _showDeleteAccountDialog tetap sama)
    // Gunakan widget.key jika diperlukan, atau context yang di-pass
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoadingDialog = false;

    showDialog(
      context: context, // context dari build method atau parameter
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (buildContext, setStateDialog) {
          // Ganti nama context di sini agar tidak bentrok
          return AlertDialog(
            title: const Text('Hapus Akun'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Apakah Anda yakin ingin menghapus akun ini secara permanen? Tindakan ini tidak dapat diurungkan.'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Masukkan Password Anda',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          // final authService = AuthService(); // Sudah ada _authService
                          final result =
                              await _authService.deleteCurrentUserAccount(
                                  passwordController.text);

                          Navigator.pop(dialogContext);

                          if (mounted) {
                            // Cek mounted sebelum menggunakan context utama
                            if (result.success) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                // Gunakan this.context
                                SnackBar(
                                    content: Text(result.message),
                                    backgroundColor: Colors.green),
                              );
                              Navigator.pushAndRemoveUntil(
                                this.context, // Gunakan this.context
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                                (route) => false,
                              );
                            } else {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                // Gunakan this.context
                                SnackBar(
                                    content: Text(result.message),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
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

  // 3. Fungsi untuk navigasi ke EditProfilePage dan memicu refresh saat kembali
  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );

    // Setelah kembali dari EditProfilePage, panggil setState untuk refresh.
    // Kita tidak perlu 'result' di sini, hanya perlu tahu bahwa kita kembali.
    if (mounted) {
      // Pastikan widget masih ada di tree
      setState(() {
        // State di sini akan mengambil _authService.currentUser yang terbaru
        // dan build method akan menggunakan nilai baru tersebut.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // final authService = AuthService(); // Gunakan instance _authService dari state
    final user =
        _authService.currentUser; // Data pengguna diambil dari _authService

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [Colors.grey[900]!, Colors.black]
                : [Colors.deepPurple[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header (menggunakan 'user' dari state)
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          user?.username.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.username ?? 'Unknown User',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      if (user?.email != null && user!.email!.isNotEmpty)
                        Text(
                          user.email!, // Ini akan menampilkan email terbaru setelah setState
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Bergabung ${_formatDate(user?.createdAt ?? DateTime.now())}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BookmarkListPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuOption(
                        context,
                        icon: Icons.person_outline,
                        title: 'Personal Data',
                        subtitle: 'Edit data personal Anda',
                        color: Colors.blue,
                        onTap:
                            _navigateToEditProfile, // 4. Gunakan fungsi navigasi baru
                      ),
                      const SizedBox(height: 12),
                      _buildMenuOption(
                        context,
                        icon: Icons.delete_outline,
                        title: 'Hapus Akun',
                        subtitle: 'Hapus akun Anda secara permanen',
                        color: Colors.red.shade700,
                        onTap: () => _showDeleteAccountDialog(
                            context), // Pass context dari build method
                      ),
                    ],
                  ),
                ),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(
                        context), // Pass context dari build method
                    icon: const Icon(Icons.logout),
                    label: const Text('LOGOUT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
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
