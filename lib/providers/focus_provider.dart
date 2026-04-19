import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/focus_session_model.dart';
import '../models/auth_user_model.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import '../core/utils/date_helper.dart';
import 'user_provider.dart';
import 'auth_provider.dart';

enum TimerState { idle, running, paused, finished }

class FocusState {
  final List<FocusSessionModel> sessions;
  final FocusSessionModel? activeSession;
  final TimerState timerState;
  final int remainingSeconds;
  final int elapsedSeconds;
  final SessionType sessionType;
  final int focusDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final int sessionsCompleted;
  final String? linkedTaskId;

  const FocusState({
    this.sessions = const [],
    this.activeSession,
    this.timerState = TimerState.idle,
    this.remainingSeconds = 0,
    this.elapsedSeconds = 0,
    this.sessionType = SessionType.focus,
    this.focusDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.sessionsCompleted = 0,
    this.linkedTaskId,
  });

  int get totalDurationSeconds {
    switch (sessionType) {
      case SessionType.focus:
        return focusDuration * 60;
      case SessionType.shortBreak:
        return shortBreakDuration * 60;
      case SessionType.longBreak:
        return longBreakDuration * 60;
    }
  }

  double get progress =>
      totalDurationSeconds == 0
          ? 0
          : 1.0 - (remainingSeconds / totalDurationSeconds);

  FocusState copyWith({
    List<FocusSessionModel>? sessions,
    FocusSessionModel? activeSession,
    bool clearActiveSession = false,
    TimerState? timerState,
    int? remainingSeconds,
    int? elapsedSeconds,
    SessionType? sessionType,
    int? focusDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? sessionsCompleted,
    String? linkedTaskId,
    bool clearLinkedTask = false,
  }) {
    return FocusState(
      sessions: sessions ?? this.sessions,
      activeSession:
          clearActiveSession ? null : (activeSession ?? this.activeSession),
      timerState: timerState ?? this.timerState,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      sessionType: sessionType ?? this.sessionType,
      focusDuration: focusDuration ?? this.focusDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      linkedTaskId:
          clearLinkedTask ? null : (linkedTaskId ?? this.linkedTaskId),
    );
  }
}

final focusProvider =
    StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  final hive = ref.read(hiveServiceProvider);
  final firestore = ref.read(firestoreServiceProvider);
  final authUser = ref.watch(authProvider).user;
  return FocusNotifier(hive, firestore, authUser);
});

class FocusNotifier extends StateNotifier<FocusState> {
  final HiveService _hive;
  final FirestoreService _firestore;
  final AuthUserModel? _authUser;
  Timer? _timer;

  FocusNotifier(this._hive, this._firestore, this._authUser)
      : super(const FocusState()) {
    _loadSessions();
  }

  bool get _isCloudUser =>
      _authUser != null && _authUser!.provider != AuthProvider.guest;
  String? get _uid => _authUser?.uid;

  void _loadSessions() {
    final sessions = _hive.getAllFocusSessions();
    state = state.copyWith(sessions: sessions);
  }

  void setDurations({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
  }) {
    state = state.copyWith(
      focusDuration: focusMinutes,
      shortBreakDuration: shortBreakMinutes,
      longBreakDuration: longBreakMinutes,
    );
  }

  void setLinkedTask(String? taskId) {
    if (taskId == null) {
      state = state.copyWith(clearLinkedTask: true);
    } else {
      state = state.copyWith(linkedTaskId: taskId);
    }
  }

  void setSessionType(SessionType type) {
    if (state.timerState == TimerState.running) return;
    final secs = _durationForType(type) * 60;
    state = state.copyWith(
      sessionType: type,
      remainingSeconds: secs,
      elapsedSeconds: 0,
      timerState: TimerState.idle,
    );
  }

