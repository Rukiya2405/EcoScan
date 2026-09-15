import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

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
  // ============================================================
  // GEMINI MODEL
  // ============================================================

  static const String _modelName = 'gemini-2.0-flash-exp';

  // ============================================================
  // IMAGE PREPROCESSING
  // ============================================================

  static Future<Uint8List> _preprocessImage(
    Uint8List imageBytes,
  ) async {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('IMAGE PREPROCESSING');
    debugPrint('========================================');
    debugPrint('Original size: ${imageBytes.length} bytes');

    try {
      // Decode the image
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        debugPrint('Failed to decode image, using original');
        return imageBytes;
      }

      debugPrint('Original dimensions: ${image.width}x${image.height}');

      // Fix orientation based on EXIF data
      // This is critical for photos taken with real phone cameras
      image = img.bakeOrientation(image);
      debugPrint('Applied EXIF orientation correction');

      // Resize if too large (max dimension 1536px)
      const int maxDimension = 1536;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          image = img.copyResize(
            image,
            width: maxDimension,
          );
        } else {
          image = img.copyResize(
            image,
            height: maxDimension,
          );
        }
        debugPrint('Resized to: ${image.width}x${image.height}');
      }

      // Encode as JPEG with good quality
      final processedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: 85),
      );

      debugPrint('Processed size: ${processedBytes.length} bytes');
      debugPrint('Size reduction: ${((1 - processedBytes.length / imageBytes.length) * 100).toStringAsFixed(1)}%');
      debugPrint('========================================');

      return processedBytes;
    } catch (e, stackTrace) {
      debugPrint('Image preprocessing error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Using original image');
      debugPrint('========================================');
      return imageBytes;
    }
  }

  // ============================================================
  // MAIN CLASSIFICATION
  // ============================================================

  static Future<WasteClassification> classify(
    Uint8List imageBytes,
  ) async {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('ECOSCAN AI SCAN');
    debugPrint('========================================');
    debugPrint('Input image size: ${imageBytes.length} bytes');
    debugPrint('Model: $_modelName');

    try {
      // Preprocess the image to fix orientation and size issues
      final processedImage = await _preprocessImage(imageBytes);

      const prompt = '''
You are EcoScan, an AI-powered waste classification assistant.

Analyze the image carefully and identify ALL types of waste materials.

Your first job is to determine whether the main visible object is actually waste.

Examples of waste (you can identify ALL of these):

- Plastic bottles, containers, bags, wrappers, cups, straws
- Aluminum cans, tin cans, metal containers
- Glass bottles, jars, broken glass
- Paper (newspapers, magazines, office paper, notebooks)
- Cardboard boxes, packaging
- Food waste (fruit peels, vegetable scraps, leftovers, eggshells)
- Electronic waste (old phones, computers, cables, batteries)
- Batteries (alkaline, lithium, rechargeable)
- Styrofoam containers and packaging
- Tetra packs (juice boxes, milk cartons)
- Fabric and textile waste
- Wood scraps
- Rubber items
- Mixed materials
- Other clearly discarded waste items

Examples that are NOT waste:

- People, animals, cars, buildings
- Trees, plants, landscapes
- Furniture or objects that are not clearly being discarded
- Clothing that is being worn
- Food that is being served or eaten fresh
- Normal household objects in use
- Screenshots, text documents

If the image does NOT contain a clear waste item:

isWaste must be false.

If the image DOES contain a clear waste item:

isWaste must be true.

Return ONLY valid JSON.

Use exactly this structure:

{
  "isWaste": true,
  "wasteType": "Plastic bottle",
  "material": "Plastic (PET)",
  "recyclable": true,
  "hazardLevel": "Low",
  "disposalAdvice": "Empty and rinse the bottle before placing it in the recycling bin for plastics.",
  "confidence": 0.95,
  "recyclingSuggestions": [
    {
      "title": "Recycle properly",
      "description": "Prepare the item for recycling.",
      "steps": [
        "Empty the container completely",
        "Rinse with water to remove residue",
        "Place in the appropriate recycling bin"
      ],
      "iconType": "recycle"
    },
    {
      "title": "Creative reuse",
      "description": "Give the item a second life.",
      "steps": [
        "Clean and dry the item thoroughly",
        "Use as a storage container or planter",
        "Get creative with DIY projects"
      ],
      "iconType": "creative"
    }
  ]
}

Rules:

- isWaste must be true or false
- wasteType must identify the specific waste item (be specific: "Plastic water bottle", "Aluminum soda can", "Banana peel", etc.)
- material must identify the main material (Plastic, Metal, Glass, Paper, Cardboard, Organic, Electronic, etc.)
- recyclable must be true or false
- hazardLevel must be Low, Medium, High, or Unknown
- disposalAdvice must be short, practical, and location-appropriate
- confidence must be between 0.0 and 1.0
- Provide exactly 2 recyclingSuggestions when the item is waste
- Each suggestion must have 3 simple, safe steps
- iconType must be one of: recycle, clean, reuse, creative, dispose

If the image is NOT waste:

{
  "isWaste": false,
  "wasteType": "Unknown",
  "material": "Unknown",
  "recyclable": false,
  "hazardLevel": "Unknown",
  "disposalAdvice": "Please scan a waste item.",
  "confidence": 0.0,
  "recyclingSuggestions": []
}

Important:

- You CAN identify all types of waste, not just plastic bottles
- Be confident in your classification
- Focus on the main object in the image
- Do not invent information
- Do not recommend unsafe activities
- Return JSON only, no Markdown, no code blocks
''';

      debugPrint('');
      debugPrint('Sending image to Gemini...');
      debugPrint('');

      final model = FirebaseAI.googleAI().generativeModel(
        model: _modelName,
      );

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          InlineDataPart(
            'image/jpeg',
            processedImage,
          ),
        ]),
      ]);

      debugPrint('Gemini response received.');

      return _parseResponse(response);
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('ECOSCAN GEMINI ERROR');
      debugPrint('========================================');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('');
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('========================================');

      throw Exception(
        _friendlyErrorMessage(e),
      );
    }
  }

  // ============================================================
  // FRIENDLY ERROR MESSAGE
  // ============================================================

  static String _friendlyErrorMessage(
    Object error,
  ) {
    final String message = error.toString().toLowerCase();

    // ----------------------------------------------------------
    // QUOTA
    // ----------------------------------------------------------

    if (message.contains('quota') ||
        message.contains('resource_exhausted') ||
        message.contains('rate limit') ||
        message.contains('429') ||
        message.contains('free_tier')) {
      return 'The AI scan limit has been reached. '
          'Please wait for the Gemini quota to reset '
          'or check your Gemini API billing and limits.';
    }

    // ----------------------------------------------------------
    // APP CHECK
    // ----------------------------------------------------------

    if (message.contains('app attestation failed') ||
        message.contains('firebase_app_check') ||
        message.contains('403')) {
      return 'Firebase App Check rejected this request. '
          'Please check your App Check configuration.';
    }

    // ----------------------------------------------------------
    // PERMISSION
    // ----------------------------------------------------------

    if (message.contains('permission denied') ||
        message.contains('unauthenticated') ||
        message.contains('unauthorized')) {
      return 'Gemini access was denied. '
          'Please check your Firebase AI configuration.';
    }

    // ----------------------------------------------------------
    // NETWORK
    // ----------------------------------------------------------

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return 'Network connection failed. '
          'Please check your internet connection and try again.';
    }

    // ----------------------------------------------------------
    // EMPTY RESPONSE
    // ----------------------------------------------------------

    if (message.contains('empty response')) {
      return 'Gemini returned an empty response. '
          'Please try scanning again.';
    }

    // ----------------------------------------------------------
    // JSON
    // ----------------------------------------------------------

    if (message.contains('json')) {
      return 'EcoScan received an invalid AI response. '
          'Please try scanning again.';
    }

    // ----------------------------------------------------------
    // DEFAULT
    // ----------------------------------------------------------

    return 'Gemini could not analyze the image. '
        'Please try again.';
  }

  // ============================================================
  // PARSE GEMINI RESPONSE
  // ============================================================

  static WasteClassification _parseResponse(
    GenerateContentResponse response,
  ) {
    final String? responseText = response.text;

    debugPrint('');
    debugPrint('========================================');
    debugPrint('GEMINI RESPONSE');
    debugPrint('========================================');
    debugPrint(responseText ?? '(empty)');
    debugPrint('========================================');

    if (responseText == null || responseText.trim().isEmpty) {
      throw Exception(
        'Gemini returned an empty response.',
      );
    }

    final String jsonText = _extractJson(responseText);

    final dynamic decoded = jsonDecode(jsonText);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Gemini response is not a JSON object.',
      );
    }

    final bool isWaste = decoded['isWaste'] == true;

    final String wasteType = _getString(
      decoded['wasteType'],
      'Unknown',
    );

    final String material = _getString(
      decoded['material'],
      'Unknown',
    );

    final bool recyclable = decoded['recyclable'] == true;

    final String hazardLevel = _getString(
      decoded['hazardLevel'],
      'Unknown',
    );

    final String disposalAdvice = _getString(
      decoded['disposalAdvice'],
      'Please follow your local waste disposal guidelines.',
    );

    double confidence = 0.0;

    final dynamic confidenceValue = decoded['confidence'];

    if (confidenceValue is num) {
      confidence = confidenceValue.toDouble();
    } else if (confidenceValue is String) {
      confidence = double.tryParse(confidenceValue) ?? 0.0;
    }

    confidence = confidence.clamp(0.0, 1.0);

    final List<RecyclingSuggestion> recyclingSuggestions =
        _parseSuggestions(
      decoded['recyclingSuggestions'],
    );

    debugPrint('');
    debugPrint('========================================');
    debugPrint('ECOSCAN RESULT');
    debugPrint('========================================');
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
    debugPrint('========================================');

    return WasteClassification(
      isWaste: isWaste,
      wasteType: wasteType,
      material: material,
      recyclable: recyclable,
      hazardLevel: hazardLevel,
      disposalAdvice: disposalAdvice,
      confidence: confidence,
      recyclingSuggestions: recyclingSuggestions,
    );
  }

  // ============================================================
  // PARSE SUGGESTIONS
  // ============================================================

  static List<RecyclingSuggestion> _parseSuggestions(dynamic value) {
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

      final dynamic stepsValue = item['steps'];

      if (stepsValue is List) {
        for (final step in stepsValue) {
          final String stepText = step.toString().trim();

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

      final IconType iconType = _parseIconType(
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
    final String type = value?.toString().toLowerCase().trim() ?? '';

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

    final String result = value.toString().trim();

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
      cleaned = cleaned.substring(7).trim();
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3).trim();
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(
        0,
        cleaned.length - 3,
      ).trim();
    }

    final int start = cleaned.indexOf('{');

    final int end = cleaned.lastIndexOf('}');

    if (start != -1 && end != -1 && end > start) {
      cleaned = cleaned.substring(
        start,
        end + 1,
      );
    }

    return cleaned.trim();
  }
}