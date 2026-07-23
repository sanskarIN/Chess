import 'package:flutter/material.dart';

enum GuideTopicId {
  howChessWorks,
  pieces,
  check,
  checkmate,
  stalemate,
  castling,
  enPassant,
  promotion,
  draws,
  timeControls,
  computer,
  difficulty,
  local,
  friend,
  teamCodes,
  daily,
  coins,
  hints,
  saved,
  importExport,
  accessibility,
  settings,
  developer,
  privacy,
  openSource,
  troubleshooting,
  upcoming,
}

final class GuideTopic {
  const GuideTopic({required this.id, required this.icon});

  final GuideTopicId id;
  final IconData icon;
}
