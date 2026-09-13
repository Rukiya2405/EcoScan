import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'community_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFEAF6EC);
  static const Color background = Color(0xFFF5F8F5);

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // ============================================================
  // CONFIRM LOGOUT
  // ============================================================

  Future<void> _confirmLogout(
    BuildContext context,
  ) async {
    final bool? shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of your EcoScan account?',
            style: TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      // ignore: use_build_context_synchronously
      await _logout(context);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Your Account',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Profile',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(right: 20),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryGreen.withValues(
                    alpha: 0.12,
                  ),
                ),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: primaryGreen,
                size: 24,
              ),
            ),
          ),
        ],
      ),

      body: user == null
          ? _buildLoggedOutMessage(context)
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryGreen,
                    ),
                  );
                }

                final Map<String, dynamic>
                    userData =
                    snapshot.data?.data()
                            as Map<String,
                                dynamic>? ??
                        {};

                final int totalScans =
                    (userData['totalScans']
                                as num?)
                            ?.toInt() ??
                        0;

                final int ecoPoints =
                    (userData['ecoPoints']
                                as num?)
                            ?.toInt() ??
                        0;

                final int totalRecycled =
                    (userData['totalRecycled']
                                as num?)
                            ?.toInt() ??
                        0;

                return SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    30,
                  ),
                  child: Column(
                    children: [
                      _buildProfileHeader(user),

                      const SizedBox(height: 20),

                      _buildStatisticsCard(
                        totalScans: totalScans,
                        totalRecycled:
                            totalRecycled,
                        ecoPoints: ecoPoints,
                      ),

                      const SizedBox(height: 20),

                      _buildSectionTitle(
                        'Account',
                      ),

                      const SizedBox(height: 10),

                      _buildMenuCard(
                        children: [
                          _buildMenuItem(
                            icon:
                                Icons.email_outlined,
                            title: 'Email',
                            subtitle: user.email ??
                                'No email available',
                            iconColor: primaryGreen,
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons
                                .verified_user_outlined,
                            title:
                                'Account Status',
                            subtitle:
                                'Authenticated',
                            iconColor: primaryGreen,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSectionTitle(
                        'Eco Activity',
                      ),

                      const SizedBox(height: 10),

                      _buildMenuCard(
                        children: [
                          _buildMenuItem(
                            icon: Icons
                                .camera_alt_outlined,
                            title: 'Scan History',
                            subtitle:
                                'View your previous waste scans',
                            iconColor: primaryGreen,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const HistoryScreen(),
                                ),
                              );
                            },
                            showArrow: true,
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons
                                .recycling_rounded,
                            title:
                                'Recycled Items',
                            subtitle:
                                '$totalRecycled items marked recyclable',
                            iconColor: primaryGreen,
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons
                                .star_outline_rounded,
                            title: 'Eco Points',
                            subtitle:
                                '$ecoPoints points earned',
                            iconColor: const Color(
                              0xFFFFA000,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // COMMUNITY MENU ITEM
                      _buildSectionTitle(
                        'Community',
                      ),

                      const SizedBox(height: 10),

                      _buildMenuCard(
                        children: [
                          _buildMenuItem(
                            icon: Icons
                                .people_outline_rounded,
                            title: 'Community Feed',
                            subtitle:
                                'Share and connect with others',
                            iconColor: const Color(
                              0xFFE65100,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CommunityScreen(),
                                ),
                              );
                            },
                            showArrow: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // LOGOUT
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child:
                            ElevatedButton.icon(
                          onPressed: () {
                            _confirmLogout(
                              context,
                            );
                          },
                          icon: const Icon(
                            Icons.logout_rounded,
                          ),
                          label: const Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton
                              .styleFrom(
                            backgroundColor:
                                Colors.red.shade50,
                            foregroundColor:
                                Colors.red.shade700,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(16),
                              side: BorderSide(
                                color: Colors
                                    .red.shade100,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'EcoScan',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Waste classification made simple.',
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

      bottomNavigationBar:
          _buildBottomNavigation(context),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader(User user) {
    final String email =
        user.email ?? 'EcoScan User';

    final String initial = email.isNotEmpty
        ? email[0].toUpperCase()
        : 'E';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF43A047),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(
              alpha: 0.20,
            ),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white54,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'EcoScan Member',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTICS CARD
  // ============================================================

  Widget _buildStatisticsCard({
    required int totalScans,
    required int totalRecycled,
    required int ecoPoints,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.045,
            ),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              icon: Icons.camera_alt_outlined,
              value: totalScans.toString(),
              label: 'Scans',
              color: primaryGreen,
            ),
          ),

          Container(
            width: 1,
            height: 45,
            color: Colors.grey.shade200,
          ),

          Expanded(
            child: _statItem(
              icon: Icons.recycling_rounded,
              value: totalRecycled.toString(),
              label: 'Recycled',
              color: primaryGreen,
            ),
          ),

          Container(
            width: 1,
            height: 45,
            color: Colors.grey.shade200,
          ),

          Expanded(
            child: _statItem(
              icon: Icons.star_rounded,
              value: ecoPoints.toString(),
              label: 'Points',
              color: const Color(0xFFFFA000),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT ITEM
  // ============================================================

  Widget _statItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ============================================================
  // MENU CARD
  // ============================================================

  Widget _buildMenuCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Column(children: children),
      ),
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: iconColor.withValues(
                  alpha: 0.09,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 23,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
    );
  }

  // ============================================================
  // LOGGED OUT MESSAGE
  // ============================================================

  Widget _buildLoggedOutMessage(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off_outlined,
                size: 50,
                color: primaryGreen,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Login Required',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 9),

            const Text(
              'Please log in to view your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 25,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              _bottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const HomeScreen(),
                    ),
                  );
                },
              ),

              _bottomNavItem(
                icon: Icons.camera_alt_outlined,
                label: 'Scan',
                selected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ScanScreen(),
                    ),
                  );
                },
              ),

              // COMMUNITY NAV ITEM
              _bottomNavItem(
                icon:
                    Icons.people_outline_rounded,
                label: 'Community',
                selected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const CommunityScreen(),
                    ),
                  );
                },
              ),

              _bottomNavItem(
                icon: Icons.history_rounded,
                label: 'History',
                selected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const HistoryScreen(),
                    ),
                  );
                },
              ),

              _bottomNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                selected: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV ITEM
  // ============================================================

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(
                milliseconds: 200,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? primaryGreen.withValues(
                        alpha: 0.10,
                      )
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 23,
                color: selected
                    ? primaryGreen
                    : Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: selected
                    ? primaryGreen
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}