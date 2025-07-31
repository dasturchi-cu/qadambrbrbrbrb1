import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/auth_service.dart';

class NewSupportScreen extends StatefulWidget {
  const NewSupportScreen({Key? key}) : super(key: key);

  @override
  State<NewSupportScreen> createState() => _NewSupportScreenState();
}

class _NewSupportScreenState extends State<NewSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'texnik_muammo';
  String _selectedPriority = 'past';
  bool _isLoading = false;
  List<File> _attachedImages = [];

  final List<Map<String, String>> _categories = [
    {'value': 'texnik_muammo', 'label': 'Texnik muammo'},
    {'value': 'hisob_muammosi', 'label': 'Hisob muammosi'},
    {'value': 'yangi_funksiya', 'label': 'Yangi funksiya so\'rovi'},
    {'value': 'to\'lov_muammosi', 'label': 'To\'lov muammosi'},
    {'value': 'boshqa', 'label': 'Boshqa'},
  ];

  final List<Map<String, String>> _priorities = [
    {'value': 'past', 'label': 'Past'},
    {'value': 'o\'rta', 'label': 'O\'rta'},
    {'value': 'yuqori', 'label': 'Yuqori'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rasm tanlash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galereya'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rasm hajmi 5MB dan kichik bo\'lishi kerak'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (_attachedImages.length >= 3) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maksimal 3 ta rasm qo\'shish mumkin'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        setState(() {
          _attachedImages.add(file);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rasm tanlashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<AuthService>(context, listen: false).user;
      if (user == null) throw Exception('Foydalanuvchi aniqlanmadi');

      List<String> imageUrls = [];

      // Rasmlarni Firebase Storage ga yuklash
      for (File image in _attachedImages) {
        final ref = FirebaseStorage.instance.ref().child('support_images').child(
            '${DateTime.now().millisecondsSinceEpoch}_${_attachedImages.indexOf(image)}.jpg');

        await ref.putFile(image);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Support ticket yaratish
      final ticketRef =
          await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? 'Noma\'lum',
        'subject': _subjectController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'status': 'yangi',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'imageUrls': imageUrls,
      });

      // Birinchi xabarni qo'shish
      await FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(ticketRef.id)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Noma\'lum',
        'senderType': 'user',
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrls': imageUrls,
        'isRead': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Murojaat muvaffaqiyatli yuborildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi murojaat'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Mavzu'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: 'Muammo haqida qisqacha yozing',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.subject),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mavzu kiritish majburiy';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Kategoriya'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category['value'],
                    child: Text(category['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Muhimlik darajasi'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.priority_high),
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority['value'],
                    child: Text(priority['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Xabar'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Muammoni batafsil tasvirlab bering...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Xabar kiritish majburiy';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Rasmlar (ixtiyoriy)'),
              const SizedBox(height: 8),
              _buildImageSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Murojaat yuborish',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        if (_attachedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _attachedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _attachedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _attachedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _attachedImages.length < 3 ? _pickImage : null,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text('Rasm qo\'shish (${_attachedImages.length}/3)'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }
}
