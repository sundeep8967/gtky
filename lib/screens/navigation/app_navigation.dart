import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../plans/plan_discovery_screen.dart';
import '../restaurants/restaurant_discovery_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/privacy_settings_screen.dart';
import '../social/social_features_screen.dart';
import '../smart_features/smart_recommendations_screen.dart';
import '../premium/premium_upgrade_screen.dart';

class AppNavigation {
  static const String home = '/home';
  static const String planDiscovery = '/plan-discovery';
  static const String restaurantDiscovery = '/restaurant-discovery';
  static const String notifications = '/notifications';
  static const String privacySettings = '/privacy-settings';
  static const String socialFeatures = '/social-features';
  static const String smartRecommendations = '/smart-recommendations';
  static const String premiumUpgrade = '/premium-upgrade';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomeScreen(),
    planDiscovery: (context) => const PlanDiscoveryScreen(),
    restaurantDiscovery: (context) => const RestaurantDiscoveryScreen(),
    notifications: (context) => const NotificationsScreen(),
    privacySettings: (context) => const PrivacySettingsScreen(),
    socialFeatures: (context) => const SocialFeaturesScreen(),
    smartRecommendations: (context) => const SmartRecommendationsScreen(),
    premiumUpgrade: (context) => const PremiumUpgradeScreen(),
  };

  static void navigateToPrivacySettings(BuildContext context) {
    Navigator.pushNamed(context, privacySettings);
  }

  static void navigateToSocialFeatures(BuildContext context) {
    Navigator.pushNamed(context, socialFeatures);
  }

  static void navigateToSmartRecommendations(BuildContext context) {
    Navigator.pushNamed(context, smartRecommendations);
  }

  static void navigateToPremiumUpgrade(BuildContext context) {
    Navigator.pushNamed(context, premiumUpgrade);
  }

  static void showFeatureBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'App Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFeatureTile(
                    context,
                    icon: Icons.psychology,
                    title: 'Smart Recommendations',
                    subtitle: 'AI-powered restaurant and timing suggestions',
                    onTap: () {
                      Navigator.pop(context);
                      navigateToSmartRecommendations(context);
                    },
                  ),
                  _buildFeatureTile(
                    context,
                    icon: Icons.people,
                    title: 'Social Features',
                    subtitle: 'Share memories and connect with dining partners',
                    onTap: () {
                      Navigator.pop(context);
                      navigateToSocialFeatures(context);
                    },
                  ),
                  _buildFeatureTile(
                    context,
                    icon: Icons.security,
                    title: 'Privacy Settings',
                    subtitle: 'Control your data and privacy preferences',
                    onTap: () {
                      Navigator.pop(context);
                      navigateToPrivacySettings(context);
                    },
                  ),
                  _buildFeatureTile(
                    context,
                    icon: Icons.star,
                    title: 'Premium Features',
                    subtitle: 'Unlock advanced matching and priority booking',
                    onTap: () {
                      Navigator.pop(context);
                      navigateToPremiumUpgrade(context);
                    },
                  ),
                  _buildFeatureTile(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage your notification preferences',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, notifications);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}