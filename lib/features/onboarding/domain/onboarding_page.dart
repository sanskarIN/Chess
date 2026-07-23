import 'package:flutter/material.dart';

enum OnboardingPageId {
  welcome(Icons.auto_awesome_outlined),
  computer(Icons.memory_outlined),
  localPlay(Icons.people_alt_outlined),
  friendMatch(Icons.hub_outlined),
  challenges(Icons.calendar_today_outlined),
  rewards(Icons.toll_outlined),
  languages(Icons.translate_outlined),
  privacy(Icons.shield_outlined),
  openSource(Icons.code_outlined),
  ready(Icons.sports_esports_outlined);

  const OnboardingPageId(this.icon);

  final IconData icon;
}
