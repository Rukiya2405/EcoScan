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

  // Try Flash-Lite first.
  // This is the model we are testing now.
  static const String _primaryModel =
      'gemini-3.5-flash-lite';

  // Other models are used as fallbacks.
  static const List<String> _fallbackModels = [
    'gemini-3.8-flash',
    'gemini-3.7-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
  ];

  // Number of times a temporary server error is retried
  // for the same model.
  static const int _maxTemporaryRetries = 2;

  // ============================================================
  // MAIN CLASSIFICATION
  // ============================================================

  static Future<WasteClassification> classify(
    Uint8List imageBytes,
  ) async {
    debugPrint('');
    debugPrint('================================================');
    debugPrint('STARTING WASTE ANALYSIS');
    debugPrint('================================================');
    debugPrint(
      'Input image size: ${imageBytes.length} bytes',
    );
    debugPrint(
      'Input image size: '
      '${(imageBytes.length / 1024).toStringAsFixed(1)} KB',
    );
    debugPrint('================================================');

    if (imageBytes.isEmpty) {
      throw Exception(
        'The image is empty.',
      );
    }

    try {
      final String prompt = _buildPrompt();

      final List<String> models = [
        _primaryModel,
        ..._fallbackModels,
      ];

      Object? lastError;

      for (final String modelName in models) {
        int temporaryRetryCount = 0;

        while (temporaryRetryCount <=
            _maxTemporaryRetries) {
          try {
            debugPrint('');
            debugPrint('========================================');
            debugPrint('TRYING GEMINI MODEL');
            debugPrint('========================================');
            debugPrint(
              'Model: $modelName',
            );
            debugPrint(
              'Attempt: ${temporaryRetryCount + 1}',
            );
            debugPrint(
              'Image bytes: ${imageBytes.length}',
            );
            debugPrint('========================================');

            final model =
                FirebaseAI.googleAI().generativeModel(
              model: modelName,
            );

            debugPrint('');
            debugPrint(
              'Creating Gemini model: $modelName',
            );

            debugPrint(
              'Sending image to Gemini...',
            );

            final response =
                await model.generateContent([
              Content.multi([
                TextPart(prompt),
                InlineDataPart(
                  'image/jpeg',
                  imageBytes,
                ),
              ]),
            ]);

            debugPrint('');
            debugPrint('========================================');
            debugPrint('GEMINI RESPONSE RECEIVED');
            debugPrint('========================================');
            debugPrint(
              'Model: $modelName',
            );
            debugPrint('========================================');

            return _parseResponse(response);
          } catch (e, stackTrace) {
            lastError = e;

            debugPrint('');
            debugPrint('========================================');
            debugPrint('GEMINI MODEL FAILED');
            debugPrint('========================================');
            debugPrint(
              'Model: $modelName',
            );
            debugPrint(
              'Attempt: ${temporaryRetryCount + 1}',
            );
            debugPrint(
              'Error type: ${e.runtimeType}',
            );
            debugPrint(
              'Error: $e',
            );
            debugPrint('');
            debugPrint('Stack trace:');
            debugPrint(
              stackTrace.toString(),
            );
            debugPrint('========================================');

            final String message =
                e.toString().toLowerCase();

            // ----------------------------------------------------
            // APP CHECK
            // ----------------------------------------------------

            if (message.contains(
                  'app attestation failed',
                ) ||
                message.contains(
                  'firebase_app_check',
                ) ||
                message.contains('403')) {
              throw Exception(
                _friendlyErrorMessage(e),
              );
            }

            // ----------------------------------------------------
            // PERMISSION
            // ----------------------------------------------------

            if (message.contains(
                  'permission denied',
                ) ||
                message.contains(
                  'unauthenticated',
                ) ||
                message.contains(
                  'unauthorized',
                )) {
              throw Exception(
                _friendlyErrorMessage(e),
              );
            }

            // ----------------------------------------------------
            // NETWORK
            // ----------------------------------------------------

            if (message.contains('network') ||
                message.contains('socket') ||
                message.contains('connection') ||
                message.contains('timeout')) {
              throw Exception(
                _friendlyErrorMessage(e),
              );
            }

            // ----------------------------------------------------
            // QUOTA / RATE LIMIT
            // ----------------------------------------------------

            final bool quotaError =
                message.contains('quota') ||
                message.contains(
                  'resource_exhausted',
                ) ||
                message.contains('rate limit') ||
                message.contains('429') ||
                message.contains('free_tier');

            if (quotaError) {
              debugPrint('');
              debugPrint(
                'Gemini quota/rate limit detected.',
              );
              debugPrint(
                'Trying the next model...',
              );

              break;
            }

            // ----------------------------------------------------
            // MODEL UNAVAILABLE
            // ----------------------------------------------------

            final bool modelUnavailable =
                message.contains('not found') ||
                message.contains('not supported') ||
                message.contains(
                  'unsupported model',
                );

            if (modelUnavailable) {
              debugPrint('');
              debugPrint(
                'Gemini model is unavailable.',
              );
              debugPrint(
                'Model: $modelName',
              );
              debugPrint(
                'Trying the next model...',
              );

              break;
            }

            // ----------------------------------------------------
            // TEMPORARY SERVER ERROR
            // ----------------------------------------------------

            final bool temporaryServerError =
                message.contains('server error') ||
                message.contains('high demand') ||
                message.contains(
                  'status: internal',
                ) ||
                message.contains(
                  'statuscode=500',
                ) ||
                message.contains(
                  '"code": 500',
                ) ||
                message.contains(
                  'code":500',
                );

            if (temporaryServerError) {
              temporaryRetryCount++;

              if (temporaryRetryCount <=
                  _maxTemporaryRetries) {
                final int delaySeconds =
                    temporaryRetryCount == 1
                        ? 2
                        : 4;

                debugPrint('');
                debugPrint(
                  'Temporary Gemini server problem.',
                );
                debugPrint(
                  'Retrying $modelName '
                  'in $delaySeconds seconds...',
                );

                await Future.delayed(
                  Duration(
                    seconds: delaySeconds,
                  ),
                );

                continue;
              }

              debugPrint('');
              debugPrint(
                'Retries exhausted for $modelName.',
              );
              debugPrint(
                'Trying the next model...',
              );

              break;
            }

            // ----------------------------------------------------
            // UNKNOWN ERROR
            // ----------------------------------------------------

            throw Exception(
              _friendlyErrorMessage(e),
            );
          }
        }
      }

      debugPrint('');
      debugPrint('========================================');
      debugPrint('ALL GEMINI MODELS FAILED');
      debugPrint('========================================');
      debugPrint(
        'Last error: $lastError',
      );
      debugPrint('========================================');

      throw Exception(
        'Gemini is temporarily unavailable. '
        'Please try scanning again in a few seconds.',
      );
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('ECOSCAN GEMINI ERROR');
      debugPrint('========================================');
      debugPrint(
        'Error type: ${e.runtimeType}',
      );
      debugPrint(
        'Error: $e',
      );
      debugPrint('');
      debugPrint('Stack trace:');
      debugPrint(
        stackTrace.toString(),
      );
      debugPrint('========================================');

      if (e is Exception &&
          e.toString().startsWith(
            'Exception: ',
          )) {
        rethrow;
      }

      throw Exception(
        _friendlyErrorMessage(e),
      );
    }
  }

  // ============================================================
  // AI PROMPT
  // ============================================================

  static String _buildPrompt() {
    return '''
You are EcoScan, an AI-powered waste classification assistant.

Your task is to carefully analyze the supplied image and identify
the MAIN visible object.

The application is designed to classify common household and
environmental waste.

============================================================
IMPORTANT CLASSIFICATION RULE
============================================================

Determine whether the main visible object is actually waste.

An object should be considered waste when it appears to be:
- discarded
- used and thrown away
- damaged and being discarded
- packaging after use
- a disposable item
- an unwanted material
- clearly intended for disposal

Do NOT require the image to literally show a trash bin.

For example:
- A plastic bottle on a table can still be classified as a
  plastic bottle if it appears to be a used/disposable bottle.
- A crushed can can be classified as a metal can.
- A cardboard box can be classified as cardboard if it is clearly
  an unwanted/discarded box.
- A battery can be classified as electronic/hazardous waste.
- A food container can be classified as waste if it appears to
  be used packaging.

============================================================
SUPPORTED WASTE TYPES
============================================================

You can identify many different types of waste.

Examples include:

PLASTIC:
- Plastic bottle
- Plastic container
- Plastic bag
- Plastic packaging
- Plastic cup
- Plastic wrapper
- Plastic food container
- Other plastic waste

PAPER:
- Paper
- Newspaper
- Magazine
- Paper packaging
- Paper wrapper
- Other paper waste

CARDBOARD:
- Cardboard box
- Corrugated cardboard
- Cardboard packaging
- Other cardboard waste

METAL:
- Aluminum can
- Tin can
- Steel can
- Metal container
- Scrap metal
- Other metal waste

GLASS:
- Glass bottle
- Glass jar
- Glass container
- Broken glass
- Other glass waste

FOOD:
- Fruit waste
- Vegetable waste
- Food scraps
- Leftover food
- Organic waste
- Other food waste

ELECTRONIC WASTE:
- Phone
- Charger
- Cable
- Computer component
- Keyboard
- Mouse
- Small electronic device
- Electronic component
- Other electronic waste

BATTERIES:
- AA/AAA battery
- Rechargeable battery
- Battery pack
- Lithium battery
- Other battery waste

TEXTILE:
- Discarded clothing
- Fabric waste
- Textile waste

OTHER:
- Clearly discarded waste that does not fit the categories above.

============================================================
DO NOT CLASSIFY THESE AS WASTE
============================================================

Do NOT classify the following as waste unless the image clearly
shows them being discarded:

- People
- Animals
- Cars
- Motorcycles
- Buildings
- Houses
- Trees
- Plants
- Landscapes
- Furniture
- Clothing being worn
- Food being eaten
- Food being served
- Normal household objects
- Appliances that are clearly being used
- Phones that are clearly being used
- Computers that are clearly being used
- Screenshots
- Drawings
- Photos of people
- Random objects that cannot reasonably be identified as waste

============================================================
MAIN OBJECT
============================================================

Focus on the main object.

If several objects are visible, identify the object that appears
to be the primary subject of the image.

Do not let the background determine the classification.

For example:

If a plastic bottle is on a wooden table:
wasteType = "Plastic bottle"

If a person is holding a plastic bottle and the bottle is clearly
the main subject:
wasteType = "Plastic bottle"

If a person is the main subject and the bottle is incidental:
isWaste = false

============================================================
MATERIAL
============================================================

Identify the primary material when possible.

Examples:
- Plastic
- Paper
- Cardboard
- Glass
- Aluminum
- Metal
- Steel
- Food
- Organic
- Electronic
- Textile
- Battery
- Mixed material
- Unknown

Do not invent the exact plastic type unless it is clearly visible.

============================================================
RECYCLABILITY
============================================================

Estimate whether the item is commonly recyclable.

If recyclability depends strongly on local facilities, use the most
reasonable general classification and mention local guidelines in
the disposal advice.

Do not claim that every item is universally recyclable.

============================================================
HAZARD LEVEL
============================================================

Use exactly one of:

- Low
- Medium
- High
- Unknown

Examples:

Normal paper:
Low

Plastic bottle:
Low

Glass bottle:
Medium

Broken glass:
High

Battery:
High

Unknown hazardous item:
Unknown

============================================================
CONFIDENCE
============================================================

Return a number between 0.0 and 1.0.

Confidence should represent how certain you are about the visual
classification.

Examples:

Very clear object:
0.90 - 0.99

Reasonably clear:
0.70 - 0.89

Some uncertainty:
0.50 - 0.69

Very unclear:
below 0.50

Do not artificially use 0.99 for every image.

============================================================
RECYCLING SUGGESTIONS
============================================================

If isWaste is true:

Return EXACTLY 2 suggestions.

Each suggestion must contain EXACTLY 3 simple steps.

Use safe recommendations only.

Never recommend:
- burning
- cutting
- breaking
- melting
- chemically modifying
- opening batteries
- opening electronic devices
- dangerous handling

Possible iconType values:

recycle
clean
reuse
creative
dispose

============================================================
IMPORTANT JSON RULE
============================================================

Return ONLY valid JSON.

Do NOT use Markdown.

Do NOT use a code block.

Do NOT add an explanation before or after the JSON.

Use exactly this structure:

{
  "isWaste": true,
  "wasteType": "Plastic bottle",
  "material": "Plastic",
  "recyclable": true,
  "hazardLevel": "Low",
  "disposalAdvice": "Empty and rinse the bottle before placing it in the appropriate recycling bin.",
  "confidence": 0.95,
  "recyclingSuggestions": [
    {
      "title": "Recycle the bottle",
      "description": "Prepare the bottle properly for recycling.",
      "steps": [
        "Empty the bottle completely.",
        "Rinse the bottle.",
        "Place it in the appropriate recycling bin."
      ],
      "iconType": "recycle"
    },
    {
      "title": "Reuse the bottle",
      "description": "Reuse the bottle for a suitable household purpose.",
      "steps": [
        "Clean the bottle.",
        "Dry the bottle completely.",
        "Reuse it for a safe purpose."
      ],
      "iconType": "reuse"
    }
  ]
}

============================================================
NON-WASTE RESPONSE
============================================================

If the image does NOT contain a clear waste item, return:

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

============================================================
UNCLEAR IMAGE
============================================================

If the image is too blurry, too dark, too distant, obstructed,
or otherwise unclear:

Return:

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

============================================================
FINAL RULES
============================================================

- Focus on the main object.
- Analyze the image itself.
- Do not assume the object is a plastic bottle.
- Do not restrict classification to plastic.
- Identify paper, cardboard, glass, metal, food, electronic waste,
  batteries, textiles, and other waste when visible.
- Do not invent information.
- Do not guess when the image is genuinely unclear.
- Give practical disposal advice.
- Follow the exact JSON structure.
- Return JSON only.
''';
  }

  // ============================================================
  // FRIENDLY ERROR MESSAGE
  // ============================================================

  static String _friendlyErrorMessage(
    Object error,
  ) {
    final String message =
        error.toString().toLowerCase();

    if (message.contains('server error') ||
        message.contains('high demand') ||
        message.contains('status: internal') ||
        message.contains('statuscode=500') ||
        message.contains('"code": 500')) {
      return 'Gemini is temporarily busy. '
          'Please try scanning again in a few seconds.';
    }

    if (message.contains('quota') ||
        message.contains('resource_exhausted') ||
        message.contains('rate limit') ||
        message.contains('429') ||
        message.contains('free_tier')) {
      return 'The AI scan limit has been reached. '
          'Please wait for the Gemini quota to reset '
          'or check your Gemini API billing and limits.';
    }

    if (message.contains('app attestation failed') ||
        message.contains('firebase_app_check') ||
        message.contains('403')) {
      return 'Firebase App Check rejected this request. '
          'Please check your App Check configuration.';
    }

    if (message.contains('permission denied') ||
        message.contains('unauthenticated') ||
        message.contains('unauthorized')) {
      return 'Gemini access was denied. '
          'Please check your Firebase AI configuration.';
    }

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return 'Network connection failed. '
          'Please check your internet connection and try again.';
    }

    if (message.contains('not found') ||
        message.contains('not supported') ||
        message.contains('unsupported model')) {
      return 'The selected Gemini model is unavailable. '
          'Please try again or update the AI model configuration.';
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
  // PARSE GEMINI RESPONSE
  // ============================================================

  static WasteClassification _parseResponse(
    GenerateContentResponse response,
  ) {
    final String? responseText =
        response.text;

    debugPrint('');
    debugPrint('========================================');
    debugPrint('GEMINI RESPONSE');
    debugPrint('========================================');
    debugPrint(
      responseText ?? '(empty)',
    );
    debugPrint('========================================');

    if (responseText == null ||
        responseText.trim().isEmpty) {
      throw Exception(
        'Gemini returned an empty response.',
      );
    }

    final String jsonText =
        _extractJson(responseText);

    if (jsonText.isEmpty) {
      throw Exception(
        'Gemini returned invalid JSON.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(jsonText);
    } catch (e) {
      debugPrint(
        'JSON parsing failed: $e',
      );

      debugPrint(
        'Raw JSON text: $jsonText',
      );

      throw Exception(
        'Gemini returned invalid JSON.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Gemini response is not a JSON object.',
      );
    }

    final bool isWaste =
        decoded['isWaste'] == true;

    final String wasteType =
        _getString(
      decoded['wasteType'],
      'Unknown',
    );

    final String material =
        _getString(
      decoded['material'],
      'Unknown',
    );

    final bool recyclable =
        decoded['recyclable'] == true;

    final String hazardLevel =
        _getString(
      decoded['hazardLevel'],
      'Unknown',
    );

    final String disposalAdvice =
        _getString(
      decoded['disposalAdvice'],
      'Please follow your local waste disposal guidelines.',
    );

    double confidence = 0.0;

    final dynamic confidenceValue =
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
        confidence.clamp(
      0.0,
      1.0,
    );

    List<RecyclingSuggestion>
        recyclingSuggestions =
        _parseSuggestions(
      decoded['recyclingSuggestions'],
    );

    if (!isWaste) {
      recyclingSuggestions = [];
    }

    debugPrint('');
    debugPrint('========================================');
    debugPrint('ECOSCAN RESULT');
    debugPrint('========================================');
    debugPrint(
      'Is Waste: $isWaste',
    );
    debugPrint(
      'Waste: $wasteType',
    );
    debugPrint(
      'Material: $material',
    );
    debugPrint(
      'Recyclable: $recyclable',
    );
    debugPrint(
      'Hazard: $hazardLevel',
    );
    debugPrint(
      'Confidence: '
      '${(confidence * 100).toStringAsFixed(1)}%',
    );
    debugPrint(
      'Suggestions: '
      '${recyclingSuggestions.length}',
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
      recyclingSuggestions:
          recyclingSuggestions,
    );
  }

  // ============================================================
  // PARSE SUGGESTIONS
  // ============================================================

  static List<RecyclingSuggestion>
      _parseSuggestions(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    final List<RecyclingSuggestion>
        suggestions = [];

    for (final item in value) {
      if (item is! Map) {
        continue;
      }

      final String title =
          _getString(
        item['title'],
        'Recycling Idea',
      );

      final String description =
          _getString(
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

      if (steps.length > 3) {
        steps.removeRange(
          3,
          steps.length,
        );
      }

      while (steps.length < 3) {
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

    if (suggestions.length > 2) {
      return suggestions.sublist(
        0,
        2,
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
    String cleaned =
        text.trim();

    if (cleaned.startsWith(
      '```json',
    )) {
      cleaned =
          cleaned.substring(7).trim();
    } else if (cleaned.startsWith(
      '```',
    )) {
      cleaned =
          cleaned.substring(3).trim();
    }

    if (cleaned.endsWith(
      '```',
    )) {
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
      cleaned =
          cleaned.substring(
        start,
        end + 1,
      );
    }

    return cleaned.trim();
  }
}