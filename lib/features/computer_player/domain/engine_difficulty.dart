enum EngineDifficulty {
  beginner,
  intermediate,
  expert,
  grandmaster;

  bool get warnsAboutPerformance => this == EngineDifficulty.grandmaster;
}
