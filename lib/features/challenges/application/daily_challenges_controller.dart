import 'package:flutter/foundation.dart';

import '../../chess/domain/model/position.dart';
import '../data/challenge_repository.dart';
import '../data/deterministic_challenge_generator.dart';
import '../domain/challenge_dashboard.dart';
import '../domain/challenge_event.dart';
import '../domain/hint_suggestion.dart';
import '../domain/local_date.dart';
import '../domain/reward_wallet.dart';

typedef ChallengeNow = DateTime Function();

final class DailyChallengesController extends ChangeNotifier {
  DailyChallengesController({
    required this.repository,
    required this.generator,
    required this.hintService,
    ChallengeNow? now,
  }) : _now = now ?? DateTime.now;

  final ChallengeRepository repository;
  final DeterministicChallengeGenerator generator;
  final HintService hintService;
  final ChallengeNow _now;

  ChallengeDashboard? _dashboard;
  LocalDate? _simulatedDate;
  String? _errorCode;
  String? _claimingChallengeId;
  bool _loading = false;
  bool _hintInProgress = false;
  bool _closed = false;

  ChallengeDashboard? get dashboard => _dashboard;
  LocalDate? get simulatedDate => _simulatedDate;
  String? get errorCode => _errorCode;
  String? get claimingChallengeId => _claimingChallengeId;
  bool get isLoading => _loading;
  bool get hintInProgress => _hintInProgress;

  LocalDate get effectiveDate => _simulatedDate ?? LocalDate.fromLocal(_now());

  Duration get untilRefresh {
    if (_simulatedDate != null) {
      return const Duration(hours: 24);
    }
    final Duration remaining = effectiveDate.nextMidnight.difference(_now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> initialize() async {
    if (_dashboard != null || _loading) {
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _errorCode = null;
    _notify();
    try {
      final DateTime current = _now();
      final LocalDate date = effectiveDate;
      _dashboard = await repository.load(
        date: date,
        definitions: generator.generate(date),
        now: current,
      );
    } on Object {
      _errorCode = 'challenge_load_failed';
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> refreshIfDateChanged() async {
    if (_simulatedDate == null &&
        _dashboard?.date != LocalDate.fromLocal(_now())) {
      await refresh();
    }
  }

  Future<void> recordEvent(ChallengeEvent event) async {
    try {
      final DateTime current = _now();
      final LocalDate date = effectiveDate;
      _dashboard = await repository.recordEvent(
        date: date,
        definitions: generator.generate(date),
        event: event,
        now: current,
      );
      _errorCode = null;
    } on Object {
      _errorCode = 'challenge_progress_failed';
    }
    _notify();
  }

  Future<bool> claim(String challengeId) async {
    if (_claimingChallengeId != null) {
      return false;
    }
    _claimingChallengeId = challengeId;
    _errorCode = null;
    _notify();
    try {
      final DateTime current = _now();
      final LocalDate date = effectiveDate;
      final ClaimRewardResult result = await repository.claim(
        date: date,
        definitions: generator.generate(date),
        challengeId: challengeId,
        now: current,
      );
      _dashboard = result.dashboard;
      return result.newlyClaimed;
    } on EconomyFailure catch (failure) {
      _errorCode = failure.code;
      return false;
    } on Object {
      _errorCode = 'challenge_claim_failed';
      return false;
    } finally {
      _claimingChallengeId = null;
      _notify();
    }
  }

  Future<HintRequestResult> requestHint({
    required Position position,
    required HintPaymentMethod paymentMethod,
    String? requestId,
  }) async {
    if (_hintInProgress) {
      throw const EconomyFailure('hint_in_progress');
    }
    _hintInProgress = true;
    _errorCode = null;
    _notify();
    try {
      final HintSuggestion suggestion = await hintService.generate(position);
      final DateTime current = _now();
      final HintPurchase purchase = await repository.purchaseHint(
        method: paymentMethod,
        requestId:
            requestId ?? 'hint-${current.toUtc().microsecondsSinceEpoch}',
        now: current,
      );
      final LocalDate date = effectiveDate;
      try {
        _dashboard = await repository.load(
          date: date,
          definitions: generator.generate(date),
          now: current,
        );
      } on Object {
        final ChallengeDashboard? previous = _dashboard;
        if (previous != null) {
          _dashboard = ChallengeDashboard(
            date: previous.date,
            today: previous.today,
            history: previous.history,
            wallet: purchase.wallet,
          );
        }
      }
      return HintRequestResult(suggestion: suggestion, purchase: purchase);
    } on EconomyFailure catch (failure) {
      _errorCode = failure.code;
      rethrow;
    } on Object {
      _errorCode = 'hint_generation_failed';
      rethrow;
    } finally {
      _hintInProgress = false;
      _notify();
    }
  }

  Future<void> simulateDate(LocalDate? date) async {
    _simulatedDate = date;
    await refresh();
  }

  Future<void> resetCurrentDate() async {
    final DateTime current = _now();
    final LocalDate date = effectiveDate;
    _dashboard = await repository.resetDate(
      date: date,
      definitions: generator.generate(date),
      now: current,
    );
    _notify();
  }

  Future<List<RewardLedgerEntry>> readLedger() {
    return repository.readLedger();
  }

  Future<LedgerIntegrityReport> verifyLedgerIntegrity() {
    return repository.verifyLedgerIntegrity();
  }

  void clearError() {
    _errorCode = null;
    _notify();
  }

  void _notify() {
    if (!_closed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
