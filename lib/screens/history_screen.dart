import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'scan_screen.dart';
import 'home_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFEAF6EC);
  static const Color background = Color(0xFFF5F8F5);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Activity',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Scan History',
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
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.12),
                ),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: primaryGreen,
                size: 24,
              ),
            ),
          ),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: user == null
          ? _buildLoginMessage()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('waste_scans')
                  .where(
                    'userId',
                    isEqualTo: user.uid,
                  )
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

                if (snapshot.hasError) {
                  return _buildError(snapshot.error);
                }

                final documents = snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return _buildEmptyState(context);
                }

                // ----------------------------------------------------
                // SORT NEWEST FIRST
                // ----------------------------------------------------

                final sortedDocuments =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                  documents,
                );

                sortedDocuments.sort((a, b) {
                  final Timestamp? aTime =
                      a.data()['timestamp'] as Timestamp?;

                  final Timestamp? bTime =
                      b.data()['timestamp'] as Timestamp?;

                  if (aTime == null && bTime == null) {
                    return 0;
                  }

                  if (aTime == null) {
                    return 1;
                  }

                  if (bTime == null) {
                    return -1;
                  }

                  return bTime.compareTo(aTime);
                });

                // ----------------------------------------------------
                // CALCULATE SUMMARY
                // ----------------------------------------------------

                int totalPoints = 0;
                int recycledCount = 0;

                for (final document in sortedDocuments) {
                  final data = document.data();

                  totalPoints +=
                      (data['ecoPoints'] as num?)?.toInt() ?? 0;

                  if (data['recyclable'] == true) {
                    recycledCount++;
                  }
                }

                return Column(
                  children: [
                    // ------------------------------------------------
                    // SUMMARY CARD
                    // ------------------------------------------------

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        5,
                        20,
                        8,
                      ),
                      child: _buildSummaryCard(
                        totalScans: sortedDocuments.length,
                        recycledCount: recycledCount,
                        totalPoints: totalPoints,
                      ),
                    ),

                    // ------------------------------------------------
                    // SECTION TITLE
                    // ------------------------------------------------

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        12,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Scans',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: lightGreen,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${sortedDocuments.length} scans',
                              style: const TextStyle(
                                color: primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ------------------------------------------------
                    // SCAN LIST
                    // ------------------------------------------------

                    Expanded(
                      child: ListView.builder(
                        physics:
                            const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          30,
                        ),
                        itemCount: sortedDocuments.length,
                        itemBuilder: (context, index) {
                          final data =
                              sortedDocuments[index].data();

                          return _buildHistoryCard(data);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar:
          _buildBottomNavigation(context),
    );
  }

  // ================================================================
  // SUMMARY CARD
  // ================================================================

  Widget _buildSummaryCard({
    required int totalScans,
    required int recycledCount,
    required int totalPoints,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            color: primaryGreen.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 9),
              Text(
                'YOUR SCAN ACTIVITY',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  value: totalScans.toString(),
                  label: 'Total Scans',
                  icon: Icons.camera_alt_outlined,
                ),
              ),

              Container(
                height: 45,
                width: 1,
                color: Colors.white24,
              ),

              Expanded(
                child: _summaryStat(
                  value: recycledCount.toString(),
                  label: 'Recycled',
                  icon: Icons.recycling,
                ),
              ),

              Container(
                height: 45,
                width: 1,
                color: Colors.white24,
              ),

              Expanded(
                child: _summaryStat(
                  value: totalPoints.toString(),
                  label: 'Points',
                  icon: Icons.star_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUMMARY STAT
  // ================================================================

  Widget _summaryStat({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 21,
        ),

        const SizedBox(height: 5),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // HISTORY CARD
  // ================================================================

  Widget _buildHistoryCard(
    Map<String, dynamic> data,
  ) {
    final String wasteType =
        data['wasteType']?.toString() ?? 'Unknown Waste';

    final String material =
        data['material']?.toString() ?? 'Unknown Material';

    final bool recyclable =
        data['recyclable'] == true;

    final String hazardLevel =
        data['hazardLevel']?.toString() ?? 'Unknown';

    final int ecoPoints =
        (data['ecoPoints'] as num?)?.toInt() ?? 0;

    final double confidence =
        (data['confidence'] as num?)?.toDouble() ?? 0.0;

    final Timestamp? timestamp =
        data['timestamp'] as Timestamp?;

    final Color statusColor = recyclable
        ? primaryGreen
        : const Color(0xFFE65100);

    final Color statusBackground = recyclable
        ? lightGreen
        : const Color(0xFFFFF3E0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------------
            // TOP
            // --------------------------------------------------------

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Icon(
                    recyclable
                        ? Icons.recycling_rounded
                        : Icons.delete_outline_rounded,
                    color: statusColor,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        wasteType,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        material,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusBackground,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          recyclable
                              ? 'Recyclable'
                              : 'Not Recyclable',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ----------------------------------------------------
                // POINTS
                // ----------------------------------------------------

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFA000),
                        size: 20,
                      ),

                      const SizedBox(height: 2),

                      Text(
                        '+$ecoPoints',
                        style: const TextStyle(
                          color: Color(0xFFE68A00),
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 17),

            // --------------------------------------------------------
            // DIVIDER
            // --------------------------------------------------------

            Container(
              height: 1,
              color: Colors.grey.shade100,
            ),

            const SizedBox(height: 13),

            // --------------------------------------------------------
            // DETAILS
            // --------------------------------------------------------

            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    icon:
                        Icons.warning_amber_rounded,
                    label: 'Hazard',
                    value: hazardLevel,
                    color:
                        _hazardColor(hazardLevel),
                  ),
                ),

                Expanded(
                  child: _detailItem(
                    icon: Icons.auto_awesome,
                    label: 'AI Confidence',
                    value:
                        '${(confidence * 100).toStringAsFixed(0)}%',
                    color: primaryGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            // --------------------------------------------------------
            // DATE AND TIME
            // --------------------------------------------------------

            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.grey.shade500,
                ),

                const SizedBox(width: 7),

                Text(
                  _formatDate(timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 12),

                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Colors.grey.shade500,
                ),

                const SizedBox(width: 5),

                Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DETAIL ITEM
  // ================================================================

  Widget _detailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // HAZARD COLOR
  // ================================================================

  Color _hazardColor(String hazard) {
    final String value = hazard.toLowerCase();

    if (value.contains('high') ||
        value.contains('danger')) {
      return Colors.red;
    }

    if (value.contains('medium') ||
        value.contains('moderate')) {
      return Colors.orange;
    }

    if (value.contains('low') ||
        value.contains('safe')) {
      return primaryGreen;
    }

    return Colors.blueGrey;
  }

  // ================================================================
  // DATE
  // ================================================================

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Date unavailable';
    }

    final DateTime date = timestamp.toDate();

    return '${_monthName(date.month)} '
        '${date.day}, '
        '${date.year}';
  }

  // ================================================================
  // TIME
  // ================================================================

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return '--:--';
    }

    final DateTime date = timestamp.toDate();

    final int hour = date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final String minute =
        date.minute.toString().padLeft(2, '0');

    final String period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // ================================================================
  // MONTH
  // ================================================================

  String _monthName(int month) {
    const List<String> months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month];
  }

  // ================================================================
  // LOGIN MESSAGE
  // ================================================================

  Widget _buildLoginMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 65,
              color: Colors.grey,
            ),

            SizedBox(height: 18),

            Text(
              'Login Required',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Please log in to view your scan history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Could not load your scan history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
                Icons.history_rounded,
                size: 50,
                color: primaryGreen,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'No scans yet',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 9),

            const Text(
              'Your saved waste scans will appear here.\n'
              'Start by scanning your first item.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ScanScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.camera_alt_outlined,
                ),
                label: const Text(
                  'Scan Your First Item',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 22,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION
  // ================================================================

  Widget _buildBottomNavigation(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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

              _bottomNavItem(
                icon: Icons.history_rounded,
                label: 'History',
                selected: true,
                onTap: () {},
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
    );
  }

  // ================================================================
  // BOTTOM NAV ITEM
  // ================================================================

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
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 15,
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
                fontSize: 11,
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
