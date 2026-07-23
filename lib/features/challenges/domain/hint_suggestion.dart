import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/position.dart';
import 'reward_wallet.dart';

final class HintSuggestion {
  const HintSuggestion({required this.move, required this.explanationKey});

  final Move move;
  final String explanationKey;
}

abstract interface class HintService {
  Future<HintSuggestion> generate(Position position);
}

final class HintRequestResult {
  const HintRequestResult({required this.suggestion, required this.purchase});

  final HintSuggestion suggestion;
  final HintPurchase purchase;
}
