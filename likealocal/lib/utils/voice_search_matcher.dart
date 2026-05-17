import '../models/place.dart';

class VoiceSearchMatcher {
  const VoiceSearchMatcher._();

  static String normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static int levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;

        final deleteCost = matrix[i - 1][j] + 1;
        final insertCost = matrix[i][j - 1] + 1;
        final replaceCost = matrix[i - 1][j - 1] + cost;

        matrix[i][j] = [
          deleteCost,
          insertCost,
          replaceCost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  static double similarityScore(String input, String candidate) {
    final cleanInput = normalize(input);
    final cleanCandidate = normalize(candidate);

    if (cleanInput.isEmpty || cleanCandidate.isEmpty) return 0;

    if (cleanCandidate.contains(cleanInput)) return 1.0;
    if (cleanInput.contains(cleanCandidate)) return 0.95;

    final distance = levenshteinDistance(cleanInput, cleanCandidate);
    final maxLength = cleanInput.length > cleanCandidate.length
        ? cleanInput.length
        : cleanCandidate.length;

    return 1 - (distance / maxLength);
  }

  static String getBestMatch(
    String spokenText,
    List<Place> places, {
    double threshold = 0.60,
  }) {
    final cleanSpoken = normalize(spokenText);

    if (cleanSpoken.isEmpty) return spokenText;

    final candidates = <String>{};

    for (final place in places) {
      final placeName = place.name.trim();
      final category = place.category.trim();

      if (placeName.isNotEmpty) {
        candidates.add(placeName);
      }

      if (category.isNotEmpty) {
        candidates.add(category);
      }

      // Useful combined candidate:
      // Example: "Yatta Cafe" can match "yata cafe" better.
      if (placeName.isNotEmpty && category.isNotEmpty) {
        candidates.add('$placeName $category');
      }
    }

    String bestMatch = spokenText;
    double bestScore = 0;

    for (final candidate in candidates) {
      final score = similarityScore(cleanSpoken, candidate);

      if (score > bestScore) {
        bestScore = score;
        bestMatch = candidate;
      }
    }

    if (bestScore >= threshold) {
      return bestMatch;
    }

    return spokenText;
  }
}
