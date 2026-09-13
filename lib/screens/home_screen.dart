import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ecoscan/screens/profile_screen.dart';
import 'package:ecoscan/screens/scan_screen.dart';
import 'package:ecoscan/screens/map_screen.dart';
import 'package:ecoscan/screens/history_screen.dart';
import 'package:ecoscan/screens/community_screen.dart';
import 'package:ecoscan/screens/chat_screen.dart';
import 'package:ecoscan/screens/post_detail_screen.dart';
import 'package:ecoscan/services/notification_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFEAF6EC);
  static const Color background = Color(0xFFF5F8F5);

  // ============================================================
  // SHOW NOTIFICATIONS
  // ============================================================

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: user == null
            ? const Center(
                child: Text(
                  'Please log in to continue.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();

                  final String name =
                      (data?['name'] ?? 'EcoScan User').toString();

                  final int ecoPoints =
                      (data?['ecoPoints'] as num?)?.toInt() ?? 0;

                  final int totalScans =
                      (data?['totalScans'] as num?)?.toInt() ?? 0;

                  final int totalRecycled =
                      (data?['totalRecycled'] as num?)?.toInt() ?? 0;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // HEADER
                        // ==================================================

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome back 👋',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ==================================================
                            // NOTIFICATION BELL
                            // ==================================================

                            StreamBuilder<int>(
                              stream:
                                  NotificationService.getUnreadCount(),
                              builder: (
                                context,
                                notifSnap,
                              ) {
                                final int count =
                                    notifSnap.data ?? 0;

                                return GestureDetector(
                                  onTap: () {
                                    _showNotifications(context);
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: lightGreen,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: primaryGreen.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.notifications_outlined,
                                          color: primaryGreen,
                                          size: 24,
                                        ),
                                      ),

                                      // ==================================================
                                      // UNREAD BADGE
                                      // ==================================================

                                      if (count > 0)
                                        Positioned(
                                          right: -1,
                                          top: -1,
                                          child: Container(
                                            constraints:
                                                const BoxConstraints(
                                              minWidth: 18,
                                              minHeight: 18,
                                            ),
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            decoration:
                                                const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                count > 9
                                                    ? '9+'
                                                    : '$count',
                                                style:
                                                    const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 10),

                            // ==================================================
                            // PROFILE BUTTON
                            // ==================================================

                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ProfileScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: lightGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryGreen.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: primaryGreen,
                                  size: 27,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // ==================================================
                        // ECO POINTS CARD
                        // ==================================================

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF2E7D32),
                                Color(0xFF43A047),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.eco,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'YOUR ECO IMPACT',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.trending_up,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Keep going!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              const Text(
                                'Eco Points',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 2),

                              Text(
                                ecoPoints.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: _impactStat(
                                      icon:
                                          Icons.camera_alt_outlined,
                                      value:
                                          totalScans.toString(),
                                      label: 'Scans',
                                    ),
                                  ),
                                  Container(
                                    height: 40,
                                    width: 1,
                                    color: Colors.white24,
                                  ),
                                  Expanded(
                                    child: _impactStat(
                                      icon: Icons.recycling,
                                      value:
                                          totalRecycled.toString(),
                                      label: 'Recycled',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ==================================================
                        // QUICK ACTIONS
                        // ==================================================

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ScanScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Scan now',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _actionCard(
                                context,
                                title: 'Scan Waste',
                                subtitle: 'Identify an item',
                                icon:
                                    Icons.camera_alt_outlined,
                                color: primaryGreen,
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _actionCard(
                                context,
                                title: 'Find Center',
                                subtitle: 'Nearby recycling',
                                icon:
                                    Icons.location_on_outlined,
                                color:
                                    const Color(0xFF1976D2),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MapScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _actionCard(
                                context,
                                title: 'Scan History',
                                subtitle: 'View your scans',
                                icon: Icons.history,
                                color:
                                    const Color(0xFF00897B),
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _actionCard(
                                context,
                                title: 'Community',
                                subtitle: 'Share & connect',
                                icon:
                                    Icons.people_outline_rounded,
                                color:
                                    const Color(0xFFE65100),
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
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ==================================================
                        // ECO TIP
                        // ==================================================

                        const Text(
                          'Eco Tip',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius:
                                BorderRadius.circular(22),
                            border: Border.all(
                              color: primaryGreen.withValues(
                                alpha: 0.10,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outline,
                                  color:
                                      Color(0xFFF9A825),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Small actions matter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold,
                                        color:
                                            Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Rinse recyclable containers before putting them in the recycling bin.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.45,
                                        color:
                                            Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // ==================================================
                        // YOUR PROGRESS
                        // ==================================================

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Progress',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const HistoryScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'View history',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.045,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _progressRow(
                                icon:
                                    Icons.camera_alt_outlined,
                                color: primaryGreen,
                                title: 'Total scans',
                                value:
                                    totalScans.toString(),
                              ),
                              const Divider(height: 25),
                              _progressRow(
                                icon: Icons.recycling,
                                color:
                                    const Color(0xFF1976D2),
                                title: 'Items recycled',
                                value:
                                    totalRecycled.toString(),
                              ),
                              const Divider(height: 25),
                              _progressRow(
                                icon: Icons.star_outline,
                                color:
                                    const Color(0xFFFFA000),
                                title:
                                    'Eco points earned',
                                value:
                                    ecoPoints.toString(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar: Container(
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
                  selected: true,
                  onTap: () {},
                ),
                _bottomNavItem(
                  icon: Icons.camera_alt_outlined,
                  label: 'Scan',
                  selected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScanScreen(),
                      ),
                    );
                  },
                ),
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
                  icon: Icons.history,
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
                  selected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ECO IMPACT STAT
  // ============================================================

  static Widget _impactStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 22,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  static Widget _actionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 125,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.045,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROGRESS ROW
  // ============================================================

  static Widget _progressRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM NAV ITEM
  // ============================================================

  static Widget _bottomNavItem({
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
              duration:
                  const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(
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

// ================================================================
// NOTIFICATIONS BOTTOM SHEET
// ================================================================

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() =>
      _NotificationsSheetState();
}

class _NotificationsSheetState
    extends State<_NotificationsSheet> {
  static const Color primaryGreen =
      Color(0xFF2E7D32);

  List<Map<String, dynamic>> _notifications = [];

  bool _loaded = false;

  @override
  void initState() {
    super.initState();

    _loadNotifications();
  }

  // ============================================================
  // LOAD NOTIFICATIONS
  // ============================================================

  Future<void> _loadNotifications() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _loaded = true;
          });
        }
        return;
      }

      final String currentUid = user.uid;

      // IMPORTANT:
      // We don't use orderBy here.
      // This avoids requiring a Firestore composite index.

      final QuerySnapshot snap =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where(
                'toUserId',
                isEqualTo: currentUid,
              )
              .limit(50)
              .get();

      final List<Map<String, dynamic>>
          loadedNotifications =
          snap.docs.map((doc) {
        final Map<String, dynamic> data =
            doc.data() as Map<String, dynamic>;

        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      // ==========================================================
      // SORT LOCALLY
      // ==========================================================

      loadedNotifications.sort(
        (a, b) {
          final DateTime? aDate =
              _getNotificationDate(a);

          final DateTime? bDate =
              _getNotificationDate(b);

          if (aDate == null && bDate == null) {
            return 0;
          }

          if (aDate == null) {
            return 1;
          }

          if (bDate == null) {
            return -1;
          }

          return bDate.compareTo(aDate);
        },
      );

      if (!mounted) return;

      setState(() {
        _notifications = loadedNotifications;
        _loaded = true;
      });

      // ==========================================================
      // IMPORTANT:
      //
      // DO NOT call markAllAsRead() here.
      //
      // Notifications are now marked read individually when
      // the user actually clicks them.
      // ==========================================================
    } catch (e, stackTrace) {
      debugPrint(
        'Notifications load error: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        setState(() {
          _loaded = true;
        });
      }
    }
  }

  // ============================================================
  // OPEN NOTIFICATION
  // ============================================================

  Future<void> _openNotification(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final String notificationId =
        (data['id'] ?? '').toString();

    final String type =
        (data['type'] ?? '')
            .toString()
            .toLowerCase();

    // Save the navigator before closing the bottom sheet.
    final NavigatorState navigator =
        Navigator.of(context);

    // ==========================================================
    // MARK ONLY THIS NOTIFICATION AS READ
    // ==========================================================

    if (notificationId.isNotEmpty) {
      try {
        await NotificationService.markAsRead(
          notificationId,
        );
      } catch (e) {
        debugPrint(
          'Mark notification as read error: $e',
        );
      }
    }

    if (!mounted) return;

    // ==========================================================
    // MESSAGE NOTIFICATION
    // ==========================================================

    if (type == 'message' ||
        type == 'messaged') {
      final String chatId =
          (data['chatId'] ?? '').toString();

      // Support both field names in case your
      // notification documents use either one.
      String otherUid =
          (data['fromUserId'] ?? '').toString();

      if (otherUid.isEmpty) {
        otherUid =
            (data['senderId'] ?? '').toString();
      }

      String otherName =
          (data['fromUserName'] ?? '').toString();

      if (otherName.isEmpty) {
        otherName =
            (data['senderName'] ?? 'User')
                .toString();
      }

      if (chatId.isEmpty ||
          otherUid.isEmpty) {
        debugPrint(
          'Cannot open chat notification: '
          'chatId=$chatId otherUid=$otherUid',
        );
        return;
      }

      // Close notification sheet first.
      navigator.pop();

      // Open exact chat.
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherName: otherName,
            otherUid: otherUid,
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // LIKE / COMMENT NOTIFICATION
    // ==========================================================

    if (type == 'like' ||
        type == 'liked' ||
        type == 'comment' ||
        type == 'commented') {
      final String postId =
          (data['postId'] ?? '').toString();

      if (postId.isEmpty) {
        debugPrint(
          'Cannot open post notification: postId is empty.',
        );
        return;
      }

      try {
        final DocumentSnapshot postDoc =
            await FirebaseFirestore.instance
                .collection('posts')
                .doc(postId)
                .get();

        if (!postDoc.exists) {
          debugPrint(
            'Post does not exist: $postId',
          );
          return;
        }

        final Map<String, dynamic> postData =
            postDoc.data()
                    as Map<String, dynamic>;

        if (!mounted) return;

        // Close notification sheet first.
        navigator.pop();

        // Open exact post.
        navigator.push(
          MaterialPageRoute(
            builder: (_) =>
                PostDetailScreen(
              postId: postId,
              data: postData,
            ),
          ),
        );
      } catch (e) {
        debugPrint(
          'Open post notification error: $e',
        );
      }

      return;
    }

    // ==========================================================
    // UNKNOWN NOTIFICATION
    // ==========================================================

    // If this notification doesn't have a supported destination,
    // simply close the notification sheet after marking it read.
    navigator.pop();
  }

  // ============================================================
  // GET DATE
  // ============================================================

  DateTime? _getNotificationDate(
    Map<String, dynamic> data,
  ) {
    final dynamic value =
        data['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(DateTime dt) {
    final Duration diff =
        DateTime.now().difference(dt);

    if (diff.isNegative) {
      return 'Just now';
    }

    if (diff.inSeconds < 60) {
      return 'Just now';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }

    return '${dt.month}/${dt.day}/${dt.year}';
  }

  // ============================================================
  // GET MESSAGE
  // ============================================================

  String _getMessage(
    Map<String, dynamic> data,
  ) {
    final dynamic message =
        data['message'];

    if (message != null &&
        message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    final dynamic title =
        data['title'];

    if (title != null &&
        title.toString().trim().isNotEmpty) {
      return title.toString();
    }

    return 'You have a new notification';
  }

  // ============================================================
  // GET TYPE
  // ============================================================

  String _getType(
    Map<String, dynamic> data,
  ) {
    final dynamic type =
        data['type'];

    if (type == null) {
      return '';
    }

    return type.toString().toLowerCase();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height *
              0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F8F5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ========================================================
          // HANDLE
          // ========================================================

          Container(
            margin:
                const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ),

          // ========================================================
          // TITLE
          // ========================================================

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ========================================================
          // LIST
          // ========================================================

          Expanded(
            child: !_loaded
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color: primaryGreen,
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            24,
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                Icons
                                    .notifications_none_rounded,
                                size: 64,
                                color: Colors
                                    .grey
                                    .shade300,
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Text(
                                'No notifications yet',
                                style: TextStyle(
                                  color: Colors
                                      .grey
                                      .shade500,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                'Likes, comments and messages\nwill appear here',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  color: Colors
                                      .grey
                                      .shade400,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount:
                            _notifications.length,
                        itemBuilder:
                            (context, index) {
                          final Map<String, dynamic>
                              data =
                              _notifications[index];

                          final String type =
                              _getType(data);

                          final String message =
                              _getMessage(data);

                          final bool read =
                              data['read'] == true;

                          final DateTime?
                              notificationDate =
                              _getNotificationDate(
                            data,
                          );

                          // =================================================
                          // ICON
                          // =================================================

                          IconData icon;
                          Color color;

                          switch (type) {
                            case 'like':
                            case 'liked':
                              icon =
                                  Icons.favorite;
                              color = Colors.red;
                              break;

                            case 'comment':
                            case 'commented':
                              icon =
                                  Icons.chat_bubble;
                              color =
                                  primaryGreen;
                              break;

                            case 'message':
                            case 'messaged':
                              icon =
                                  Icons.message;
                              color =
                                  Colors.blue.shade600;
                              break;

                            default:
                              icon =
                                  Icons.notifications;
                              color =
                                  primaryGreen;
                          }

                          // =================================================
                          // CLICKABLE NOTIFICATION
                          // =================================================

                          return GestureDetector(
                            onTap: () {
                              _openNotification(
                                context,
                                data,
                              );
                            },
                            child: Container(
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 8,
                              ),
                              padding:
                                  const EdgeInsets
                                      .all(14),
                              decoration:
                                  BoxDecoration(
                                color: read
                                    ? Colors.white
                                    : primaryGreen
                                        .withValues(
                                        alpha: 0.05,
                                      ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                                border:
                                    Border.all(
                                  color: read
                                      ? Colors
                                          .transparent
                                      : primaryGreen
                                          .withValues(
                                          alpha: 0.15,
                                        ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  // =================================================
                                  // ICON
                                  // =================================================

                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          color.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape:
                                          BoxShape.circle,
                                    ),
                                    child: Icon(
                                      icon,
                                      color: color,
                                      size: 20,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  // =================================================
                                  // MESSAGE
                                  // =================================================

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          message,
                                          style:
                                              TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                read
                                                    ? FontWeight
                                                        .w500
                                                    : FontWeight
                                                        .w600,
                                            color:
                                                Colors
                                                    .black87,
                                          ),
                                        ),

                                        if (notificationDate !=
                                            null)
                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              _formatTime(
                                                notificationDate,
                                              ),
                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    11,
                                                color: Colors
                                                    .grey
                                                    .shade500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  // =================================================
                                  // CLICK ARROW
                                  // =================================================

                                  Icon(
                                    Icons
                                        .chevron_right_rounded,
                                    color: Colors
                                        .grey
                                        .shade400,
                                    size: 20,
                                  ),

                                  const SizedBox(
                                    width: 4,
                                  ),

                                  // =================================================
                                  // UNREAD DOT
                                  // =================================================

                                  if (!read)
                                    Container(
                                      margin:
                                          const EdgeInsets
                                              .only(
                                        top: 5,
                                      ),
                                      width: 8,
                                      height: 8,
                                      decoration:
                                          const BoxDecoration(
                                        color:
                                            primaryGreen,
                                        shape:
                                            BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
