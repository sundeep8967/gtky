import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/safety_service.dart';
import '../../services/auth_service.dart';
import '../../models/blocked_user_model.dart';
import '../../models/report_model.dart';

class SafetySettingsScreen extends StatefulWidget {
  const SafetySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SafetySettingsScreen> createState() => _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends State<SafetySettingsScreen> {
  final SafetyService _safetyService = SafetyService();
  final AuthService _authService = AuthService();
  
  List<BlockedUserModel> _blockedUsers = [];
  List<ReportModel> _userReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final blockedUsers = await _safetyService.getBlockedUsers(currentUser.uid);
        final reports = await _safetyService.getUserReports(currentUser.uid);
        
        if (mounted) {
          setState(() {
            _blockedUsers = blockedUsers;
            _userReports = reports;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unblockUser(BlockedUserModel blockedUser) async {
    try {
      await _safetyService.unblockUser(
        blockerId: blockedUser.blockerId,
        blockedUserId: blockedUser.blockedUserId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unblocked successfully')),
        );
        _loadData(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unblock user: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _launchEmergencyNumber(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety & Privacy'),
        backgroundColor: Colors.blue[50],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Safety Guidelines Section
                  _buildSectionCard(
                    title: 'Safety Guidelines',
                    icon: Icons.security,
                    color: Colors.green,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _safetyService.getSafetyGuidelines()
                          .map((guideline) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(guideline)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Emergency Contacts Section
                  _buildSectionCard(
                    title: 'Emergency Contacts',
                    icon: Icons.emergency,
                    color: Colors.red,
                    child: Column(
                      children: _safetyService.getEmergencyContacts()
                          .entries
                          .map((entry) => ListTile(
                                leading: Icon(Icons.phone, color: Colors.red[600]),
                                title: Text(entry.key),
                                trailing: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () => _launchEmergencyNumber(entry.value),
                              ))
                          .toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Blocked Users Section
                  _buildSectionCard(
                    title: 'Blocked Users (${_blockedUsers.length})',
                    icon: Icons.block,
                    color: Colors.orange,
                    child: _blockedUsers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No blocked users',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Column(
                            children: _blockedUsers.map((blockedUser) {
                              return ListTile(
                                leading: const Icon(Icons.person_off),
                                title: Text('User ID: ${blockedUser.blockedUserId}'),
                                subtitle: Text(
                                  'Blocked on ${blockedUser.createdAt.day}/${blockedUser.createdAt.month}/${blockedUser.createdAt.year}',
                                ),
                                trailing: TextButton(
                                  onPressed: () => _unblockUser(blockedUser),
                                  child: const Text('Unblock'),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Reports Section
                  _buildSectionCard(
                    title: 'My Reports (${_userReports.length})',
                    icon: Icons.report,
                    color: Colors.purple,
                    child: _userReports.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No reports submitted',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Column(
                            children: _userReports.take(5).map((report) {
                              return ListTile(
                                leading: Icon(
                                  Icons.report_problem,
                                  color: _getStatusColor(report.status),
                                ),
                                title: Text(report.reason),
                                subtitle: Text(
                                  'Status: ${report.status.toUpperCase()}\n'
                                  'Submitted: ${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                                ),
                                isThreeLine: true,
                              );
                            }).toList(),
                          ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Privacy Notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Privacy Notice',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your safety is our priority. All reports are reviewed by our moderation team. '
                          'We take appropriate action based on our community guidelines.',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}