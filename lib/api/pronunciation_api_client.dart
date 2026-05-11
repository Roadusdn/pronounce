import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/pronunciation_models.dart';

class PronunciationApiException implements Exception {
  final String message;
  final int? statusCode;

  const PronunciationApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null ? message : '$message ($statusCode)';
}

class PronunciationApiClient {
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  final Uri baseUri;
  final http.Client _client;

  PronunciationApiClient({
    String baseUrl = defaultBaseUrl,
    http.Client? client,
  })  : baseUri = Uri.parse(baseUrl),
        _client = client ?? http.Client();

  Future<List<Lesson>> getLessons() async {
    final json = await _getJson('/api/lessons');
    return _list(json).map(Lesson.fromJson).toList();
  }

  Future<List<Utterance>> getSceneUtterances(String sceneId) async {
    final json = await _getJson('/api/scenes/$sceneId/utterances');
    return _list(json).map(Utterance.fromJson).toList();
  }

  Future<AttemptStartResponse> startAttempt({
    required String lessonId,
    required String sceneId,
    required String utteranceId,
  }) async {
    final json = await _postJson('/api/attempts/start', {
      'lesson_id': lessonId,
      'scene_id': sceneId,
      'utterance_id': utteranceId,
    });
    return AttemptStartResponse.fromJson(json);
  }

  Future<void> uploadAttemptAudio({
    required String attemptId,
    required Uint8List audioBytes,
    String filename = 'recording.wav',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/attempts/$attemptId/audio'),
    );
    request.files.add(
      http.MultipartFile.fromBytes('audio', audioBytes, filename: filename),
    );

    final response = await http.Response.fromStream(await _client.send(request));
    _ensureSuccess(response);
  }

  Future<AttemptStatus> getAttemptStatus(String attemptId) async {
    final json = await _getJson('/api/attempts/$attemptId/status');
    return AttemptStatus.fromJson(json);
  }

  Future<AttemptResult> getAttemptResult(String attemptId) async {
    final json = await _getJson('/api/attempts/$attemptId/result');
    return AttemptResult.fromJson(_map(json, payloadKey: 'result'));
  }

  Future<List<PhonemeDetail>> getAttemptPhoneme(String attemptId) async {
    final json = await _getJson('/api/attempts/$attemptId/phoneme');
    return _list(json).map(PhonemeDetail.fromJson).toList();
  }

  Future<PitchDetail> getAttemptPitch(String attemptId) async {
    final json = await _getJson('/api/attempts/$attemptId/pitch');
    return PitchDetail.fromJson(_map(json, payloadKey: 'pitch'));
  }

  Future<AttemptFeedback> getAttemptFeedback(String attemptId) async {
    final json = await _getJson('/api/attempts/$attemptId/feedback');
    return AttemptFeedback.fromJson(_map(json, payloadKey: 'feedback'));
  }

  void close() => _client.close();

  Future<dynamic> _getJson(String path) async {
    final response = await _client.get(_uri(path));
    _ensureSuccess(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
    return _map(jsonDecode(response.body));
  }

  Uri _uri(String path) => baseUri.replace(path: path);

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw PronunciationApiException(
      response.body.isEmpty ? 'API request failed' : response.body,
      statusCode: response.statusCode,
    );
  }

  List<Map<String, dynamic>> _list(dynamic json) {
    final raw = json is Map<String, dynamic>
        ? json['items'] ??
            json['lessons'] ??
            json['utterances'] ??
            json['phonemes'] ??
            json['data'] ??
            const []
        : json;

    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Map<String, dynamic> _map(dynamic json, {String? payloadKey}) {
    if (json is Map<String, dynamic>) {
      final payload = payloadKey == null ? null : json[payloadKey];
      if (payload is Map<String, dynamic>) return payload;
      return json;
    }
    return const {};
  }
}
