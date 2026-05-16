/// Maps merchant keywords to KHARCHA categories.
/// Supports confidence scoring and user-override learning via local prefs.
class MerchantClassifier {
  static const Map<String, String> _keywordMap = {
    // Food & Dining
    'swiggy': 'Food', 'zomato': 'Food', 'dominos': 'Food',
    'domino': 'Food', 'pizza': 'Food', 'mcdonald': 'Food',
    'kfc': 'Food', 'subway': 'Food', 'blinkit': 'Food',
    'dunzo': 'Food', 'zepto': 'Food', 'bigbasket': 'Food',
    'grofers': 'Food', 'instamart': 'Food', 'starbucks': 'Food',
    'chai': 'Food', 'restaurant': 'Food', 'cafe': 'Food',
    'hotel': 'Food', 'dhaba': 'Food', 'tiffin': 'Food',

    // Transport
    'uber': 'Transport', 'ola': 'Transport', 'rapido': 'Transport',
    'metro': 'Transport', 'irctc': 'Transport', 'makemytrip': 'Transport',
    'goibibo': 'Transport', 'yatra': 'Transport', 'bus': 'Transport',
    'petrol': 'Transport', 'fuel': 'Transport', 'parking': 'Transport',
    'toll': 'Transport', 'auto': 'Transport', 'cab': 'Transport',
    'indigo': 'Transport', 'airindia': 'Transport', 'spicejet': 'Transport',

    // Shopping
    'amazon': 'Shopping', 'flipkart': 'Shopping', 'myntra': 'Shopping',
    'ajio': 'Shopping', 'nykaa': 'Shopping', 'meesho': 'Shopping',
    'snapdeal': 'Shopping', 'shopsy': 'Shopping', 'reliance': 'Shopping',
    'dmart': 'Shopping', 'bigmart': 'Shopping', 'walmart': 'Shopping',
    'ikea': 'Shopping', 'lifestyle': 'Shopping', 'zara': 'Shopping',
    'h&m': 'Shopping', 'westside': 'Shopping',

    // Utilities
    'jio': 'Utilities', 'airtel': 'Utilities', 'vi': 'Utilities',
    'bsnl': 'Utilities', 'tata': 'Utilities', 'electricity': 'Utilities',
    'water': 'Utilities', 'gas': 'Utilities', 'broadband': 'Utilities',
    'wifi': 'Utilities', 'recharge': 'Utilities', 'bill': 'Utilities',
    'postpaid': 'Utilities', 'dth': 'Utilities', 'tataplay': 'Utilities',

    // Entertainment
    'netflix': 'Entertainment', 'hotstar': 'Entertainment',
    'prime': 'Entertainment', 'spotify': 'Entertainment',
    'youtube': 'Entertainment', 'zee5': 'Entertainment',
    'sonyliv': 'Entertainment', 'bookmyshow': 'Entertainment',
    'pvr': 'Entertainment', 'inox': 'Entertainment',
    'steam': 'Entertainment', 'playstation': 'Entertainment',

    // Health
    'pharmacy': 'Health', 'medplus': 'Health', 'apollo': 'Health',
    'netmeds': 'Health', '1mg': 'Health', 'pharmeasy': 'Health',
    'hospital': 'Health', 'clinic': 'Health', 'doctor': 'Health',
    'gym': 'Health', 'cult': 'Health', 'healthify': 'Health',

    // Education
    'byju': 'Education', 'unacademy': 'Education', 'udemy': 'Education',
    'coursera': 'Education', 'vedantu': 'Education', 'school': 'Education',
    'college': 'Education', 'university': 'Education', 'fees': 'Education',
    'tuition': 'Education', 'book': 'Education',
  };

  // User overrides: merchant → category (persisted in-memory for session)
  final Map<String, String> _userOverrides = {};

  ClassifyResult classify(String merchantName) {
    final lower = merchantName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9&]'), ' ');

    // Check user overrides first
    for (final entry in _userOverrides.entries) {
      if (lower.contains(entry.key.toLowerCase())) {
        return ClassifyResult(category: entry.value, confidence: 1.0, isUserOverride: true);
      }
    }

    // Check keyword map
    double bestScore = 0;
    String bestCategory = 'Other';

    for (final entry in _keywordMap.entries) {
      if (lower.contains(entry.key)) {
        // Longer keyword = higher confidence
        final score = entry.key.length / lower.length.clamp(1, 100);
        if (score > bestScore) {
          bestScore = score;
          bestCategory = entry.value;
        }
      }
    }

    final confidence = bestScore > 0 ? (0.6 + bestScore * 0.4).clamp(0.0, 1.0) : 0.0;
    return ClassifyResult(
      category: bestCategory,
      confidence: confidence,
      isUserOverride: false,
    );
  }

  /// Learn from user correction
  void learnOverride(String merchantName, String correctedCategory) {
    _userOverrides[merchantName.toLowerCase()] = correctedCategory;
  }
}

class ClassifyResult {
  final String category;
  final double confidence;
  final bool isUserOverride;
  const ClassifyResult({
    required this.category,
    required this.confidence,
    required this.isUserOverride,
  });
  bool get isHighConfidence => confidence >= 0.7;
}
