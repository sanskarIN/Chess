import '../../chess/domain/model/piece_color.dart';

enum LocalActionType { undo, redo, draw }

enum LocalRequestOutcome { applied, approvalRequired, unavailable }

final class LocalActionRequest {
  const LocalActionRequest({
    required this.type,
    required this.requester,
    required this.approver,
  });

  final LocalActionType type;
  final PieceColor requester;
  final PieceColor approver;
}
