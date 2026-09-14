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
  // ============================================================
  // GEMINI MODELS
  // ============================================================

  static const String _primaryModel = 'gemini-3.7-flash';

  // Free-tier compatible fallback when using Gemini Developer API.
  static const String _fallbackModel = 'gemini-3.5-flash-lite';

  // Number of attempts for each model.
  static const int _maxAttempts = 3;

  // ============================================================
  // MAIN CLASSIFICATION
  // ============================================================

  static Future<WasteClassification> classify(
    Uint8List imageBytes,
  ) async {
    debugPrint('================================');
    debugPrint('ECOSCAN GEMINI AI');
    debugPrint('Image size: ${imageBytes.length} bytes');
    debugPrint('================================');

    try {
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
        "Place it in the appropriate recycling bin."
      ],
      "iconType": "recycle"
    },
    {
      "title": "Reuse as a planter",
      "description": "Turn the bottle into a small plant container.",
      "steps": [
        "Clean and dry the bottle.",
        "Prepare it safely as a container.",
        "Add soil and a small plant."
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
- recyclingSuggestions: provide exactly 2 practical suggestions when the item is waste.
- Each suggestion must have a short title.
- Each suggestion must have a short description.
- Each suggestion must contain 3 simple steps.
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

      // ============================================================
      // TRY PRIMARY MODEL
      // ============================================================

      try {
        debugPrint(
          'Trying primary model: $_primaryModel',
        );

        final response = await _generateWithRetry(
          modelName: _primaryModel,
          prompt: prompt,
          imageBytes: imageBytes,
        );

        return _parseResponse(response);
      } catch (primaryError) {
        debugPrint('================================');
        debugPrint('PRIMARY MODEL FAILED');
        debugPrint('Model: $_primaryModel');
        debugPrint('Error: $primaryError');
        debugPrint('================================');

        // Only use the fallback for temporary/server/rate-limit
        // errors. Don't hide permanent errors such as malformed
        // requests or invalid configuration.
        if (!_isRetryableError(primaryError)) {
          rethrow;
        }
      }

      // ============================================================
      // FALLBACK MODEL
      // ============================================================

      debugPrint('================================');
      debugPrint('USING FALLBACK GEMINI MODEL');
      debugPrint('Model: $_fallbackModel');
      debugPrint('================================');

      final fallbackResponse = await _generateWithRetry(
        modelName: _fallbackModel,
        prompt: prompt,
        imageBytes: imageBytes,
      );

      return _parseResponse(fallbackResponse);
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('GEMINI AI ERROR');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('================================');

      throw Exception(
        _friendlyErrorMessage(e),
      );
    }
  }

  // ============================================================
  // GENERATE CONTENT WITH RETRY
  // ============================================================

  static Future<GenerateContentResponse> _generateWithRetry({
    required String modelName,
    required String prompt,
    required Uint8List imageBytes,
  }) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: modelName,
    );

    Object? lastError;

    for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        debugPrint(
          'Gemini request: $modelName '
          'attempt $attempt/$_maxAttempts',
        );

        final response = await model.generateContent([
          Content.multi([
            TextPart(prompt),
            InlineDataPart(
              'image/jpeg',
              imageBytes,
            ),
          ]),
        ]);

        debugPrint(
          'Gemini request successful '
          'using $modelName',
        );

        return response;
      } catch (e) {
        lastError = e;

        debugPrint(
          'Gemini request failed '
          '($modelName, attempt $attempt): $e',
        );

        // Don't retry permanent errors.
        if (!_isRetryableError(e)) {
          rethrow;
        }

        // If this was the final attempt, stop.
        if (attempt == _maxAttempts) {
          break;
        }

        // Exponential backoff:
        //
        // Attempt 1 → wait 2 seconds
        // Attempt 2 → wait 4 seconds
        //
        // This gives temporary Gemini server overload
        // a chance to recover.
        final int delaySeconds = attempt * 2;

        debugPrint(
          'Temporary Gemini error. '
          'Retrying in $delaySeconds seconds...',
        );

        await Future.delayed(
          Duration(seconds: delaySeconds),
        );
      }
    }

    throw Exception(
      lastError?.toString() ??
          'Gemini request failed.',
    );
  }

  // ============================================================
  // DETECT TEMPORARY GEMINI ERRORS
  // ============================================================

  static bool _isRetryableError(Object error) {
    final String message =
        error.toString().toLowerCase();

    // HTTP 500 / internal server errors.
    if (message.contains('500')) {
      return true;
    }

    if (message.contains('internal')) {
      return true;
    }

    // Gemini server temporarily overloaded.
    if (message.contains('high demand')) {
      return true;
    }

    if (message.contains('temporarily')) {
      return true;
    }

    if (message.contains('try again later')) {
      return true;
    }

    // Rate limiting.
    if (message.contains('429')) {
      return true;
    }

    if (message.contains('resource_exhausted')) {
      return true;
    }

    if (message.contains('rate limit')) {
      return true;
    }

    if (message.contains('quota')) {
      return true;
    }

    return false;
  }

  // ============================================================
  // PARSE GEMINI RESPONSE
  // ============================================================

  static WasteClassification _parseResponse(
    GenerateContentResponse response,
  ) {
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
  }

  // ============================================================
  // FRIENDLY ERROR MESSAGE
  // ============================================================

  static String _friendlyErrorMessage(
    Object error,
  ) {
    final String message =
        error.toString().toLowerCase();

    if (message.contains('high demand') ||
        message.contains('500') ||
        message.contains('internal')) {
      return 'Gemini is temporarily busy. '
          'Please try scanning again in a moment.';
    }

    if (message.contains('429') ||
        message.contains('quota') ||
        message.contains('rate limit') ||
        message.contains('resource_exhausted')) {
      return 'The AI scan limit has been reached temporarily. '
          'Please try again later.';
    }

    if (message.contains('empty response')) {
      return 'Gemini returned an empty response. '
          'Please try scanning again.';
    }

    if (message.contains('json')) {
      return 'EcoScan received an invalid AI response. '
          'Please try scanning again.';
    }

    return 'Gemini could not analyze the image. '
        'Please try again.';
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
