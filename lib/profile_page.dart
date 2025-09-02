import 'package:flutter/material.dart';
import 'package:stitches_africa_local/register_screen.dart';
import 'package:stitches_africa_local/utils/prefs.dart';
import 'package:stitches_africa_local/services/user_service.dart';
import 'package:stitches_africa_local/models/user_model.dart';
import 'package:stitches_africa_local/widgets/profile_update_sheets.dart';

const bool kDebugMode = true; // Set to false in production

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;
  String? _error;
  bool _showingSignInSheet = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _showingSignInSheet = false;
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Try to load from API
      try {
        final user = await _userService.getProfile();
        if (kDebugMode) {
          print('API user data loaded successfully: ${user?.fullName}');
          print('API user image: ${user?.image}');
        }
        if (user != null) {
          setState(() {
            _user = user;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('API call failed: $e');
        }
      }

      // Fallback to cached user data
      final cachedUserData = Prefs.userData;
      if (cachedUserData != null) {
        if (kDebugMode) {
          print('Attempting to load cached user data: $cachedUserData');
        }
        try {
          final user = User.fromJson(cachedUserData);
          if (kDebugMode) {
            print('Cached user data loaded successfully: ${user.fullName}');
          }
          setState(() {
            _user = user;
            _isLoading = false;
          });
          return;
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing cached user data: $e');
          }
          await Prefs.remove('user');
        }
      }

      // No cached data → error
      setState(() {
        _error =
            'Unable to load user profile. Please try logging out and back in.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserData(User updatedUser) async {
    setState(() {
      _user = updatedUser;
    });
    await Prefs.setUserData(updatedUser.toJson());

    // Reload the profile to get the latest data including image URL
    await _loadUserProfile();
  }

  void showSignInSheet(BuildContext context) {
    if (_showingSignInSheet) return; // Prevent multiple sheets

    _showingSignInSheet = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return const RegisterScreen();
      },
    ).then((_) {
      _showingSignInSheet = false; // Reset flag when sheet is closed
    });
  }

  Widget _accountSettingItem({
    required IconData leadingIcon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    bool showTrailing = true,
  }) {
    return ListTile(
      leading: Icon(leadingIcon, color: Colors.black87, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: showTrailing
          ? (trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey,
                ))
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    );
  }

  Future<void> _handleLogout() async {
    try {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout != true) return;

      await _userService.logout();
      await Prefs.clearAll();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Prefs.token;

    if (t == null || t.isEmpty) {
      // Only show sign-in sheet if not already showing
      if (!_showingSignInSheet) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_showingSignInSheet) {
            showSignInSheet(context);
          }
        });
      }
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your profile')),
      );
    }

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Image.asset(
                  "images/Stitches Africa Logo-06.png", // ✅ your logo
                  height: 120, // adjust size if needed
                ),
              ),
              const SizedBox(height: 16),
              const Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await Prefs.remove('user');
                      _loadUserProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear Cache & Retry'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await Prefs.clearAll();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear All Data & Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('No user data available')),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ProfileUpdateSheets.showImageUpdateSheet(
                          context,
                          _user!.image,
                          _updateUserData,
                        );
                      },
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: _user!.image != null
                            ? NetworkImage(_user!.image!)
                            : null,
                        child: _user!.image == null
                            ? Text(
                                _user!.fullName.isNotEmpty
                                    ? _user!.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user!.fullName.isNotEmpty
                                ? _user!.fullName
                                : 'User',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          if (_user!.email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _user!.email,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          if (_user!.gender != null &&
                              _user!.gender!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Gender: ${_user!.gender}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                const Text(
                  'Account Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _accountSettingItem(
                  leadingIcon: Icons.person_outline,
                  title: "Edit profile",
                  onTap: () {
                    ProfileUpdateSheets.showPersonalInfoUpdateSheet(
                      context,
                      null, // dob not available in User model
                      _user!.gender,
                      _updateUserData,
                    );
                  },
                  showTrailing: false,
                ),

                const Divider(),
                _accountSettingItem(
                  leadingIcon: Icons.location_on_outlined,
                  title: "Saved Location",
                  onTap: () {
                    // TODO: Navigate to saved locations screen
                  },
                  showTrailing: false,
                ),
                const Divider(),
                if (_user!.userType == "VENDOR") ...[
                  _accountSettingItem(
                    leadingIcon: Icons.campaign_outlined,
                    title: "My Ads Placements",
                    onTap: () {
                      // TODO: Navigate to my ads screen
                    },
                    showTrailing: false,
                  ),
                  const Divider(),
                ],

                const Divider(),
                _accountSettingItem(
                  leadingIcon: Icons.logout,
                  title: "Logout",
                  onTap: _handleLogout,
                  showTrailing: false,
                ),
                const SizedBox(height: 32),

                if (_user!.address != null) ...[
                  _accountSettingItem(
                    leadingIcon: Icons.location_on,
                    title: "Location: ${_user!.address}",
                    onTap: null,
                    showTrailing: false,
                  ),
                  const Divider(),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
