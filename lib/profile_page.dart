import 'package:flutter/material.dart';
import 'package:stitches_africa_local/register_screen.dart';
import 'package:stitches_africa_local/utils/prefs.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});
  final t = Prefs.token;

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
  }) {
    return ListTile(
      leading: Icon(leadingIcon, color: Colors.black87, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 18,
        color: Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      //dense: true,
      // minLeadingWidth: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (t == null || t!.isEmpty) {
      showSignInSheet(context);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(radius: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Thomas Djono",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ID 0212141',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
            ],
          ),
          const SizedBox(height: 64),
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
            onTap: () {},
          ),
          Divider(),
          _accountSettingItem(
            leadingIcon: Icons.location_on_outlined,
            title: "Saved Location",
            onTap: () {},
          ),
          Divider(),
          _accountSettingItem(
            leadingIcon: Icons.campaign_outlined,
            title: "My Ads Placments",
            onTap: () {},
          ),
          Divider(),
          _accountSettingItem(
            leadingIcon: Icons.logout,
            title: "Logout",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
