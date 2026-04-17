class KarmaCalculator {
  KarmaCalculator._();

  static String tierLabel(int karma) {
    if (karma >= 500) return 'Jawab Do Champion';
    if (karma >= 150) return 'Active Citizen';
    return 'Aware Citizen';
  }

  static int nextTierThreshold(int karma) {
    if (karma < 150) return 150;
    if (karma < 500) return 500;
    return 500;
  }

  static double tierProgress(int karma) {
    if (karma <= 0) return 0;
    if (karma < 150) {
      return (karma / 150).clamp(0, 1).toDouble();
    }
    if (karma < 500) {
      return ((karma - 150) / 350).clamp(0, 1).toDouble();
    }
    return 1;
  }
}
