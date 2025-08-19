import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

enum ModelType { sentiment, spam, grammatical }

extension ModelTypeExt on ModelType {
  String get path => 'assets/${name}_analysis/';
  int get defaultMaxLength => this == ModelType.grammatical
      ? 100
      : (this == ModelType.spam ? 256 : 250);
  List<RegExp> get regexPatterns => this == ModelType.spam
      ? [RegExp(r'http\S+|www\S+|@\w+|#\w+'), RegExp(r'[^a-zA-Z\s]')]
      : [RegExp(r'[^\w\s]')];
}

class NLPService {
  static final instance = NLPService._();
  NLPService._();

  final Map<ModelType, NLPModel> _models = {};

  Future<void> initializeModel(ModelType type) async =>
      _models[type] ??= await NLPModel._create(type);

  Future<NLPResult> predict(ModelType type, String text) async {
    final model = _models[type];
    if (model == null) {
      throw Exception(
        'Model $type not initialized. Call initializeModel() first.',
      );
    }
    return model.predict(text);
  }

  void dispose() {
    for (var model in _models.values) {
      model.dispose();
    }
    _models.clear();
  }
}

class NLPModel {
  final ModelType type;
  final Interpreter _interpreter;
  final List<String> _labels;
  final Map<String, int> _wordIndex;
  final int _maxLength;
  final int _numWords;

  NLPModel._({
    required this.type,
    required Interpreter interpreter,
    required List<String> labels,
    required Map<String, int> wordIndex,
    required int maxLength,
    required int numWords,
  })  : _interpreter = interpreter,
        _labels = labels,
        _wordIndex = wordIndex,
        _maxLength = maxLength,
        _numWords = numWords;

  static Future<NLPModel> _create(ModelType type) async {
    final [interpreter, labels, tokenizer] = await Future.wait([
      _loadModel(type),
      _loadLabels(type),
      _loadTokenizer(type),
    ]);

    final tokenizerMap = tokenizer as Map<String, dynamic>;
    final wordIndex = tokenizerMap.containsKey('word_index')
        ? Map<String, int>.from(tokenizerMap['word_index'])
        : tokenizerMap.isNotEmpty
            ? Map<String, int>.from(tokenizerMap)
            : <String, int>{};

    return NLPModel._(
      type: type,
      interpreter: interpreter as Interpreter,
      labels: labels as List<String>,
      wordIndex: wordIndex,
      maxLength: tokenizerMap['max_length'] ?? type.defaultMaxLength,
      numWords: tokenizerMap['num_words'] ?? 10000,
    );
  }

  static Future<Interpreter> _loadModel(ModelType type) async =>
      Interpreter.fromAsset(
        '${type.path}model.tflite',
        options: InterpreterOptions(),
      );

  static Future<List<String>> _loadLabels(ModelType type) async {
    final data = await rootBundle.loadString('${type.path}labels.json');
    final json = jsonDecode(data);
    return List<String>.from(json['classes']);
  }

  static Future<Map<String, dynamic>> _loadTokenizer(ModelType type) async {
    try {
      final data = await rootBundle.loadString('${type.path}token.json');
      final json = jsonDecode(data);
      return json is Map<String, dynamic> && json.isNotEmpty ? json : {};
    } catch (e) {
      return {};
    }
  }

  String _preprocessText(String text) {
    if (text.isEmpty) return '';
    text = text.toLowerCase();
    for (final regex in type.regexPatterns) {
      text = text.replaceAll(regex, '');
    }
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<int> _textToSequence(String text) => text.split(' ').map((word) {
        final index = _wordIndex[word];
        if (index != null) return index < _numWords ? index : 1;
        return (word.hashCode.abs() % (_numWords - 2)) + 2;
      }).toList();

  List<int> _padSequence(List<int> sequence) => sequence.length >= _maxLength
      ? sequence.take(_maxLength).toList()
      : [...sequence, ...List.filled(_maxLength - sequence.length, 0)];

  List<double> _softmax(List<double> predictions) {
    final maxScore = predictions.reduce(math.max);
    final exp = predictions.map((x) => math.exp(x - maxScore)).toList();
    final sumExp = exp.reduce((a, b) => a + b);
    return exp.map((x) => x / sumExp).toList();
  }

  Future<NLPResult> predict(String text) async {
    final cleanedText = _preprocessText(text);
    final sequence = _textToSequence(cleanedText);
    final paddedSequence = _padSequence(sequence);

    final input = Float32List.fromList(
      paddedSequence.map((e) => e.toDouble()).toList(),
    ).reshape([1, _maxLength]);
    final output = List.filled(
      _labels.length,
      0.0,
    ).reshape([1, _labels.length]);

    _interpreter.run(input, output);

    final predictions = output[0].cast<double>();
    final softmax = _softmax(predictions);
    final maxIndex = softmax.indexOf(softmax.reduce(math.max));

    return NLPResult(
      modelType: type,
      label: _labels[maxIndex],
      confidence: softmax[maxIndex],
      allScores: Map.fromIterables(_labels, softmax),
      originalText: text,
      cleanedText: cleanedText,
    );
  }

  void dispose() => _interpreter.close();
}

class NLPResult {
  final ModelType modelType;
  final String label;
  final double confidence;
  final Map<String, double> allScores;
  final String originalText;
  final String cleanedText;

  const NLPResult({
    required this.modelType,
    required this.label,
    required this.confidence,
    required this.allScores,
    required this.originalText,
    required this.cleanedText,
  });
}
