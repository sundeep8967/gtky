import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/subscription_service.dart';
import '../../services/auth_service.dart';
import '../../models/referral_model.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({Key? key}) : super(key: key);

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _referralCodeController = TextEditingController();
  
  List<ReferralModel> _userReferrals = [];
  String? _userReferralCode;
  bool _isLoading = true;
  bool _isGeneratingCode = false;
  bool _isApplyingCode = false;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final referrals = await _subscriptionService.getUserReferrals(currentUser.uid);
        
        if (mounted) {
          setState(() {
            _userReferrals = referrals;
            // Get the most recent active referral code
            _userReferralCode = referrals
                .where((r) => r.status == ReferralStatus.pending && !r.isExpired)
                .isNotEmpty
                ? referrals
                    .where((r) => r.status == ReferralStatus.pending && !r.isExpired)
                    .first
                    .referralCode
                : null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading referral data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateReferralCode() async {
    setState(() {
      _isGeneratingCode = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final referral = await _subscriptionService.generateReferralCode(currentUser.uid);
        
        if (mounted) {
          setState(() {
            _userReferralCode = referral.referralCode;
          });
          _loadReferralData(); // Refresh the list
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Referral code generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate referral code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingCode = false;
        });
      }
    }
  }

  Future<void> _applyReferralCode() async {
    final code = _referralCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a referral code')),
      );
      return;
    }

    setState(() {
      _isApplyingCode = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final success = await _subscriptionService.applyReferralCode(currentUser.uid, code);
        
        if (mounted) {
          if (success) {
            _referralCodeController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Referral code applied successfully! You\'ve earned credits.'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid or expired referral code'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying referral code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingCode = false;
        });
      }
    }
  }

  void _copyReferralCode() {
    if (_userReferralCode != null) {
      Clipboard.setData(ClipboardData(text: _userReferralCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral code copied to clipboard!')),
      );
    }
  }

  void _shareReferralCode() {
    if (_userReferralCode != null) {
      // In a real app, you would use the share package
      final message = 'Join me on GTKY - the best social dining app! Use my referral code $_userReferralCode and get ₹${SubscriptionService.referralCreditAmount} credit. Download now!';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share message: $message'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referrals & Rewards'),
        backgroundColor: Colors.purple[50],
        foregroundColor: Colors.purple[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Referral program info
                  _buildReferralInfoCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Your referral code section
                  _buildYourReferralCodeSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Apply referral code section
                  _buildApplyReferralCodeSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Referral history
                  _buildReferralHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildReferralInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.card_giftcard,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Earn ₹${SubscriptionService.referralCreditAmount.toStringAsFixed(0)} for each friend!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Share your referral code with friends. When they sign up and complete their first dining plan, you both get credits!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildYourReferralCodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Referral Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_userReferralCode != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _userReferralCode!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.purple[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: _copyReferralCode,
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy code',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareReferralCode,
                      icon: const Icon(Icons.share),
                      label: const Text('Share Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'You don\'t have an active referral code yet.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGeneratingCode ? null : _generateReferralCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                  ),
                  child: _isGeneratingCode
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Generate Referral Code'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplyReferralCodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have a Referral Code?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _referralCodeController,
              decoration: InputDecoration(
                labelText: 'Enter referral code',
                hintText: 'e.g., ABC12345',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  onPressed: _isApplyingCode ? null : _applyReferralCode,
                  icon: _isApplyingCode
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _applyReferralCode(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralHistorySection() {
    final completedReferrals = _userReferrals.where((r) => r.isCompleted).length;
    final totalEarnings = _userReferrals
        .where((r) => r.isCompleted)
        .fold(0.0, (sum, r) => sum + r.creditAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referral Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '$completedReferrals',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'Successful\nReferrals',
                        style: TextStyle(color: Colors.green[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '₹${totalEarnings.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Text(
                        'Total\nEarnings',
                        style: TextStyle(color: Colors.blue[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (_userReferrals.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Referral History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          ..._userReferrals.map((referral) {
            return Card(
              child: ListTile(
                leading: Icon(
                  _getReferralStatusIcon(referral.status),
                  color: _getReferralStatusColor(referral.status),
                ),
                title: Text('Code: ${referral.referralCode}'),
                subtitle: Text(
                  'Created: ${referral.createdAt.day}/${referral.createdAt.month}/${referral.createdAt.year}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (referral.isCompleted) ...[
                      Text(
                        '₹${referral.creditAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                    Text(
                      referral.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getReferralStatusColor(referral.status),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  IconData _getReferralStatusIcon(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return Icons.hourglass_empty;
      case ReferralStatus.completed:
        return Icons.check_circle;
      case ReferralStatus.expired:
        return Icons.cancel;
    }
  }

  Color _getReferralStatusColor(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return Colors.orange;
      case ReferralStatus.completed:
        return Colors.green;
      case ReferralStatus.expired:
        return Colors.red;
    }
  }
}