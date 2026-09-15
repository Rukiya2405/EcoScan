import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../data/scan_history_service.dart';
import '../data/waste_classifier.dart';
import 'result_screen.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFEAF6EC);
  static const Color background = Color(0xFFF5F8F5);

  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  bool _isAnalyzing = false;

  // ===============================================================
  // IMAGE PICKING
  // ===============================================================

  Future<void> _pickImage(ImageSource source) async {
    try {
      debugPrint('================================');
      debugPrint('OPENING IMAGE SOURCE: $source');
      debugPrint('================================');

      final XFile? image = await _picker.pickImage(
        source: source,

        // Use higher resolution for real device cameras
        // This ensures we capture enough detail
        maxWidth: 2048,
        maxHeight: 2048,

        // Higher quality to preserve details
        // The classifier will optimize it further
        imageQuality: 90,

        // Use rear camera for better quality
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) {
        debugPrint('No image selected by user.');
        return;
      }

      debugPrint('================================');
      debugPrint('IMAGE SELECTED');
      debugPrint('================================');
      debugPrint('Path: ${image.path}');
      debugPrint('Name: ${image.name}');
      debugPrint('MIME type: ${image.mimeType ?? 'unknown'}');

      final Uint8List bytes = await image.readAsBytes();

      debugPrint('Size: ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(1)} KB)');
      debugPrint('================================');

      if (bytes.isEmpty) {
        throw Exception('The selected image is empty.');
      }

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
      });

      debugPrint('Image successfully loaded into Flutter state.');

      // Show success feedback
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Image loaded successfully! (${(bytes.length / 1024).toStringAsFixed(0)} KB)',
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('IMAGE PICKING FAILED');
      debugPrint('================================');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('');
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('================================');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Failed to load image',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$e',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _takePhoto() {
    debugPrint('User tapped: Take Photo');
    _pickImage(ImageSource.camera);
  }

  void _chooseFromGallery() {
    debugPrint('User tapped: Choose from Gallery');
    _pickImage(ImageSource.gallery);
  }

  // ===============================================================
  // ANALYZE WASTE
  // ===============================================================

  Future<void> _analyzeWaste() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Please take or select a photo first.'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    if (_isAnalyzing) {
      debugPrint('Analysis already in progress, ignoring tap.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      debugPrint('');
      debugPrint('================================================');
      debugPrint('STARTING WASTE ANALYSIS');
      debugPrint('================================================');
      debugPrint('Input image size: ${_imageBytes!.length} bytes');
      debugPrint('Input image size: ${(_imageBytes!.length / 1024).toStringAsFixed(1)} KB');
      debugPrint('================================================');

      final WasteClassification classification =
          await WasteClassifier.classify(_imageBytes!);

      debugPrint('');
      debugPrint('================================================');
      debugPrint('CLASSIFICATION COMPLETE');
      debugPrint('================================================');
      debugPrint('Is waste: ${classification.isWaste}');
      debugPrint('Type: ${classification.wasteType}');
      debugPrint('Material: ${classification.material}');
      debugPrint('Recyclable: ${classification.recyclable}');
      debugPrint('Confidence: ${(classification.confidence * 100).toStringAsFixed(1)}%');
      debugPrint('================================================');

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });

      if (!classification.isWaste) {
        debugPrint('Not waste detected, showing dialog.');
        _showNotWasteDialog();
        return;
      }

      // Save scan history
      try {
        await ScanHistoryService.saveScan(classification);
        debugPrint('Scan saved to Firestore successfully.');
      } catch (e, stackTrace) {
        debugPrint('Could not save scan history: $e');
        debugPrint('History save stack trace: $stackTrace');
        // Don't block the user flow if history save fails
      }

      if (!mounted) return;

      debugPrint('Navigating to ResultScreen...');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageBytes: _imageBytes!,
            classification: classification,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('================================================');
      debugPrint('AI ANALYSIS FAILED');
      debugPrint('================================================');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('');
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('================================================');

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'AI Analysis Failed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$e',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _analyzeWaste,
          ),
        ),
      );
    }
  }

  // ===============================================================
  // NOT WASTE DIALOG
  // ===============================================================

  void _showNotWasteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          contentPadding: const EdgeInsets.fromLTRB(24, 5, 24, 10),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.image_search_outlined,
                  color: primaryGreen,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No Waste Detected',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'This image does not appear to contain a clear waste item.\n\n'
            'Please scan an item that is being discarded, such as:\n'
            '• Plastic bottles or containers\n'
            '• Aluminum or tin cans\n'
            '• Glass bottles or jars\n'
            '• Paper or cardboard\n'
            '• Food waste\n'
            '• Electronic waste',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.black54,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntro(),
                    const SizedBox(height: 22),
                    _buildImagePreview(),
                    const SizedBox(height: 18),
                    _buildImageActions(),
                    const SizedBox(height: 18),
                    if (_isAnalyzing) ...[
                      _buildAnalyzingCard(),
                      const SizedBox(height: 18),
                    ],
                    _buildAnalyzeButton(),
                    const SizedBox(height: 20),
                    _buildScanGuide(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ===============================================================
  // HEADER
  // ===============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: primaryGreen,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ecoscan',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Scan Waste',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: primaryGreen,
                  size: 15,
                ),
                SizedBox(width: 5),
                Text(
                  'AI',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // INTRO
  // ===============================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEAF6EC),
            Color(0xFFF4FAF4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.recycling,
              color: primaryGreen,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identify Your Waste',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Take a clear photo of any waste item and let EcoScan AI identify it for you.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // IMAGE PREVIEW
  // ===============================================================

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 285,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: _imageBytes == null
              ? Colors.transparent
              : primaryGreen.withValues(alpha: 0.20),
          width: 1.5,
        ),
      ),
      child: _imageBytes == null
          ? _buildEmptyImageState()
          : _buildSelectedImage(),
    );
  }

  Widget _buildEmptyImageState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.add_a_photo_outlined,
            color: primaryGreen,
            size: 34,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'No image selected',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Take a photo or choose one from your gallery',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Image.memory(
            _imageBytes!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: _isAnalyzing
                ? null
                : () {
                    setState(() {
                      _imageBytes = null;
                    });
                    debugPrint('Image cleared by user.');
                  },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.60),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(
                  'Image ready',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // IMAGE ACTIONS
  // ===============================================================

  Widget _buildImageActions() {
    return Row(
      children: [
        Expanded(
          child: _imageActionButton(
            icon: Icons.camera_alt_outlined,
            title: 'Camera',
            subtitle: 'Take photo',
            color: primaryGreen,
            onTap: _isAnalyzing ? null : _takePhoto,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _imageActionButton(
            icon: Icons.photo_library_outlined,
            title: 'Gallery',
            subtitle: 'Choose photo',
            color: const Color(0xFF1976D2),
            onTap: _isAnalyzing ? null : _chooseFromGallery,
          ),
        ),
      ],
    );
  }

  Widget _imageActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 86,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // ANALYZING CARD
  // ===============================================================

  Widget _buildAnalyzingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: primaryGreen,
              backgroundColor: lightGreen,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EcoScan AI is analyzing...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Identifying the material and disposal method.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_awesome,
            color: Color(0xFFFFA000),
            size: 23,
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // ANALYZE BUTTON
  // ===============================================================

  Widget _buildAnalyzeButton() {
    final bool hasImage = _imageBytes != null;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _analyzeWaste,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasImage ? primaryGreen : Colors.grey.shade300,
          foregroundColor:
              hasImage ? Colors.white : Colors.grey.shade600,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.65),
          disabledForegroundColor: Colors.white,
          elevation: hasImage ? 4 : 0,
          shadowColor: primaryGreen.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isAnalyzing)
              const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                hasImage ? Icons.auto_awesome : Icons.image_search_outlined,
                size: 22,
              ),
            const SizedBox(width: 9),
            Text(
              _isAnalyzing ? 'Analyzing...' : 'Analyze Waste',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // SCAN GUIDE
  // ===============================================================

  Widget _buildScanGuide() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.tips_and_updates_outlined,
              color: Color(0xFFF9A825),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For better results',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Use good lighting and make sure the waste item is clearly visible in the photo. Works with plastics, metals, glass, paper, food waste, and more!',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // BOTTOM NAVIGATION
  // ===============================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                  );
                },
              ),
              _bottomNavItem(
                icon: Icons.camera_alt_outlined,
                label: 'Scan',
                selected: true,
                onTap: () {},
              ),
              _bottomNavItem(
                icon: Icons.people_outline_rounded,
                label: 'Community',
                selected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CommunityScreen(),
                    ),
                  );
                },
              ),
              _bottomNavItem(
                icon: Icons.history,
                label: 'History',
                selected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistoryScreen(),
                    ),
                  );
                },
              ),
              _bottomNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                selected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // BOTTOM NAV ITEM
  // ===============================================================

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? primaryGreen.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 23,
                color: selected ? primaryGreen : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? primaryGreen : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}