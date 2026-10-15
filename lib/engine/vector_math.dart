import 'dart:math';

class VectorMath {
  static double cosineSimilarity(List<double> vA, List<double> vB) {
    if (vA.length != vB.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vA.length; i++) {
      dotProduct += vA[i] * vB[i];
      normA += vA[i] * vA[i];
      normB += vB[i] * vB[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