  int _durationForType(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return state.focusDuration;
      case SessionType.shortBreak:
        return state.shortBreakDuration;
      case SessionType.longBreak:
        return state.longBreakDuration;
    }
  }

  Future<void> startSession() async {
    if (state.timerState == TimerState.running) return;

    final duration = _durationForType(state.sessionType);
    final session = FocusSessionModel(
      id: const Uuid().v4(),
      linkedTaskId: state.linkedTaskId,
      sessionType: state.sessionType,
      plannedDurationMinutes: duration,
      startTime: DateTime.now(),
    );

    await _hive.saveFocusSession(session);

    state = state.copyWith(
      activeSession: session,
      timerState: TimerState.running,
      remainingSeconds: duration * 60,
      elapsedSeconds: 0,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _completeSession();
      } else {
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
          elapsedSeconds: state.elapsedSeconds + 1,
        );
      }
    });
  }

  void pauseSession() {
    if (state.timerState != TimerState.running) return;
    _timer?.cancel();
    state = state.copyWith(timerState: TimerState.paused);
  }

  void resumeSession() {
    if (state.timerState != TimerState.paused) return;
    state = state.copyWith(timerState: TimerState.running);
    _startTimer();
  }

  Future<void> stopSession() async {
    _timer?.cancel();
    final active = state.activeSession;
    if (active != null) {
      final elapsed = state.elapsedSeconds ~/ 60;
      final completed = active.copyWith(
        actualDurationMinutes: elapsed,
        endTime: DateTime.now(),
        isCompleted: false,
      );
      await _hive.saveFocusSession(completed);
      if (_isCloudUser && _uid != null) {
        _firestore.saveFocusSession(_uid!, completed).catchError((_) {});
      }
      final updated = state.sessions
          .map((s) => s.id == completed.id ? completed : s)
          .toList();
      final isNew = !updated.any((s) => s.id == completed.id);
      state = state.copyWith(
        sessions: isNew ? [...state.sessions, completed] : updated,
        clearActiveSession: true,
        timerState: TimerState.idle,
        remainingSeconds: _durationForType(state.sessionType) * 60,
        elapsedSeconds: 0,
      );
    } else {
      state = state.copyWith(timerState: TimerState.idle);
    }
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    final active = state.activeSession;
    if (active == null) return;

    final duration = _durationForType(state.sessionType);
    final completed = active.copyWith(
      actualDurationMinutes: duration,
      endTime: DateTime.now(),
      isCompleted: true,
    );
    await _hive.saveFocusSession(completed);
    if (_isCloudUser && _uid != null) {
      _firestore.saveFocusSession(_uid!, completed).catchError((_) {});
    }

    final updatedSessions = state.sessions.any((s) => s.id == completed.id)
        ? state.sessions
            .map((s) => s.id == completed.id ? completed : s)
            .toList()
        : [...state.sessions, completed];

    final newSessionsCompleted = state.sessionType == SessionType.focus
        ? state.sessionsCompleted + 1
        : state.sessionsCompleted;

    state = state.copyWith(
      sessions: updatedSessions,
      clearActiveSession: true,
      timerState: TimerState.finished,
      remainingSeconds: 0,
      sessionsCompleted: newSessionsCompleted,
    );
  }

  void resetTimer() {
    if (state.timerState == TimerState.running) return;
    final secs = _durationForType(state.sessionType) * 60;
    state = state.copyWith(
      timerState: TimerState.idle,
      remainingSeconds: secs,
      elapsedSeconds: 0,
    );
  }

  /// Pull from cloud and merge.
  Future<void> syncFromCloud() async {
    if (!_isCloudUser || _uid == null) return;
    final cloudSessions = await _firestore.getAllFocusSessions(_uid!);
    final localSessions = _hive.getAllFocusSessions();

    final merged = <String, FocusSessionModel>{};
    for (final s in localSessions) {
      merged[s.id] = s;
    }
    for (final s in cloudSessions) {
      merged[s.id] = s;
    }

    for (final s in merged.values) {
      await _hive.saveFocusSession(s);
    }

    final cloudIds = cloudSessions.map((s) => s.id).toSet();
    for (final s in localSessions) {
      if (!cloudIds.contains(s.id)) {
        _firestore.saveFocusSession(_uid!, s).catchError((_) {});
      }
    }

    state = state.copyWith(
      sessions: merged.values.toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime)),
    );
  }

  int get todayFocusMinutes {
    final today = DateHelper.toStorageKey(DateHelper.today);
    return state.sessions
        .where((s) =>
            s.isCompleted &&
            s.sessionType == SessionType.focus &&
            DateHelper.toStorageKey(s.startTime) == today)
        .fold(0, (sum, s) => sum + s.actualDurationMinutes);
  }

  int get todaySessionCount {
    final today = DateHelper.toStorageKey(DateHelper.today);
    return state.sessions
        .where((s) =>
            s.isCompleted &&
            s.sessionType == SessionType.focus &&
            DateHelper.toStorageKey(s.startTime) == today)
        .length;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
