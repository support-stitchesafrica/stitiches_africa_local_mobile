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

  @override
  void initState() {
    super.initState();
    _testUserParsing(); // Test the User model parsing
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // First try to load from API
      try {
        final user = await _userService.getProfile();
        if (kDebugMode) {
          print('API user data loaded successfully: ${user?.fullName}');
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
        // If API fails, try to load from cached data
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
          // Clear corrupted cached data
          await Prefs.remove('user');
        }
      }

      // If no cached data, show error
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

    // Update cached data
    await Prefs.setUserData(updatedUser.toJson());
  }

  // Test method to validate User model parsing
  void _testUserParsing() {
    try {
      // Test with sample data that might come from API
      final testData = {
        "id": "test-id",
        "fullName": "Test User",
        "email": "test@example.com",
        "category": "Fashion,Clothing", // String format
        "style": ["Casual", "Formal"], // Array format
        "priceRange": "Medium",
        "latitude": "12.345",
        "longitude": "67.890",
      };

      final user = User.fromJson(testData);
      if (kDebugMode) {
        print('Test user parsing successful: ${user.fullName}');
        print('Category: ${user.category}');
        print('Style: ${user.style}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Test user parsing failed: $e');
      }
    }
  }

  void showSignInSheet(BuildContext context) {
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
    );
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
      // Show confirmation dialog
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

      // Call logout API
      await _userService.logout();

      // Clear all local data
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
      showSignInSheet(context);
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your profile')),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
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
                          // const SizedBox(height: 4),
                          // Text(
                          //   'ID ${_user!.id}',
                          //   style: const TextStyle(fontWeight: FontWeight.w500),
                          // ),
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
                          if (_user!.dob != null && _user!.dob!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'DOB: ${_user!.dob}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
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
                    // IconButton(
                    //   onPressed: () {
                    //     ProfileUpdateSheets.showPersonalInfoUpdateSheet(
                    //       context,
                    //       _user!.dob,
                    //       _user!.gender,
                    //       _updateUserData,
                    //     );
                    //   },
                    //   icon: const Icon(Icons.edit),
                    // ),
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
                      _user!.dob,
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
                _accountSettingItem(
                  leadingIcon: Icons.campaign_outlined,
                  title: "My Ads Placements",
                  onTap: () {
                    // TODO: Navigate to my ads screen
                  },
                  showTrailing: false,
                ),
                const Divider(),
                _accountSettingItem(
                  leadingIcon: Icons.logout,
                  title: "Logout",
                  onTap: _handleLogout,
                  showTrailing: false,
                ),
                const SizedBox(height: 32),

                // User Preferences Section
                const Text(
                  'Preferences',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                // Style preference
                _accountSettingItem(
                  leadingIcon: Icons.style,
                  title: _user!.style != null && _user!.style!.isNotEmpty
                      ? "Style: ${_user!.style!.join(', ')}"
                      : "Style: Not set",
                  onTap: () {
                    ProfileUpdateSheets.showStyleUpdateSheet(
                      context,
                      _user!.style,
                      _updateUserData,
                    );
                  },
                  trailing: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.grey,
                  ),
                  showTrailing: true,
                ),
                const Divider(),
                // Price range preference
                _accountSettingItem(
                  leadingIcon: Icons.attach_money,
                  title:
                      _user!.priceRange != null && _user!.priceRange!.isNotEmpty
                      ? "Price Range: ${_user!.priceRange}"
                      : "Price Range: Not set",
                  onTap: () {
                    ProfileUpdateSheets.showPriceRangeUpdateSheet(
                      context,
                      _user!.priceRange,
                      _updateUserData,
                    );
                  },
                  trailing: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.grey,
                  ),
                  showTrailing: true,
                ),
                const Divider(),
                if (_user!.address != null) ...[
                  _accountSettingItem(
                    leadingIcon: Icons.location_on,
                    title: "Location: ${_user!.address}",
                    onTap: null,
                    showTrailing: false,
                  ),
                  const Divider(),
                ],
                const SizedBox(
                  height: 100,
                ), // Add bottom padding for refresh indicator
              ],
            ),
          ),
        ),
      ),
    );
  }
}
