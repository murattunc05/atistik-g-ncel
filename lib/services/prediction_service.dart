import 'dart:math';

class PredictionService {
  static List<Map<String, dynamic>> calculateWinningProbability(List<Map<String, dynamic>> horses) {
    if (horses.isEmpty) return [];

    // Deep copy to avoid modifying the original list directly during calculation
    List<Map<String, dynamic>> processedHorses = List.from(horses.map((h) => Map<String, dynamic>.from(h)));
    
    double maxEarnings = 0;
    
    // First pass: Calculate base scores and find max earnings
    for (var horse in processedHorses) {
      double score = 0;
      
      // Parse races
      List<dynamic> races = horse['races'] ?? [];
      int totalRaces = races.length;
      int wins = 0;
      int places = 0; // Top 4
      
      if (totalRaces > 0) {
        for (var race in races) {
          try {
            String posStr = race['position'].toString().replaceAll('.', '');
            int pos = int.tryParse(posStr) ?? 99;
            
            if (pos == 1) wins++;
            if (pos <= 4) places++;
          } catch (e) {
            // Ignore parse errors
          }
        }
        
        double winRate = wins / totalRaces;
        double placeRate = places / totalRaces;
        
        score += winRate * 40; // 40% weight
        score += placeRate * 20; // 20% weight
      }
      
      // Recent Form (Last 5)
      var recentRaces = races.take(5).toList();
      double recentScore = 0;
      if (recentRaces.isNotEmpty) {
        for (int i = 0; i < recentRaces.length; i++) {
          try {
            String posStr = recentRaces[i]['position'].toString().replaceAll('.', '');
            int pos = int.tryParse(posStr) ?? 99;
            
            double posScore = 0;
            if (pos == 1) posScore = 10;
            else if (pos == 2) posScore = 8;
            else if (pos == 3) posScore = 6;
            else if (pos == 4) posScore = 4;
            else posScore = 1;
            
            // Weight: Most recent has highest weight (5, 4, 3, 2, 1) / 15
            double weight = (5 - i) / 15;
            recentScore += posScore * weight;
          } catch (e) {
            // Ignore
          }
        }
        score += (recentScore / 10) * 25; // 25% weight
      }
      
      // Earnings
      double earnings = 0;
      try {
        String earningsStr = (horse['prize'] ?? '0').toString()
            .replaceAll('.', '')
            .replaceAll(',', '')
            .replaceAll(' t', '')
            .trim();
        earnings = double.tryParse(earningsStr) ?? 0;
      } catch (e) {
        earnings = 0;
      }
      
      if (earnings > maxEarnings) maxEarnings = earnings;
      
      horse['_raw_earnings'] = earnings;
      horse['_raw_score'] = score;
    }
    
    if (maxEarnings == 0) maxEarnings = 1;
    
    // Second pass: Normalize earnings and calculate final probability
    double totalScore = 0;
    for (var horse in processedHorses) {
      double earnings = horse['_raw_earnings'] as double;
      double earningsScore = earnings / maxEarnings;
      
      double currentScore = horse['_raw_score'] as double;
      currentScore += earningsScore * 15; // 15% weight
      
      horse['_raw_score'] = currentScore;
      totalScore += currentScore;
    }
    
    // Final pass: Assign probabilities
    for (var horse in processedHorses) {
      double prob = 0;
      if (totalScore > 0) {
        prob = ((horse['_raw_score'] as double) / totalScore) * 100;
      } else {
        prob = 100 / processedHorses.length;
      }
      
      horse['winningProbability'] = prob.toStringAsFixed(1);
      
      // Cleanup
      horse.remove('_raw_earnings');
      horse.remove('_raw_score');
    }
    
    // Sort by probability descending
    processedHorses.sort((a, b) {
      double probA = double.parse(a['winningProbability']);
      double probB = double.parse(b['winningProbability']);
      return probB.compareTo(probA);
    });

    return processedHorses;
  }
}
