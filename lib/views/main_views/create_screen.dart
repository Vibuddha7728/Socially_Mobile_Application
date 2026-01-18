import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // අත්‍යවශ්‍යයි
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socially_app/services/feed/feed_service.dart';
import 'package:socially_app/services/users/user_service.dart';
import 'package:socially_app/utils/util_functions/mood.dart';
import 'package:socially_app/widgets/reusable/custom_input.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  _CreateScreenState createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  File? _imageFile;
  Mood _selectedMood = Mood.happy;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitPost() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        setState(() => _isUploading = true);

        if (kIsWeb) return;
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // --- SECURITY CHECK: පෝස්ට් එක දාන්න කලින් බ්ලොක් ද බලන්න ---
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final bool isBlocked = userDoc.data()?['isBlocked'] ?? false;

          if (isBlocked) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Access Denied! Your account has been blocked by Admin.',
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
            setState(() => _isUploading = false);
            return; // මෙතනින් නවතිනවා, පෝස්ට් එක සේව් වෙන්නේ නැහැ
          }

          final userDetails = await UserService().getUserById(user.uid);
          if (!mounted) return;

          if (userDetails != null) {
            final postDetails = {
              'postCaption': _captionController.text,
              'mood': _selectedMood.name,
              'userId': user.uid,
              'username': userDetails.name,
              'profImage': userDetails.imageUrl,
              'postImage': _imageFile,
            };

            await FeedService().savePost(postDetails);

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post created successfully!')),
            );

            _captionController.clear();
            context.go('/main-screen');
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to create post')));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF121016);
    const gradientColors = [Color(0xFFBC1EAA), Color(0xFFF13D3D)];

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        primaryColor: Colors.white,
        scaffoldBackgroundColor: bgColor,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text(
            'Create Post',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableInput(
                    controller: _captionController,
                    labelText: 'Caption',
                    icon: Icons.text_fields,
                    obscureText: false,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter a caption'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildMoodDropdown(),
                  const SizedBox(height: 16),
                  _buildImagePreview(),
                  const SizedBox(height: 24),
                  _buildActionButtons(gradientColors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widgets for clean code
  Widget _buildMoodDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: const Color(0xFF2A282F)),
      child: DropdownButton<Mood>(
        value: _selectedMood,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        onChanged: (newMood) => setState(() => _selectedMood = newMood!),
        items: Mood.values
            .map(
              (mood) => DropdownMenuItem(
                value: mood,
                child: Text('${mood.name} ${mood.emoji}'),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return _imageFile != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              _imageFile!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        : const Text(
            'No image selected',
            style: TextStyle(color: Colors.white70),
          );
  }

  Widget _buildActionButtons(List<Color> colors) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _gradientBtn(
                'Camera',
                () => _pickImage(ImageSource.camera),
                colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _gradientBtn(
                'Gallery',
                () => _pickImage(ImageSource.gallery),
                colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _gradientBtn(
          _isUploading ? 'Uploading...' : 'Create Post',
          _submitPost,
          colors,
          full: true,
        ),
      ],
    );
  }

  Widget _gradientBtn(
    String text,
    VoidCallback press,
    List<Color> colors, {
    bool full = false,
  }) {
    return Container(
      width: full ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: _isUploading ? null : press,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
