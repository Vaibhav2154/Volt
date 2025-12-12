class ApiConstants {
  ApiConstants._();
  
  // Base URL - Update this with your server URL
  // For Android Emulator, use 10.0.2.2 to access host machine's localhost
  // For physical device, use your machine's IP address
  static const String baseUrl = 'http://172.16.41.26:8000';
  // static const String baseUrl = 'http://10.0.2.2:8000';
  // static const String baseUrl = 'https://volt-wzwo.onrender.com';
  // Auth endpoints
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login/json';
  static const String getCurrentUserEndpoint = '/auth/me';
  
  // Transaction endpoints
  static const String transactionsEndpoint = '/transactions';
  static const String transactionsDateRangeEndpoint = '/transactions/date-range';
  
  // OCR endpoints
  static const String ocrImagesToTextEndpoint = '/ocr/images-to-text';
  
  // Email configuration endpoints
  static const String emailConfigSetupAppPasswordEndpoint = '/email-config/setup-app-password';
  static const String emailConfigStatusEndpoint = '/email-config/status';
  static const String emailConfigDisableEndpoint = '/email-config/disable';
  static const String emailConfigUpdateAppPasswordEndpoint = '/email-config/update-app-password';
  
  // Email transactions endpoints
  static const String emailTransactionsQueueStatsEndpoint = '/email-transactions/queue/stats';
  static const String emailTransactionsQueueJobEndpoint = '/email-transactions/queue/job';
  static const String emailTransactionsQueueManualEndpoint = '/email-transactions/queue/manual';
  static const String emailTransactionsRecentEndpoint = '/email-transactions/transactions/recent';
  static const String emailTransactionsByBankEndpoint = '/email-transactions/transactions/by-bank';
  static const String emailTransactionsHealthEndpoint = '/email-transactions/health';
  
  // Lean week endpoints
  static const String leanWeekAnalysisEndpoint = '/lean-week/analysis';
  static const String leanWeekForecastEndpoint = '/lean-week/forecast';
  static const String leanWeekSmoothingRecommendationsEndpoint = '/lean-week/smoothing-recommendations';
  
  // Goal endpoints
  static const String goalsEndpoint = '/goals';
  static const String goalsProgressEndpoint = '/goals/progress';
  
  // Simulation endpoints
  static const String simulationBaseEndpoint = '/api/users';
  static String simulationBehaviorEndpoint(int userId) => '$simulationBaseEndpoint/$userId/behavior';
  static String simulationEndpoint(int userId) => '$simulationBaseEndpoint/$userId/simulate';
  static String simulationEnhancedEndpoint(int userId) => '$simulationBaseEndpoint/$userId/simulate/enhanced';
  static String simulationCompareEndpoint(int userId) => '$simulationBaseEndpoint/$userId/simulate/compare';
  static String simulationCompareEnhancedEndpoint(int userId) => '$simulationBaseEndpoint/$userId/simulate/compare/enhanced';
  static String simulationReallocateEndpoint(int userId) => '$simulationBaseEndpoint/$userId/simulate/reallocate';
  static String simulationProjectEndpoint(int userId) => '$simulationBaseEndpoint/$userId/simulate/project';
  static String simulationBehaviorSummaryEndpoint(int userId) => '$simulationBaseEndpoint/$userId/behavior/summary';
  
  // Gamification endpoints
  static const String gamificationProfileEndpoint = '/gamification/profile';
  static const String gamificationFeedEndpoint = '/gamification/feed';
  
  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
}

  