import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
// Bu import qo'shildi
import 'package:qadam_app/app/services/coin_service.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    setState(() {
      _isLoading = false;
      _isEditing = false;
      _error = success ? null : authService.errorMessage;
    });
    if (success && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profil yangilandi!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    final coinService =
        Provider.of<CoinService>(context); // achievementService o'chirildi

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing
                ? _saveProfile
                : () => setState(() => _isEditing = true),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Foydalanuvchi maʼlumotlari topilmadi.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? const Icon(Icons.person,
                                  size: 45, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(labelText: 'Ism'),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Ism kiriting' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Email kiriting' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          enabled: _isEditing,
                          decoration:
                              const InputDecoration(labelText: 'Telefon raqam'),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        _isEditing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _saveProfile,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Text('Saqlash'),
                                  ),
                                  const SizedBox(width: 16),
                                  OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _isEditing = false;
                                              _nameController.text =
                                                  user.displayName ?? '';
                                              _emailController.text =
                                                  user.email ?? '';
                                              _phoneController.text = '';
                                            });
                                          },
                                    child: const Text('Bekor qilish'),
                                  ),
                                ],
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                                child: const Text('Tahrirlash'),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Yutuqlar',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontSize:
                                    18)), // displayMedium o'rniga headlineSmall
                  ),
                  const SizedBox(height: 12),
                  Consumer<CoinService>(
                    builder: (context, coinService, _) {
                      if (coinService.achievements.isEmpty) {
                        return const Text('Hali yutuqlar yo\'q');
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: coinService.achievements.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final ach = coinService.achievements[index];
                          return ListTile(
                            leading: const Icon(Icons.emoji_events,
                                color: Colors.amber),
                            title: Text(
                                ach['challengeTitle'] ?? 'Noma\'lum yutuq'),
                            subtitle: Text(
                                'Mukofot: +${ach['reward'] ?? 0} tanga\n${DateFormat('yyyy-MM-dd').format(DateTime.parse(ach['date'] ?? DateTime.now().toIso8601String()))}'),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, Map<String, dynamic> ach) {
    IconData icon;
    Color color;
    switch (ach['type']) {
      case 'steps':
        icon = Icons.directions_walk;
        color = Colors.green;
        break;
      case 'challenge':
        icon = Icons.flag;
        color = Colors.deepPurple;
        break;
      case 'streak':
        icon = Icons.whatshot;
        color = Colors.orange;
        break;
      default:
        icon = Icons.emoji_events;
        color = Colors.amber;
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              radius: 28,
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(ach['title'] ?? 'Noma\'lum',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(ach['description'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
                ach['date'] != null
                    ? DateFormat('dd.MM.yyyy')
                        .format(DateTime.parse(ach['date']))
                    : '',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
