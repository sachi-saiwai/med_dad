import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/app_state.dart';
import 'attachment_compression.dart';
import 'attachment_service.dart';
import 'auth_service.dart';
import 'certificate_extraction.dart';

class CloudApiException implements Exception {
  const CloudApiException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  bool get isInvitationRequired => code == 'invitation_required';
  bool get isNetworkError => code == 'network_error';

  @override
  String toString() => message;
}

class CloudConflictException extends CloudApiException {
  const CloudConflictException(this.currentRevision)
    : super('revision_conflict', '別の端末でデータが更新されました。', statusCode: 409);

  final int currentRevision;
}

class CloudSnapshotData {
  const CloudSnapshotData({
    required this.snapshot,
    required this.revision,
    required this.updatedAt,
  });

  final AppSnapshot snapshot;
  final int revision;
  final DateTime updatedAt;
}

class CloudBackup {
  const CloudBackup({
    required this.id,
    required this.revision,
    required this.createdAt,
    required this.byteLength,
  });

  final String id;
  final int revision;
  final DateTime createdAt;
  final int byteLength;

  factory CloudBackup.fromJson(Map<String, Object?> json) => CloudBackup(
    id: json['id']! as String,
    revision: (json['revision'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(json['createdAt']! as String),
    byteLength: (json['byteLength'] as num?)?.toInt() ?? 0,
  );
}

class CloudDataService {
  CloudDataService(this._auth, {http.Client? client})
    : _client = client ?? http.Client();

  final CloudAuthService _auth;
  final http.Client _client;

  static const _configuredBaseUrl = String.fromEnvironment('APP_API_BASE_URL');

  Uri _uri(String path, [Map<String, String>? query]) {
    final Uri base;
    if (_configuredBaseUrl.trim().isNotEmpty) {
      base = Uri.parse(
        _configuredBaseUrl.endsWith('/')
            ? _configuredBaseUrl
            : '$_configuredBaseUrl/',
      );
    } else if (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') {
      base = Uri.base;
    } else {
      throw const CloudApiException(
        'api_not_configured',
        'クラウドAPIのURLが設定されていません。',
      );
    }
    final uri = base.resolve(path.startsWith('/') ? path.substring(1) : path);
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<http.Response> _authorized(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    String? authorizationToken,
  }) async {
    Future<http.Response> send({required bool forceRefresh}) async {
      final token =
          authorizationToken ??
          await _auth.getIdToken(forceRefresh: forceRefresh);
      if (token == null || token.isEmpty) {
        throw const CloudApiException(
          'missing_auth_token',
          'ログイン情報を確認できませんでした。再ログインしてください。',
          statusCode: 401,
        );
      }
      final request = http.Request(method, _uri(path, query));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(body);
      }
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    }

    try {
      var response = await send(forceRefresh: false);
      if (response.statusCode == 401 && authorizationToken == null) {
        response = await send(forceRefresh: true);
      }
      return response;
    } on CloudApiException {
      rethrow;
    } on Object {
      throw const CloudApiException(
        'network_error',
        'サーバーへ接続できませんでした。通信環境を確認してください。',
      );
    }
  }

  Map<String, Object?> _decodeObject(http.Response response) {
    if (response.bodyBytes.isEmpty) return const {};
    try {
      return Map<String, Object?>.from(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map,
      );
    } on Object {
      throw CloudApiException(
        'invalid_server_response',
        'サーバーから正しい応答を受信できませんでした。',
        statusCode: response.statusCode,
      );
    }
  }

  Never _throwResponse(http.Response response) {
    final decoded = _decodeObject(response);
    final code = decoded['error'] as String? ?? 'server_error';
    if (response.statusCode == 409 && code == 'revision_conflict') {
      throw CloudConflictException(
        (decoded['currentRevision'] as num?)?.toInt() ?? 0,
      );
    }
    throw CloudApiException(
      code,
      _messageFor(code, decoded['message'] as String?),
      statusCode: response.statusCode,
    );
  }

  Future<void> checkAccess({String? inviteCode}) async {
    final response = await _authorized(
      inviteCode == null ? 'GET' : 'POST',
      '/api/v1/access',
      body: inviteCode == null ? null : {'inviteCode': inviteCode},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwResponse(response);
    }
  }

  Future<CloudSnapshotData?> fetchSnapshot() async {
    final response = await _authorized('GET', '/api/v1/me');
    if (response.statusCode != 200) _throwResponse(response);
    final data = _decodeObject(response)['data'];
    if (data == null) return null;
    final json = Map<String, Object?>.from(data as Map);
    return CloudSnapshotData(
      revision: (json['revision'] as num).toInt(),
      snapshot: AppSnapshot.fromJson(
        Map<String, Object?>.from(json['snapshot']! as Map),
      ),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
    );
  }

  Future<CloudSnapshotData> saveSnapshot(
    AppSnapshot snapshot, {
    required int baseRevision,
  }) async {
    final response = await _authorized(
      'PUT',
      '/api/v1/me',
      body: {'baseRevision': baseRevision, 'snapshot': snapshot.toJson()},
    );
    if (response.statusCode != 200) _throwResponse(response);
    final data = Map<String, Object?>.from(
      _decodeObject(response)['data']! as Map,
    );
    return CloudSnapshotData(
      revision: (data['revision'] as num).toInt(),
      snapshot: AppSnapshot.fromJson(
        Map<String, Object?>.from(data['snapshot']! as Map),
      ),
      updatedAt: DateTime.parse(data['updatedAt']! as String),
    );
  }

  Future<String> uploadAttachment(PickedAttachment attachment) async {
    final prepared = await shrinkAttachmentForUpload(attachment);
    final bytes = prepared.bytes;
    final contentType = prepared.contentType;
    if (bytes == null || contentType == null) {
      throw const CloudApiException(
        'attachment_bytes_missing',
        '添付ファイルの内容を読み取れませんでした。',
      );
    }
    if (bytes.length > maxAttachmentBytes) {
      throw CloudApiException(
        'attachment_too_large',
        attachmentTooLargeMessage(contentType),
      );
    }
    final response = await _authorized(
      'POST',
      '/api/v1/attachments',
      body: {
        'name': prepared.displayName,
        'contentType': contentType,
        'base64': base64Encode(bytes),
      },
    );
    if (response.statusCode != 201) _throwResponse(response);
    final data = Map<String, Object?>.from(
      _decodeObject(response)['data']! as Map,
    );
    return data['id']! as String;
  }

  Future<CertificateExtraction> extractCertificate({
    required String ocrText,
    required List<String> qualificationNames,
    PickedAttachment? attachment,
    bool includeAttachment = false,
  }) async {
    final prepared = includeAttachment && attachment != null
        ? await shrinkAttachmentForUpload(attachment)
        : null;
    final bytes = prepared?.bytes;
    if (bytes != null && bytes.length > maxAttachmentBytes) {
      throw CloudApiException(
        'attachment_too_large',
        attachmentTooLargeMessage(prepared!.contentType),
      );
    }
    final response = await _authorized(
      'POST',
      '/api/v1/certificate-extraction',
      body: {
        'ocrText': ocrText,
        'qualificationNames': qualificationNames,
        if (bytes != null) 'fileBase64': base64Encode(bytes),
        if (bytes != null) 'contentType': prepared?.contentType,
      },
    );
    if (response.statusCode != 200) _throwResponse(response);
    final data = Map<String, Object?>.from(
      _decodeObject(response)['data']! as Map,
    );
    return CertificateExtraction.fromJson(data);
  }

  Future<CloudBackup> createBackup() async {
    final response = await _authorized('POST', '/api/v1/backups');
    if (response.statusCode != 201) _throwResponse(response);
    return CloudBackup.fromJson(
      Map<String, Object?>.from(_decodeObject(response)['data']! as Map),
    );
  }

  Future<List<CloudBackup>> listBackups() async {
    final response = await _authorized('GET', '/api/v1/backups');
    if (response.statusCode != 200) _throwResponse(response);
    final items = _decodeObject(response)['data'] as List<Object?>? ?? const [];
    return items
        .map(
          (item) =>
              CloudBackup.fromJson(Map<String, Object?>.from(item! as Map)),
        )
        .toList();
  }

  Future<AppSnapshot> fetchBackup(String id) async {
    final response = await _authorized(
      'GET',
      '/api/v1/backups',
      query: {'id': id},
    );
    if (response.statusCode != 200) _throwResponse(response);
    final data = Map<String, Object?>.from(
      _decodeObject(response)['data']! as Map,
    );
    return AppSnapshot.fromJson(
      Map<String, Object?>.from(data['snapshot']! as Map),
    );
  }

  Future<String> fetchWebPushPublicKey() async {
    final response = await _client.get(_uri('/api/v1/push-config'));
    if (response.statusCode != 200) _throwResponse(response);
    return _decodeObject(response)['publicKey']! as String;
  }

  Future<void> registerWebPushSubscription(
    Map<String, Object?> subscription,
  ) async {
    final response = await _authorized(
      'POST',
      '/api/v1/push-subscriptions',
      body: subscription,
    );
    if (response.statusCode != 201) _throwResponse(response);
  }

  Future<void> deleteAccountData({String? authorizationToken}) async {
    final response = await _authorized(
      'DELETE',
      '/api/v1/account',
      authorizationToken: authorizationToken,
    );
    if (response.statusCode != 200) _throwResponse(response);
  }

  void close() => _client.close();
}

String _messageFor(String code, String? serverMessage) => switch (code) {
  'invitation_required' => 'このアカウントには招待コードが必要です。',
  'invalid_or_expired_invite' => '招待コードが正しくないか、有効期限が切れています。',
  'invalid_invite_code' => '招待コードの形式を確認してください。',
  'attachment_too_large' => '添付できるファイルは3MBまでです。',
  'attachment_content_mismatch' => 'ファイルの内容と形式が一致しません。別のファイルを選んでください。',
  'unsupported_attachment_type' => 'このファイル形式には対応していません。',
  'web_push_not_configured' => 'Web Pushのサーバー設定が完了していません。',
  _ =>
    serverMessage?.trim().isNotEmpty == true
        ? serverMessage!
        : 'サーバー処理に失敗しました。時間をおいてもう一度お試しください。',
};
