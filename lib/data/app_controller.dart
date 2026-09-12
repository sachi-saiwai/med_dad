import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';
import '../services/attachment_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_data_service.dart';
import '../services/certificate_extraction.dart';
import '../services/web_push_service.dart';
import 'app_data_store.dart';
import 'app_state.dart';

enum AccountConnectionStatus { connected, invitationRequired }

class AccountConnectionResult {
  const AccountConnectionResult(this.status, {this.message});

  final AccountConnectionStatus status;
  final String? message;

  bool get isConnected => status == AccountConnectionStatus.connected;
}

class AppController extends ChangeNotifier {
  AppController._(this._store, this._notifications, this._snapshot)
    : _webPush = createWebPushService();

  final AppDataStore _store;
  final NotificationService _notifications;
  final WebPushService _webPush;
  AppSnapshot _snapshot;
  bool _demoMode = false;
  CloudDataService? _cloud;
  String? _cloudUserId;
  int _remoteRevision = 0;
  Future<void>? _syncFuture;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  String? _syncError;

  AppSnapshot get snapshot => _snapshot;
  bool get isSetupComplete => _snapshot.setupComplete;
  bool get demoMode => _demoMode;
  bool get cloudConnected => _cloud != null;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get syncError => _syncError;
  bool get webPushSupported => _webPush.isSupported;

  /// Loads the local data of [accountId]. Each account keeps its own dataset on
  /// the device, so signing in with another account never overwrites or exposes
  /// someone else's records.
  Future<void> activateAccount(String accountId) async {
    if (_snapshot.accountId == accountId) return;
    _snapshot = await _store.load(accountId: accountId);
    _demoMode = false;
    await _notifications.rescheduleDeadlineNotifications(
      _snapshot.qualifications,
      enabled: _snapshot.settings.deadlineNotifications,
    );
    notifyListeners();
  }

  /// Data entered before signing in belongs to whoever signs in first.
  Future<void> _adoptPreSignInData(String accountId) async {
    if (_snapshot.accountId != accountId || _snapshot.setupComplete) return;
    final preSignIn = await _store.load();
    if (!preSignIn.setupComplete) return;
    _snapshot = preSignIn.copyWith(accountId: accountId);
    await _store.save(_snapshot);
    await _store.remove();
    await _notifications.rescheduleDeadlineNotifications(
      _snapshot.qualifications,
      enabled: _snapshot.settings.deadlineNotifications,
    );
    notifyListeners();
  }

  Future<AccountConnectionResult> connectAuthenticatedAccount(
    AuthService authService,
    AuthUser user, {
    String? inviteCode,
  }) async {
    final cloudAuthService = authService is CloudAuthService
        ? authService as CloudAuthService
        : null;
    await activateAccount(user.id);
    if (cloudAuthService == null) {
      await _adoptPreSignInData(user.id);
      return const AccountConnectionResult(AccountConnectionStatus.connected);
    }

    if (_cloudUserId != user.id || _cloud == null) {
      _cloud?.close();
      _cloud = CloudDataService(cloudAuthService);
      _cloudUserId = user.id;
      _remoteRevision = 0;
      _lastSyncedAt = null;
      _syncError = null;
    }

    try {
      await _cloud!.checkAccess(inviteCode: inviteCode);
    } on CloudApiException catch (error) {
      if (error.isInvitationRequired ||
          error.code == 'invalid_or_expired_invite') {
        return AccountConnectionResult(
          AccountConnectionStatus.invitationRequired,
          message: error.message,
        );
      }
      if (error.isNetworkError &&
          _snapshot.accountId == user.id &&
          _snapshot.setupComplete) {
        _syncError = error.message;
        notifyListeners();
        return const AccountConnectionResult(AccountConnectionStatus.connected);
      }
      rethrow;
    }

    await _adoptPreSignInData(user.id);
    await _webPush.requestPersistentStorage();
    await _initialCloudSync(user.id);
    return const AccountConnectionResult(AccountConnectionStatus.connected);
  }

  Future<void> _initialCloudSync(String accountId) async {
    final cloud = _cloud;
    if (cloud == null) return;
    try {
      final remote = await cloud.fetchSnapshot();
      if (remote == null) {
        final uploaded = await cloud.saveSnapshot(_snapshot, baseRevision: 0);
        _remoteRevision = uploaded.revision;
        _lastSyncedAt = uploaded.updatedAt;
      } else {
        _remoteRevision = remote.revision;
        final localUpdatedAt = DateTime.tryParse(_snapshot.updatedAt ?? '');
        final localWins =
            _snapshot.setupComplete &&
            localUpdatedAt != null &&
            localUpdatedAt.isAfter(remote.updatedAt);
        if (localWins) {
          final uploaded = await cloud.saveSnapshot(
            _snapshot,
            baseRevision: _remoteRevision,
          );
          _remoteRevision = uploaded.revision;
          _lastSyncedAt = uploaded.updatedAt;
        } else {
          _snapshot = remote.snapshot.copyWith(accountId: accountId);
          await _store.save(_snapshot);
          _lastSyncedAt = remote.updatedAt;
          await _notifications.rescheduleDeadlineNotifications(
            _snapshot.qualifications,
            enabled: _snapshot.settings.deadlineNotifications,
          );
        }
      }
      _syncError = null;
      notifyListeners();
    } on CloudApiException catch (error) {
      if (error.isNetworkError && _snapshot.setupComplete) {
        _syncError = error.message;
        notifyListeners();
        return;
      }
      rethrow;
    }
  }

