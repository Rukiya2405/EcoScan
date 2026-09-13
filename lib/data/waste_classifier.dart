import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class RecyclingSuggestion {
  final String title;
  final String description;
  final List<String> steps;
  final IconType iconType;

  RecyclingSuggestion({
    required this.title,
    required this.description,
    required this.steps,
    required this.iconType,
  });
}

enum IconType {
  recycle,
  clean,
  reuse,
  creative,
  dispose,
}

class WasteClassification {
  final bool isWaste;
  final String wasteType;
  final String material;
  final bool recyclable;
  final String hazardLevel;
  final String disposalAdvice;
  final double confidence;

  final List<RecyclingSuggestion> recyclingSuggestions;

  WasteClassification({
    required this.isWaste,
    required this.wasteType,
    required this.material,
    required this.recyclable,
    required this.hazardLevel,
    required this.disposalAdvice,
    required this.confidence,
    required this.recyclingSuggestions,
  });
}

class WasteClassifier {
  static Future<WasteClassification> classify(
    Uint8List imageBytes,
  ) async {
    debugPrint('================================');
    debugPrint('ECOSCAN GEMINI AI');
    debugPrint('Image size: ${imageBytes.length} bytes');
    debugPrint('================================');

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.7-flash',
      );

      const prompt = '''
You are EcoScan, an AI-powered waste classification assistant.

Analyze the image carefully.

Your FIRST job is to determine whether the main visible object is actually waste.

Examples of waste:
- Plastic bottles
- Plastic containers
- Plastic bags
- Cans
- Glass bottles
- Glass containers
- Paper
- Cardboard
- Food waste
- Electronic waste
- Batteries
- Metal objects that are being discarded
- Other clearly discarded waste items

Examples that are NOT waste:
- People
- Animals
- Cars
- Buildings
- Trees
- Plants
- Furniture that is not clearly being discarded
- Clothing that is being worn
- Food that is being eaten or served
- Normal household objects that are not clearly waste
- Landscapes
- Screenshots
- Random objects that cannot reasonably be identified as waste

If the image does NOT contain a clear waste item, set "isWaste" to false.

If the image DOES contain a clear waste item, set "isWaste" to true.

Return ONLY valid JSON.

Use exactly this format:

{
  "isWaste": true,
  "wasteType": "Plastic bottle",
  "material": "Plastic",
  "recyclable": true,
  "hazardLevel": "Low",
  "disposalAdvice": "Empty and rinse the bottle before placing it in the recycling bin.",
  "confidence": 0.95,
  "recyclingSuggestions": [
    {
      "title": "Recycle the bottle",
      "description": "Prepare the bottle properly for recycling.",
      "steps": [
        "Empty the bottle completely.",
        "Rinse it with water.",
        "Remove any remaining contents.",
        "Place it in the appropriate recycling bin."
      ],
      "iconType": "recycle"
    },
    {
      "title": "Reuse as a planter",
      "description": "Turn the bottle into a small plant container.",
      "steps": [
        "Clean and dry the bottle.",
        "Cut the bottle carefully.",
        "Add small drainage holes.",
        "Fill it with soil and add a small plant."
      ],
      "iconType": "reuse"
    }
  ]
}

Rules:

- isWaste: must be true or false.
- wasteType: identify the main visible waste item.
- material: identify the main material.
- recyclable: must be true or false.
- hazardLevel: must be Low, Medium, High, or Unknown.
- disposalAdvice: provide short and practical disposal advice.
- confidence: number from 0.0 to 1.0.
- recyclingSuggestions: provide 2 to 4 practical suggestions.
- Each suggestion must have a short title.
- Each suggestion must have a short description.
- Each suggestion must contain 3 to 6 simple steps.
- Steps must be easy for a normal person to follow.
- Suggestions can include recycling, reuse, repurposing, donation, composting, or safe disposal when appropriate.
- iconType must be one of:
  "recycle",
  "clean",
  "reuse",
  "creative",
  "dispose".

If the image is not waste:

- isWaste must be false.
- wasteType must be "Unknown".
- material must be "Unknown".
- recyclable must be false.
- hazardLevel must be "Unknown".
- disposalAdvice must be "Please scan a waste item."
- recyclingSuggestions must be an empty array.

If the image is unclear and you cannot determine whether it is waste:

- isWaste must be false.
- recyclingSuggestions must be an empty array.
- Do not guess.

Important:

- Focus on the main object.
- Do not invent information.
- Make recycling suggestions appropriate for the detected material.
- Do not recommend unsafe activities.
- Do not tell users to cut, burn, break, or chemically modify hazardous materials.
- Return JSON only.
- Do not use Markdown.
- Do not put JSON in a code block.
''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          InlineDataPart(
            'image/jpeg',
            imageBytes,
          ),
        ]),
      ]);

      final responseText = response.text;

      debugPrint('Gemini request completed.');
      debugPrint('Gemini response: $responseText');

      if (responseText == null ||
          responseText.trim().isEmpty) {
        throw Exception(
          'Gemini returned an empty response.',
        );
      }

      final jsonText = _extractJson(responseText);

      final decoded = jsonDecode(jsonText);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Gemini response is not a JSON object.',
        );
      }

      final bool isWaste =
          decoded['isWaste'] == true;

      final String wasteType = _getString(
        decoded['wasteType'],
        'Unknown Waste',
      );

      final String material = _getString(
        decoded['material'],
        'Unknown',
      );

      final bool recyclable =
          decoded['recyclable'] == true;

      final String hazardLevel = _getString(
        decoded['hazardLevel'],
        'Unknown',
      );

      final String disposalAdvice = _getString(
        decoded['disposalAdvice'],
        'Follow your local waste disposal guidelines.',
      );

      double confidence = 0.0;

      final confidenceValue =
          decoded['confidence'];

      if (confidenceValue is num) {
        confidence =
            confidenceValue.toDouble();
      } else if (confidenceValue is String) {
        confidence =
            double.tryParse(
                  confidenceValue,
                ) ??
                0.0;
      }

      confidence =
          confidence.clamp(0.0, 1.0);

      final List<RecyclingSuggestion>
          recyclingSuggestions =
          _parseSuggestions(
        decoded['recyclingSuggestions'],
      );

      debugPrint('================================');
      debugPrint('ECOSCAN RESULT');
      debugPrint('Is Waste: $isWaste');
      debugPrint('Waste: $wasteType');
      debugPrint('Material: $material');
      debugPrint('Recyclable: $recyclable');
      debugPrint('Hazard: $hazardLevel');
      debugPrint(
        'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
      );
      debugPrint(
        'Suggestions: ${recyclingSuggestions.length}',
      );
      debugPrint('================================');

      return WasteClassification(
        isWaste: isWaste,
        wasteType: wasteType,
        material: material,
        recyclable: recyclable,
        hazardLevel: hazardLevel,
        disposalAdvice: disposalAdvice,
        confidence: confidence,
        recyclingSuggestions:
            recyclingSuggestions,
      );
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('GEMINI AI ERROR');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('================================');

      throw Exception(
        'Gemini could not analyze the image: $e',
      );
    }
  }

  // ============================================================
  // PARSE RECYCLING SUGGESTIONS
  // ============================================================

  static List<RecyclingSuggestion>
      _parseSuggestions(dynamic value) {
    if (value is! List) {
      return [];
    }

    final List<RecyclingSuggestion> suggestions = [];

    for (final item in value) {
      if (item is! Map) {
        continue;
      }

      final String title = _getString(
        item['title'],
        'Recycling Idea',
      );

      final String description = _getString(
        item['description'],
        'A practical way to reuse or recycle this item.',
      );

      final List<String> steps = [];

      final dynamic stepsValue =
          item['steps'];

      if (stepsValue is List) {
        for (final step in stepsValue) {
          final String stepText =
              step.toString().trim();

          if (stepText.isNotEmpty) {
            steps.add(stepText);
          }
        }
      }

      if (steps.isEmpty) {
        steps.add(
          'Follow your local recycling guidelines for this item.',
        );
      }

      final IconType iconType =
          _parseIconType(
        item['iconType'],
      );

      suggestions.add(
        RecyclingSuggestion(
          title: title,
          description: description,
          steps: steps,
          iconType: iconType,
        ),
      );
    }

    return suggestions;
  }

  // ============================================================
  // ICON TYPE
  // ============================================================

  static IconType _parseIconType(
    dynamic value,
  ) {
    final String type =
        value?.toString().toLowerCase().trim() ??
            '';

    switch (type) {
      case 'clean':
        return IconType.clean;

      case 'reuse':
        return IconType.reuse;

      case 'creative':
        return IconType.creative;

      case 'dispose':
        return IconType.dispose;

      case 'recycle':
      default:
        return IconType.recycle;
    }
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  static String _getString(
    dynamic value,
    String fallback,
  ) {
    if (value == null) {
      return fallback;
    }

    final String result =
        value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }

  // ============================================================
  // JSON EXTRACTION
  // ============================================================

  static String _extractJson(
    String text,
  ) {
    String cleaned = text.trim();

    if (cleaned.startsWith('```json')) {
      cleaned =
          cleaned.substring(7).trim();
    } else if (cleaned.startsWith('```')) {
      cleaned =
          cleaned.substring(3).trim();
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned
          .substring(
            0,
            cleaned.length - 3,
          )
          .trim();
    }

    final int start =
        cleaned.indexOf('{');

    final int end =
        cleaned.lastIndexOf('}');

    if (start != -1 &&
        end != -1 &&
        end > start) {
      cleaned = cleaned.substring(
        start,
        end + 1,
      );
    }

    return cleaned.trim();
  }
}
