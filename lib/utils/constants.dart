class AppConstants {
  // App Info
  static const String appName = 'GTKY';
  static const String appFullName = 'Get To Know You';
  static const String appVersion = '1.0.0';

  // Colors
  static const int primaryColorValue = 0xFF6B73FF;
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String restaurantsCollection = 'restaurants';
  static const String diningPlansCollection = 'dining_plans';
  static const String matchesCollection = 'matches';
  static const String ratingsCollection = 'ratings';

  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String lastLocationKey = 'last_location';

  // Default Values
  static const int defaultGroupSize = 4;
  static const double defaultDiscountPercentage = 15.0;
  static const double defaultSearchRadius = 5.0; // km
  static const int defaultTrustScore = 5;

  // Validation
  static const int minAge = 18;
  static const int maxAge = 100;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Time Constants
  static const int minPlanTimeMinutes = 30;
  static const int maxPlanTimeHours = 8;
  static const int arrivalGracePeriodMinutes = 15;

  // LinkedIn OAuth (will be configured later)
  static const String linkedInClientId = 'YOUR_LINKEDIN_CLIENT_ID';
  static const String linkedInClientSecret = 'YOUR_LINKEDIN_CLIENT_SECRET';
  static const String linkedInRedirectUri = 'YOUR_REDIRECT_URI';

  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection';
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String authErrorMessage = 'Authentication failed. Please try again.';
  static const String locationErrorMessage = 'Location access is required for this feature';
}