  static Future<AppController> load() async {
    final store = createAppDataStore();
    final notifications = createNotificationService();
    await notifications.initialize();
    final snapshot = await store.load();
    await notifications.rescheduleDeadlineNotifications(
      snapshot.qualifications,
      enabled: snapshot.settings.deadlineNotifications,
    );
    return AppController._(store, notifications, snapshot);
  }

  factory AppController.memory() {
    return AppController._(
      MemoryAppDataStore(),
      NoopNotificationService(),
      const AppSnapshot(),
    );
  }

  Future<void> completeSetup({
    required String displayName,
    required List<StoredQualification> qualifications,
    required bool notificationsEnabled,
  }) async {
    _demoMode = false;
    _snapshot = _snapshot.copyWith(
      setupComplete: true,
      displayName: displayName.trim(),
      qualifications: qualifications,
      settings: _snapshot.settings.copyWith(
        deadlineNotifications: notificationsEnabled,
      ),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    notifyListeners();
    await _store.save(_snapshot);
    if (notificationsEnabled) await _notifications.requestPermission();
    await _notifications.rescheduleDeadlineNotifications(
      qualifications,
      enabled: notificationsEnabled,
    );
    await syncNow();
  }

  void enterDemoMode() {
    _demoMode = true;
    notifyListeners();
  }

  Future<void> addActivity(StoredActivity activity) async {
    _snapshot = _snapshot.copyWith(
      activities: [activity, ..._snapshot.activities],
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    notifyListeners();
    await _store.save(_snapshot);
    await syncNow();
  }

  Future<void> updateActivity(StoredActivity activity) async {
    final index = _snapshot.activities.indexWhere(
      (item) => item.id == activity.id,
    );
    if (index < 0) return;
    final activities = [..._snapshot.activities];
    activities[index] = activity;
    _snapshot = _snapshot.copyWith(
      activities: activities,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    notifyListeners();
    await _store.save(_snapshot);
    await syncNow();
  }

  Future<void> updateQualification(StoredQualification qualification) async {
    final index = _snapshot.qualifications.indexWhere(
      (item) => item.id == qualification.id,
    );
    if (index < 0) return;
    final qualifications = [..._snapshot.qualifications];
    qualifications[index] = qualification;
    _snapshot = _snapshot.copyWith(
      qualifications: qualifications,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    notifyListeners();
    await _store.save(_snapshot);
    await _notifications.rescheduleDeadlineNotifications(
      qualifications,
      enabled: _snapshot.settings.deadlineNotifications,
    );
    await syncNow();
  }

  Future<void> updateSettings(AppSettingsData settings) async {
    _snapshot = _snapshot.copyWith(
      settings: settings,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    notifyListeners();
    await _store.save(_snapshot);
    if (settings.deadlineNotifications) {
      await _notifications.requestPermission();
    }
    await _notifications.rescheduleDeadlineNotifications(
      _snapshot.qualifications,
      enabled: settings.deadlineNotifications,
    );
    await syncNow();
  }

  void updateSettingsUnawaited(AppSettingsData settings) {
    unawaited(updateSettings(settings));
  }

  Future<void> syncNow() {
    final existing = _syncFuture;
    if (existing != null) return existing;
    final future = _performSync();
    _syncFuture = future;
    future.whenComplete(() {
      if (identical(_syncFuture, future)) _syncFuture = null;
    });
    return future;
  }

  Future<void> _performSync() async {
    final cloud = _cloud;
    if (cloud == null || _demoMode) return;
    _isSyncing = true;
    notifyListeners();
    try {
      CloudSnapshotData saved;
      try {
        saved = await cloud.saveSnapshot(
          _snapshot,
          baseRevision: _remoteRevision,
        );
      } on CloudConflictException {
        final remote = await cloud.fetchSnapshot();
        if (remote == null) rethrow;
        _remoteRevision = remote.revision;
        final localUpdatedAt = DateTime.tryParse(_snapshot.updatedAt ?? '');
        if (localUpdatedAt == null ||
            !localUpdatedAt.isAfter(remote.updatedAt)) {
          _snapshot = remote.snapshot.copyWith(accountId: _cloudUserId);
          await _store.save(_snapshot);
          _lastSyncedAt = remote.updatedAt;
          _syncError = null;
          return;
        }
        saved = await cloud.saveSnapshot(
          _snapshot,
          baseRevision: remote.revision,
        );
      }
      _remoteRevision = saved.revision;
      _lastSyncedAt = saved.updatedAt;
      _syncError = null;
    } on CloudApiException catch (error) {
      _syncError = error.message;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<String?> uploadAttachment(PickedAttachment? attachment) async {
    if (attachment == null) return null;
    final cloud = _cloud;
    if (cloud != null && attachment.bytes != null) {
      final id = await cloud.uploadAttachment(attachment);
      return 'cloud:$id';
    }
    return attachment.path;
  }

  Future<PickedAttachment?> loadActivityAttachment(
    String? attachmentPath,
  ) async {
    if (attachmentPath == null || attachmentPath.trim().isEmpty) return null;
    if (attachmentPath.startsWith('cloud:')) {
      final cloud = _cloud;
      if (cloud == null) {
        throw const CloudApiException(
          'cloud_not_connected',
          '証明書を表示するにはログインしてください。',
        );
      }
      return cloud.fetchAttachment(attachmentPath.substring('cloud:'.length));
    }
    return readStoredAttachment(attachmentPath);
  }

  Future<CertificateExtraction> extractCertificate({
    required String ocrText,
    PickedAttachment? attachment,
    bool includeAttachment = false,
  }) async {
    final local = extractCertificateFields(ocrText);
    final cloud = _cloud;
    if (cloud == null || _demoMode) return local;
    try {
      final result = await cloud.extractCertificate(
        ocrText: ocrText,
        qualificationNames: _snapshot.qualifications
            .map((item) => item.name)
            .toList(growable: false),
        attachment: attachment,
        includeAttachment: includeAttachment,
      );
      if (result.hasUsefulValues) {
        if (result.certificationId.isEmpty &&
            local.certificationId.isNotEmpty) {
          return result.copyWith(
            certificationId: local.certificationId,
            fieldConfidence: {
              ...result.fieldConfidence,
              if (local.confidenceFor('certificationId') != null)
                'certificationId': local.confidenceFor('certificationId')!,
            },
          );
        }
        return result;
      }
      return local.withWarning('AIから有効な項目を取得できなかったため端末内抽出を使用しました');
    } on CloudApiException catch (error) {
      if (local.hasUsefulValues) {
        return local.withWarning('AI構造化を利用できませんでした（${error.message}）');
      }
      rethrow;
    }
  }

  Future<CloudBackup> createCloudBackup() async {
    final cloud = _cloud;
    if (cloud == null) {
      throw const CloudApiException(
        'cloud_not_connected',
        'クラウドへ接続してからバックアップしてください。',
      );
    }
    await syncNow();
    if (_syncError != null) {
      throw CloudApiException('sync_failed', _syncError!);
    }
    return cloud.createBackup();
  }

  Future<CloudBackup> restoreLatestCloudBackup() async {
    final cloud = _cloud;
    if (cloud == null) {
      throw const CloudApiException(
        'cloud_not_connected',
        'クラウドへ接続してから復元してください。',
      );
    }
    final backups = await cloud.listBackups();
    if (backups.isEmpty) {
      throw const CloudApiException('backup_not_found', '復元できるバックアップがありません。');
    }
    final latest = backups.first;
    final restored = await cloud.fetchBackup(latest.id);
    _snapshot = restored.copyWith(
      accountId: _cloudUserId,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _store.save(_snapshot);
    await _notifications.rescheduleDeadlineNotifications(
      _snapshot.qualifications,
      enabled: _snapshot.settings.deadlineNotifications,
    );
    notifyListeners();
    await syncNow();
    if (_syncError != null) {
      throw CloudApiException('sync_failed', _syncError!);
    }
    return latest;
  }

  Future<void> enableWebPush() async {
    final cloud = _cloud;
    if (!_webPush.isSupported || cloud == null) {
      throw const CloudApiException(
        'web_push_unavailable',
        'この端末ではWeb通知を設定できません。ホーム画面から開いてください。',
      );
    }
    final publicKey = await cloud.fetchWebPushPublicKey();
    final subscription = await _webPush.subscribe(publicKey);
    await cloud.registerWebPushSubscription(subscription);
  }

  Future<void> deleteAccountAndData(AuthService authService) async {
    final cloud = _cloud;
    final cloudAuthService = authService is CloudAuthService
        ? authService as CloudAuthService
        : null;
    if (cloud == null || cloudAuthService == null) {
      throw const CloudApiException(
        'cloud_not_connected',
        'クラウドへ接続してから削除してください。',
      );
    }
    final token = await cloudAuthService.getIdToken(forceRefresh: true);
    if (token == null || token.isEmpty) {
      throw const CloudApiException(
        'missing_auth_token',
        'ログイン情報を確認できませんでした。再ログインしてください。',
      );
    }
    await cloudAuthService.deleteCurrentUser();
    try {
      await cloud.deleteAccountData(authorizationToken: token);
    } finally {
      await _store.remove(accountId: _snapshot.accountId);
      _snapshot = await _store.load();
      _remoteRevision = 0;
      _cloudUserId = null;
      _cloud?.close();
      _cloud = null;
      await _notifications.rescheduleDeadlineNotifications(
        _snapshot.qualifications,
        enabled: _snapshot.settings.deadlineNotifications,
      );
      notifyListeners();
    }
  }
}
