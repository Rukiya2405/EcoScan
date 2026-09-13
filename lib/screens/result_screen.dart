import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/waste_classifier.dart';
import 'home_screen.dart';
import 'scan_screen.dart';

class ResultScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final WasteClassification classification;

  const ResultScreen({
    super.key,
    required this.imageBytes,
    required this.classification,
  });

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFEAF6EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text(
          'Waste Analysis',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageCard(),

              const SizedBox(height: 20),

              _buildWasteTypeCard(),

              const SizedBox(height: 12),

              _buildMaterialCard(),

              const SizedBox(height: 12),

              _buildStatusCards(),

              const SizedBox(height: 20),

              _buildConfidenceCard(),

              const SizedBox(height: 20),

              _buildDisposalAdviceCard(),

              const SizedBox(height: 24),

              // ==================================================
              // RECYCLING / REUSE CARDS
              // ==================================================

              _buildRecyclingSuggestionsSection(),

              const SizedBox(height: 28),

              _buildActionButtons(context),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE CARD
  // ============================================================

  Widget _buildImageCard() {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 60,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // WASTE TYPE CARD
  // ============================================================

  Widget _buildWasteTypeCard() {
    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.recycling,
                color: primaryGreen,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Waste Identified',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            classification.wasteType,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MATERIAL CARD
  // ============================================================

  Widget _buildMaterialCard() {
    return _buildWhiteCard(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.category_outlined,
              color: primaryGreen,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              'Main Material',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Flexible(
            child: Text(
              classification.material,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECYCLABLE + HAZARD
  // ============================================================

  Widget _buildStatusCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            title: 'Recyclable',
            value: classification.recyclable ? 'Yes' : 'No',
            icon: classification.recyclable
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            color: classification.recyclable
                ? primaryGreen
                : Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            title: 'Hazard',
            value: classification.hazardLevel,
            icon: Icons.warning_amber_rounded,
            color: _hazardColor(
              classification.hazardLevel,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 27,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AI CONFIDENCE
  // ============================================================

  Widget _buildConfidenceCard() {
    final double percentage =
        classification.confidence * 100;

    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_outlined,
                color: Colors.blue,
                size: 27,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI Confidence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: classification.confidence,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSAL ADVICE
  // ============================================================

  Widget _buildDisposalAdviceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.eco_outlined,
                color: primaryGreen,
                size: 27,
              ),
              SizedBox(width: 10),
              Text(
                'Disposal Advice',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            classification.disposalAdvice,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECYCLING SUGGESTIONS SECTION
  // ============================================================

  Widget _buildRecyclingSuggestionsSection() {
    final suggestions =
        classification.recyclingSuggestions;

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --------------------------------------------------------
        // SECTION HEADER
        // --------------------------------------------------------

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE8F5E9),
                Color(0xFFF8FCF8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryGreen.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFF9A825),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Give It a Second Life',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'EcoScan AI found some practical ways you can recycle, reuse, or repurpose this item.',
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
        ),

        const SizedBox(height: 16),

        // --------------------------------------------------------
        // VISUAL CARDS
        // --------------------------------------------------------

        ...List.generate(
          suggestions.length,
          (index) {
            final RecyclingSuggestion suggestion =
                suggestions[index];

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 16,
              ),
              child: _buildVisualSuggestionCard(
                suggestion,
                index,
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // VISUAL RECYCLING CARD
  // ============================================================

  Widget _buildVisualSuggestionCard(
    RecyclingSuggestion suggestion,
    int index,
  ) {
    final IconData icon = _suggestionIcon(index);

    final Color accentColor =
        _suggestionColor(index);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: accentColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // CARD TOP
          // ------------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Visual icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(
                          alpha: 0.12,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 31,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Idea number
                      Text(
                        'IDEA ${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: accentColor,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        suggestion.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        suggestion.description,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // STEP-BY-STEP
          // ------------------------------------------------------

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.format_list_numbered,
                        color: accentColor,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 10),

                    const Text(
                      'How to do it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // STEPS
                // ------------------------------------------------

                ...List.generate(
                  suggestion.steps.length,
                  (stepIndex) {
                    final bool isLast =
                        stepIndex ==
                            suggestion.steps.length - 1;

                    return Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Step number + connecting line
                        SizedBox(
                          width: 34,
                          child: Column(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${stepIndex + 1}',
                                    style:
                                        const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 35,
                                  margin:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical: 3,
                                  ),
                                  color: accentColor
                                      .withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Step text
                        Expanded(
                          child: Container(
                            margin:
                                const EdgeInsets.only(
                              bottom: 12,
                            ),
                            padding:
                                const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF8FAF8,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: Text(
                              suggestion.steps[
                                  stepIndex],
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color:
                                    Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 4),

                // ------------------------------------------------
                // TIP
                // ------------------------------------------------

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.tips_and_updates_outlined,
                        color: Color(0xFFF9A825),
                        size: 21,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Tip: Follow local recycling rules if they differ from these general instructions.',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUGGESTION ICON
  //
  // We deliberately use the card position instead of IconType.
  // This avoids the errors you were getting.
  // ============================================================

  IconData _suggestionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.recycling;

      case 1:
        return Icons.cleaning_services_outlined;

      case 2:
        return Icons.home_outlined;

      case 3:
        return Icons.auto_awesome_outlined;

      default:
        return Icons.eco_outlined;
    }
  }

  // ============================================================
  // SUGGESTION COLOR
  // ============================================================

  Color _suggestionColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF2E7D32);

      case 1:
        return const Color(0xFF1976D2);

      case 2:
        return const Color(0xFF8E24AA);

      case 3:
        return const Color(0xFFEF6C00);

      default:
        return const Color(0xFF2E7D32);
    }
  }

  // ============================================================
  // WHITE CARD
  // ============================================================

  Widget _buildWhiteCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(
    BuildContext context,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      const ScanScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.camera_alt_outlined,
            ),
            label: const Text(
              'Scan Another Waste',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context)
                  .pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      const HomeScreen(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(
              Icons.check_circle_outline,
            ),
            label: const Text(
              'Done',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryGreen,
              side: const BorderSide(
                color: primaryGreen,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Finished reviewing your analysis?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HAZARD COLOR
  // ============================================================

  Color _hazardColor(
    String hazardLevel,
  ) {
    final String level =
        hazardLevel.toLowerCase();

    if (level.contains('high') ||
        level.contains('danger') ||
        level.contains('hazardous')) {
      return Colors.red;
    }

    if (level.contains('medium') ||
        level.contains('moderate')) {
      return Colors.orange;
    }

    if (level.contains('low') ||
        level.contains('safe')) {
      return primaryGreen;
    }

    return Colors.grey;
  }
}
