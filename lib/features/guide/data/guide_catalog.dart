import 'package:flutter/material.dart';

import '../domain/guide_topic.dart';

abstract final class GuideCatalog {
  static const List<GuideTopic> topics = <GuideTopic>[
    GuideTopic(
      id: GuideTopicId.howChessWorks,
      icon: Icons.sports_esports_outlined,
    ),
    GuideTopic(id: GuideTopicId.pieces, icon: Icons.category_outlined),
    GuideTopic(id: GuideTopicId.check, icon: Icons.warning_amber),
    GuideTopic(id: GuideTopicId.checkmate, icon: Icons.emoji_events_outlined),
    GuideTopic(id: GuideTopicId.stalemate, icon: Icons.handshake_outlined),
    GuideTopic(id: GuideTopicId.castling, icon: Icons.security_outlined),
    GuideTopic(id: GuideTopicId.enPassant, icon: Icons.swap_horiz),
    GuideTopic(id: GuideTopicId.promotion, icon: Icons.upgrade),
    GuideTopic(id: GuideTopicId.draws, icon: Icons.balance),
    GuideTopic(id: GuideTopicId.timeControls, icon: Icons.timer_outlined),
    GuideTopic(id: GuideTopicId.computer, icon: Icons.memory_outlined),
    GuideTopic(id: GuideTopicId.difficulty, icon: Icons.tune),
    GuideTopic(id: GuideTopicId.local, icon: Icons.people_outline),
    GuideTopic(id: GuideTopicId.friend, icon: Icons.hub_outlined),
    GuideTopic(id: GuideTopicId.teamCodes, icon: Icons.pin_outlined),
    GuideTopic(id: GuideTopicId.daily, icon: Icons.calendar_today_outlined),
    GuideTopic(id: GuideTopicId.coins, icon: Icons.paid_outlined),
    GuideTopic(id: GuideTopicId.hints, icon: Icons.lightbulb_outline),
    GuideTopic(id: GuideTopicId.saved, icon: Icons.bookmark_outline),
    GuideTopic(id: GuideTopicId.importExport, icon: Icons.import_export),
    GuideTopic(id: GuideTopicId.accessibility, icon: Icons.accessibility_new),
    GuideTopic(id: GuideTopicId.settings, icon: Icons.settings_outlined),
    GuideTopic(id: GuideTopicId.developer, icon: Icons.developer_mode),
    GuideTopic(id: GuideTopicId.privacy, icon: Icons.privacy_tip_outlined),
    GuideTopic(id: GuideTopicId.openSource, icon: Icons.code),
    GuideTopic(id: GuideTopicId.troubleshooting, icon: Icons.build_outlined),
    GuideTopic(id: GuideTopicId.upcoming, icon: Icons.upcoming_outlined),
  ];
}
