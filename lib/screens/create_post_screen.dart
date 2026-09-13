import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState
    extends State<CreatePostScreen> {
  static const Color primaryGreen =
      Color(0xFF2E7D32);

  final TextEditingController _contentController =
      TextEditingController();

  String _selectedTag = 'General';
  bool _isLoading = false;

  // ============================================================
  // IMAGE VARIABLES
  // ============================================================
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _tags = [
    'General',
    'Recycling',
    'Scan',
    'Achievement',
    'Tip',
  ];

  Color _tagColor(String tag) {
    switch (tag) {
      case 'Recycling':
        return Colors.blue.shade600;
      case 'Scan':
        return Colors.orange.shade600;
      case 'Achievement':
        return Colors.purple.shade600;
      case 'Tip':
        return Colors.teal.shade600;
      default:
        return primaryGreen;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // ============================================================
  // PICK IMAGE - SHOWS BOTTOM SHEET TO CHOOSE CAMERA OR GALLERY
  // ============================================================

  Future<void> _pickImage() async {
    // SHOW BOTTOM SHEET FOR IMAGE SOURCE SELECTION
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HANDLE BAR
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // CAMERA OPTION
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: primaryGreen,
                  ),
                ),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Use your camera'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.camera);
                },
              ),

              const SizedBox(height: 8),

              // GALLERY OPTION
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: primaryGreen,
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Pick from your photos'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.gallery);
                },
              ),

              const SizedBox(height: 8),

              // REMOVE PHOTO OPTION - ONLY SHOW IF IMAGE IS SELECTED
              if (_selectedImage != null) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  subtitle: const Text('Remove selected image'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GET IMAGE FROM SOURCE
  // ============================================================

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,       // COMPRESS TO SAVE STORAGE SPACE
        maxWidth: 1080,         // LIMIT SIZE TO SAVE STORAGE SPACE
        maxHeight: 1080,
      );

      if (image == null) return;  // USER CANCELLED

      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (e) {
      debugPrint('Image pick error: $e');
      _showMessage('Could not pick image. Please try again.');
    }
  }

  // ============================================================
  // UPLOAD IMAGE TO FIREBASE STORAGE
  // ============================================================

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final String uid =
          FirebaseAuth.instance.currentUser!.uid;

      // CREATE UNIQUE FILE NAME USING TIMESTAMP
      final String fileName =
          'posts/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // UPLOAD TO FIREBASE STORAGE
      final Reference storageRef =
          FirebaseStorage.instance.ref().child(fileName);

      final UploadTask uploadTask =
          storageRef.putFile(imageFile);

      final TaskSnapshot snapshot =
          await uploadTask;

      // GET DOWNLOAD URL
      final String downloadUrl =
          await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  // ============================================================
  // SUBMIT POST
  // ============================================================

  Future<void> _submitPost() async {
    final String content =
        _contentController.text.trim();

    // REQUIRE EITHER TEXT OR IMAGE
    if (content.isEmpty && _selectedImage == null) {
      _showMessage('Please write something or add a photo.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final User user =
          FirebaseAuth.instance.currentUser!;

      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final String name =
          (userDoc.data() as Map<String, dynamic>?)?['name'] ??
          user.displayName ??
          'User';

      // UPLOAD IMAGE IF ONE WAS SELECTED
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);

        // IF UPLOAD FAILED SHOW ERROR AND STOP
        if (imageUrl == null) {
          _showMessage('Failed to upload image. Please try again.');
          return;
        }
      }

      // SAVE POST TO FIRESTORE WITH IMAGE URL IF EXISTS
await FirebaseFirestore.instance
    .collection('posts')
    .add({
  'authorId': user.uid,
  'authorName': name,
  'content': content,
  'tag': _selectedTag,
  'likes': [],
  'likeCount': 0,
  'commentCount': 0,
  'createdAt': FieldValue.serverTimestamp(),
  // ONLY SAVE imageUrl IF IMAGE WAS UPLOADED
  'imageUrl': imageUrl,   // <-- UPDATED, uses null-aware '?'
});

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Create post error: $e');

      if (!mounted) return;

      _showMessage('Failed to post. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),

      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isLoading ? null : _submitPost,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // USER INFO
            // ====================================================
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text(
                    (FirebaseAuth.instance.currentUser?.displayName ?? 'U')[0]
                        .toUpperCase(),
                    style: const TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Text(
                      'Sharing with everyone',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ====================================================
            // CONTENT INPUT
            // ====================================================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText:
                      'Share what you did today...\n\n'
                      'e.g. I just scanned and recycled\n'
                      '5 plastic bottles! 🌱',
                  hintStyle: TextStyle(color: Colors.grey, height: 1.6),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ====================================================
            // ADD PHOTO BUTTON
            // ====================================================
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.4),
                    width: 1.5,
                    // DASHED BORDER EFFECT USING STYLE
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),

                // ================================================
                // SHOW PREVIEW IF IMAGE SELECTED
                // ================================================
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          // IMAGE PREVIEW
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // CHANGE PHOTO BUTTON ON TOP RIGHT
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _pickImage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Change',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )

                    // ================================================
                    // SHOW ADD PHOTO PLACEHOLDER IF NO IMAGE
                    // ================================================
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryGreen.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: primaryGreen,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Add a Photo',
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to take a photo or choose from gallery',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // ====================================================
            // TAG SELECTOR
            // ====================================================
            const Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final bool selected = _selectedTag == tag;
                final Color color = _tagColor(tag);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTag = tag;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? color
                          : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color, width: 1.5),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: selected ? Colors.white : color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ====================================================
            // TIPS BOX
            // ====================================================
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: primaryGreen,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Share your eco-wins, recycling tips,\n'
                      'or scan achievements with the community!',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryGreen,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}