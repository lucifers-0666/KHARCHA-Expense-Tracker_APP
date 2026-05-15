import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Severity levels for logged events
enum LogLevel { info, warning, error, fatal }

/// Central error & diagnostic logging service.
/// All logs are written to Firestore under:
///   /error_logs/{docId}
/// and user-scoped session info under:
///   /user_diagnostics/{uid}/logs/{docId}
///
/// Usage:
///   ErrorLogService.instance.logError(error, stackTrace, context: 'HomeScreen');
///   ErrorLogService.instance.logInfo('User opened analytics tab');
class ErrorLogService {
  ErrorLogService._();
  static final ErrorLogService instance = ErrorLogService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Derived helpers ──────────────────────────────────────────────────────

  String? get _uid => _auth.currentUser?.uid;
  String get _platform => kIsWeb ? 'web' : Platform.operatingSystem;
  String get _sessionId =>
      '${DateTime.now().millisecondsSinceEpoch}_${_uid ?? 'anonymous'}';

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Log any caught error with optional stack trace.
  /// [context] = screen / service name where the error happened.
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    await _write(
      level: LogLevel.error,
      message: error.toString(),
      stackTrace: stackTrace?.toString(),
      context: context,
      extra: extra,
    );
  }

  /// Log a fatal crash — call from Flutter's error handlers.
  Future<void> logFatal(
    FlutterErrorDetails details, {
    String? context,
  }) async {
    await _write(
      level: LogLevel.fatal,
      message: details.exceptionAsString(),
      stackTrace: details.stack?.toString(),
      context: context ?? details.context?.toDescription(),
      extra: {'library': details.library ?? 'unknown'},
    );
  }

  /// Log a warning (non-crashing but notable).
  Future<void> logWarning(
    String message, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    await _write(
      level: LogLevel.warning,
      message: message,
      context: context,
      extra: extra,
    );
  }

  /// Log a general informational event (navigation, feature use, etc).
  Future<void> logInfo(
    String message, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    await _write(
      level: LogLevel.info,
      message: message,
      context: context,
      extra: extra,
    );
  }

  /// Called once at app launch to record a healthy startup with device info.
  Future<void> logAppStartup() async {
    await _write(
      level: LogLevel.info,
      message: 'App started successfully',
      context: 'main',
      extra: {
        'platform': _platform,
        'isWeb': kIsWeb,
        'sessionId': _sessionId,
        'isDebugMode': kDebugMode,
      },
    );
  }

  /// Record a Firebase Auth event (login / register / logout).
  Future<void> logAuthEvent(
    String eventType, {
    String? email,
    String? failReason,
  }) async {
    await _write(
      level: failReason != null ? LogLevel.warning : LogLevel.info,
      message: 'Auth event: $eventType',
      context: 'AuthService',
      extra: {
        'eventType': eventType,
        if (email != null) 'email': email,
        if (failReason != null) 'failReason': failReason,
      },
    );
  }

  /// Record a Firestore operation failure.
  Future<void> logFirestoreError(
    String operation,
    dynamic error,
    StackTrace? st,
  ) async {
    await _write(
      level: LogLevel.error,
      message: 'Firestore error in $operation: $error',
      stackTrace: st?.toString(),
      context: 'FirestoreServices',
      extra: {'operation': operation},
    );
  }

  // ─── Internal writer ──────────────────────────────────────────────────────

  Future<void> _write({
    required LogLevel level,
    required String message,
    String? stackTrace,
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final payload = <String, dynamic>{
        'level': level.name,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': _platform,
        'uid': _uid ?? 'anonymous',
        if (context != null) 'context': context,
        if (stackTrace != null) 'stackTrace': stackTrace,
        if (extra != null) ...extra,
      };

      // Write to global error_logs collection
      await _db.collection('error_logs').add(payload);

      // Mirror under user's own document for per-user debugging
      final uid = _uid;
      if (uid != null) {
        await _db
            .collection('user_diagnostics')
            .doc(uid)
            .collection('logs')
            .add(payload);
      }

      // Always print to console in debug mode
      if (kDebugMode) {
        debugPrint(
          '[${level.name.toUpperCase()}] ${context != null ? '($context) ' : ''}$message',
        );
        if (stackTrace != null) debugPrint(stackTrace);
      }
    } catch (e) {
      // Never let the logger crash the app
      if (kDebugMode) debugPrint('ErrorLogService write failed: $e');
    }
  }
}
