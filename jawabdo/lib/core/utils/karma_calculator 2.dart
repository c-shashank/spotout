class KarmaCalculator {
  KarmaCalculator._();

  static int calculate({
    required int issuesFiled,
    required int upvotesReceived,
    required int commentsWritten,
    required int issuesResolved,
  }) {
    return (issuesFiled * 10) +
        (upvotesReceived * 2) +
        (commentsWritten * 1) +
        (issuesResolved * 25);
  }

  static String tierLabel(int karma) {
    if (karma >= 500) return 'Jawab Do Champion';
    if (karma >= 100) return 'Active Citizen';
    return 'Aware Citizen';
  }

  static int nextTierThreshold(int karma) {
    if (karma < 100) return 100;
    if (karma < 500) return 500;
    return 500; // max tier
  }

  static double tierProgress(int karma) {
    if (karma >= 500) return 1.0;
    if (karma >= 100) return (karma - 100) / (500 - 100);
    return karma / 100.0;
  }
}
