import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/pronunciation_models.dart';

class PronunciationApiException implements Exception {
  final String message;
  final int? statusCode;

  const PronunciationApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode == null) return message;
    return '$message ($statusCode)';
  }
}

class PronunciationApiClient {
  static const configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  final Uri baseUri;
  final http.Client _client;

  PronunciationApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUri = Uri.parse(baseUrl ?? defaultBaseUrl),
        _client = client ?? http.Client();

  static String get defaultBaseUrl {
    if (configuredBaseUrl.isNotEmpty) return configuredBaseUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  Future<List<Lesson>> getLessons() async {
    final json = await _getJson('/api/lessons');
    return _list(json).map(Lesson.fromJson).toList();
  }

  Future<Lesson> getLesson(String lessonId) async {
    final json = await _getJson('/api/lessons/$lessonId');
    return Lesson.fromJson(_map(json));
  }

  Future<SceneItem> getScene(String sceneId) async {
    final json = await _getJson('/api/scenes/$sceneId');
    return SceneItem.fromJson(_map(json));
  }

  Future<List<SceneItem>> getLessonScenes(String lessonId) async {
    final json = await _getJson('/api/lessons/$lessonId/scenes');
    return _list(json).map(SceneItem.fromJson).toList();
  }

  Future<List<Utterance>> getSceneUtterances(String sceneId) async {
    final json = await _getJson('/api/scenes/$sceneId/utterances');
    return _list(json).map(Utterance.fromJson).toList();
  }

  Future<List<Attempt>> getAttempts({String? userId}) async {
    final query = userId == null || userId.isEmpty ? null : {'user_id': userId};
    final json = await _getJson('/api/attempts', queryParameters: query);
    return _list(json).map(Attempt.fromJson).toList();
  }

  Future<void> deleteAttempts({String userId = 'local_user'}) async {
    final response = await _client.delete(
      _uri('/api/attempts', queryParameters: {'user_id': userId}),
    );
    _ensureSuccess(response);
  }

  Future<AttemptStartResponse> startAttempt({
    required String utteranceId,
    String userId = 'local_user',
    String? lessonId,
    String? sceneId,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'utterance_id': utteranceId,
    };

    if (lessonId != null) body['lesson_id'] = lessonId;
    if (sceneId != null) body['scene_id'] = sceneId;

    final json = await _postJson('/api/attempts/start', body);

    return AttemptStartResponse.fromJson(json);
  }

  Future<Map<String, dynamic>> uploadAttemptAudio({
    required String attemptId,
    required Uint8List audioBytes,
    String filename = 'recording.wav',
    String fieldName = 'audio',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/attempts/$attemptId/audio'),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        audioBytes,
        filename: filename,
      ),
    );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response);
    return _map(jsonDecode(response.body));
  }

  Future<AttemptStatus> getAttemptStatus(String attemptId) async {
    final json = await _getJson('/api/attempts/$attemptId/status');
    return AttemptStatus.fromJson(_map(json));
  }

  Future<AttemptResult> getAttemptResult(String attemptId) async {
    final json = await _getJson('/api/attempts/$attemptId/result');
    return AttemptResult.fromJson(_map(json, payloadKey: 'result'));
  }

  Future<List<PhonemeDetail>> getAttemptPhoneme(String attemptId) async {
    final json = await _getJson('/api/attempts/$attemptId/phoneme');
    return _list(json, payloadKeys: const ['phonemes', 'items', 'data'])
        .map(PhonemeDetail.fromJson)
        .toList();
  }

  Future<PitchDetail> getAttemptPitch(String attemptId) async {
    final json = await _getJson('/api/attempts/$attemptId/pitch');
    return PitchDetail.fromJson(_map(json, payloadKey: 'pitch'));
  }

  Future<AttemptFeedback> getAttemptFeedback(String attemptId) async {
    final json = await _getJson('/api/attempts/$attemptId/feedback');
    return AttemptFeedback.fromJson(_map(json, payloadKey: 'feedback'));
  }

  Future<AttemptAnalysisResult> getAttemptAnalysis(String attemptId) async {
    final json = await _getJson('/api/attempts/$attemptId/analysis');
    return AttemptAnalysisResult.fromJson(_map(json, payloadKey: 'analysis'));
  }

  Future<Map<String, dynamic>> analyze({
    required String expectedText,
    required Uint8List audioBytes,
    String filename = 'recording.wav',
    Uint8List? referenceAudioBytes,
    String referenceFilename = 'reference.wav',
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/analyze'));

    request.fields['expected_text'] = expectedText;
    request.files.add(
      http.MultipartFile.fromBytes(
        'audio_file',
        audioBytes,
        filename: filename,
      ),
    );

    if (referenceAudioBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'reference_audio_file',
          referenceAudioBytes,
          filename: referenceFilename,
        ),
      );
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response);
    return _map(jsonDecode(response.body));
  }

  Future<String> transcribeAudio({
    required Uint8List audioBytes,
    String filename = 'recording.m4a',
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/transcribe'));

    request.files.add(
      http.MultipartFile.fromBytes(
        'audio_file',
        audioBytes,
        filename: filename,
      ),
    );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response);

    final json = _map(jsonDecode(response.body));
    return json['transcript']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> analyzeFromMetadata({
    required String utteranceId,
    required Uint8List audioBytes,
    String filename = 'recording.wav',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/analyze/metadata'),
    );

    request.fields['utterance_id'] = utteranceId;
    request.files.add(
      http.MultipartFile.fromBytes(
        'audio_file',
        audioBytes,
        filename: filename,
      ),
    );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response);
    return _map(jsonDecode(response.body));
  }

  Future<UserProfile> getUserProfile(String userId) async {
    final json = await _getJson('/api/users/$userId');
    return UserProfile.fromJson(_map(json));
  }

  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    final json = await _postJson('/api/users/profile', profile.toJson());
    return UserProfile.fromJson(_map(json));
  }

  void close() => _client.close();

  Future<dynamic> _getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client.get(
      _uri(path, queryParameters: queryParameters),
    );
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

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return baseUri.replace(
      path: normalizedPath,
      queryParameters: queryParameters,
    );
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    var message = response.body.isEmpty ? 'API request failed' : response.body;
    try {
      final json = jsonDecode(response.body);
      if (json is Map && json['detail'] != null) {
        message = json['detail'].toString();
      }
    } catch (_) {
      // Keep the raw body when the server did not return JSON.
    }

    if (message.contains('ffmpeg')) {
      message = '음성 인식을 하려면 백엔드 실행 환경에 ffmpeg가 필요합니다.';
    }

    throw PronunciationApiException(
      message,
      statusCode: response.statusCode,
    );
  }

  List<Map<String, dynamic>> _list(
    dynamic json, {
    List<String> payloadKeys = const [
      'items',
      'lessons',
      'scenes',
      'utterances',
      'attempts',
      'phonemes',
      'data',
    ],
  }) {
    dynamic raw = json;

    if (json is Map<String, dynamic>) {
      for (final key in payloadKeys) {
        if (json[key] is List) {
          raw = json[key];
          break;
        }
      }
    }

    if (raw is! List) return const [];
    return raw.map(_map).where((item) => item.isNotEmpty).toList();
  }

  Map<String, dynamic> _map(dynamic json, {String? payloadKey}) {
    if (json is Map<String, dynamic>) {
      final payload = payloadKey == null ? null : json[payloadKey];
      if (payload is Map<String, dynamic>) return payload;
      return json;
    }

    if (json is Map) {
      return json.map((key, value) => MapEntry(key.toString(), value));
    }

    return const {};
  }
}
