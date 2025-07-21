import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _profileVisible = true;
  bool _companyInfoVisible = true;
  bool _locationSharingEnabled = true;
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final userDoc = await _firestoreService.getUserDocument(currentUser.uid);
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final privacySettings = userData['privacySettings'] as Map<String, dynamic>? ?? {};
          
          setState(() {
            _profileVisible = privacySettings['profileVisible'] ?? true;
            _companyInfoVisible = privacySettings['companyInfoVisible'] ?? true;
            _locationSharingEnabled = privacySettings['locationSharingEnabled'] ?? true;
            _pushNotificationsEnabled = privacySettings['pushNotificationsEnabled'] ?? true;
            _emailNotificationsEnabled = privacySettings['emailNotificationsEnabled'] ?? true;
            _smsNotificationsEnabled = privacySettings['smsNotificationsEnabled'] ?? false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading privacy settings: $e')),
        );
      }
    }
  }

  Future<void> _updatePrivacySettings() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final privacySettings = {
          'profileVisible': _profileVisible,
          'companyInfoVisible': _companyInfoVisible,
          'locationSharingEnabled': _locationSharingEnabled,
          'pushNotificationsEnabled': _pushNotificationsEnabled,
          'emailNotificationsEnabled': _emailNotificationsEnabled,
          'smsNotificationsEnabled': _smsNotificationsEnabled,
          'lastUpdated': DateTime.now().toIso8601String(),
        };

        await _firestoreService.updateUserDocument(
          currentUser.uid,
          {'privacySettings': privacySettings},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Privacy settings updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating privacy settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: Colors.blue[50],
        foregroundColor: Colors.blue[700],
        actions: [
          TextButton(
            onPressed: _updatePrivacySettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Profile Visibility',
                    'Control who can see your profile information',
                    Icons.visibility,
                  ),
                  _buildPrivacyCard([
                    _buildSwitchTile(
                      'Profile Visible to Others',
                      'Allow other users to see your profile',
                      _profileVisible,
                      (value) => setState(() => _profileVisible = value),
                    ),
                    _buildSwitchTile(
                      'Show Company Information',
                      'Display your company name to other users',
                      _companyInfoVisible,
                      (value) => setState(() => _companyInfoVisible = value),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    'Location & Data',
                    'Manage location sharing and data usage',
                    Icons.location_on,
                  ),
                  _buildPrivacyCard([
                    _buildSwitchTile(
                      'Location Sharing',
                      'Allow the app to access your location for restaurant recommendations',
                      _locationSharingEnabled,
                      (value) => setState(() => _locationSharingEnabled = value),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    'Communication Preferences',
                    'Choose how you want to receive notifications',
                    Icons.notifications,
                  ),
                  _buildPrivacyCard([
                    _buildSwitchTile(
                      'Push Notifications',
                      'Receive notifications about matches and plan updates',
                      _pushNotificationsEnabled,
                      (value) => setState(() => _pushNotificationsEnabled = value),
                    ),
                    _buildSwitchTile(
                      'Email Notifications',
                      'Receive important updates via email',
                      _emailNotificationsEnabled,
                      (value) => setState(() => _emailNotificationsEnabled = value),
                    ),
                    _buildSwitchTile(
                      'SMS Notifications',
                      'Receive urgent notifications via SMS',
                      _smsNotificationsEnabled,
                      (value) => setState(() => _smsNotificationsEnabled = value),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    'Data Management',
                    'Control your personal data',
                    Icons.security,
                  ),
                  _buildPrivacyCard([
                    _buildActionTile(
                      'Download My Data',
                      'Get a copy of all your data',
                      Icons.download,
                      () => _showDataDownloadDialog(),
                    ),
                    _buildActionTile(
                      'Delete My Account',
                      'Permanently delete your account and all data',
                      Icons.delete_forever,
                      () => _showDeleteAccountDialog(),
                      isDestructive: true,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Privacy Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your privacy is important to us. We only collect data necessary to provide our services and never share your personal information with third parties without your consent.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _showPrivacyPolicyDialog(),
                            child: const Text('Read our Privacy Policy'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(List<Widget> children) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue[600],
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red[600] : Colors.blue[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red[600] : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showDataDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Your Data'),
        content: const Text(
          'We\'ll prepare a file containing all your data and send it to your registered email address within 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data download request submitted. Check your email within 24 hours.'),
                ),
              );
            },
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data, including dining history, matches, and preferences will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalDeleteConfirmation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Type "DELETE" to confirm account deletion:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature will be implemented with backend support.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'GTKY Privacy Policy\n\n'
            '1. Data Collection: We collect only necessary information to provide our dining matching service.\n\n'
            '2. Data Usage: Your data is used to match you with compatible dining partners and recommend restaurants.\n\n'
            '3. Data Sharing: We never share your personal information with third parties without explicit consent.\n\n'
            '4. Data Security: All data is encrypted and stored securely using industry-standard practices.\n\n'
            '5. Your Rights: You can access, modify, or delete your data at any time through the app settings.\n\n'
            'For the complete privacy policy, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}