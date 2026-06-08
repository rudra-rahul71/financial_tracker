import 'package:financial_tracker/features/auth/presentation/pages/sign_in.dart';
import 'package:financial_tracker/core/database/db_service.dart';
import 'package:financial_tracker/core/widgets/page_header.dart';
import 'package:financial_tracker/features/accounts/domain/entities/account.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

SignedOutAction _signOut() {
  return SignedOutAction((context) async {
    await DatabaseService.instance.clearAllData();
    if (context.mounted) {
      context.go('/auth/sign-in');
    }
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  List<Account> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final accounts = await DatabaseService.instance.getAccounts();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return SignInPage();
    }

    final theme = Theme.of(context);
    final displayName = _user!.displayName ?? _user!.email?.split('@').first ?? 'User';
    final email = _user!.email ?? '';
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfileData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  showBackButton: true,
                  header: 'Profile & Settings',
                  sub: 'Manage bank connections and profile details',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Header Section (Avatar, Name, Email)
                      const SizedBox(height: 10),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primary.withAlpha(38),
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Settings Card (Flipped to come first)
                      _buildSettingsMenu(theme),
                      const SizedBox(height: 24),

                      // Linked Accounts Card (Flipped to come second)
                      _buildAccountsCard(theme),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(51),
          width: 1,
        ),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(38),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Linked Bank Connections',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No bank connections linked.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _accounts.length,
                separatorBuilder: (context, index) => Divider(
                  color: theme.colorScheme.outlineVariant.withAlpha(38),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  final isCredit = account.type == 'credit';
                  final balance = isCredit ? (account.current ?? 0.0) : (account.available ?? account.current ?? 0.0);
                  final isNegative = balance < 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${account.type.toUpperCase()} • ${account.subetype}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isNegative ? '-' : ''}\$${balance.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: account.type == 'credit'
                                ? Colors.redAccent
                                : Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            Divider(
              color: theme.colorScheme.outlineVariant.withAlpha(38),
              height: 1,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => context.push('/accounts'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage Bank Connections',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
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

  Widget _buildSettingsMenu(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(51),
          width: 1,
        ),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(38),
      child: Column(
        children: [
          _buildMenuRow(
            theme: theme,
            icon: Icons.person_outline_rounded,
            title: 'Personal Info & Credentials',
            subtitle: 'Update email, change password, delete account',
            onTap: () => context.push('/profile/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: iconColor ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class FirebaseProfilePage extends StatefulWidget {
  const FirebaseProfilePage({super.key});

  @override
  State<FirebaseProfilePage> createState() => _FirebaseProfilePageState();
}

class _FirebaseProfilePageState extends State<FirebaseProfilePage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return _user != null
        ? Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  PageHeader(
                    showBackButton: true,
                    header: 'Personal Settings',
                    sub: 'Manage your credentials and authentication settings',
                  ),
                  Expanded(
                    child: ProfileScreen(actions: [_signOut()]),
                  ),
                ],
              ),
            ),
          )
        : SignInPage();
  }
}
