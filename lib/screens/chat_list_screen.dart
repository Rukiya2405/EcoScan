import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ecoscan/screens/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() =>
      _ChatListScreenState();
}

class _ChatListScreenState
    extends State<ChatListScreen> {
  static const Color primaryGreen =
      Color(0xFF2E7D32);

  final String currentUid =
      FirebaseAuth.instance.currentUser!.uid;

  final TextEditingController
      _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // OPEN CHAT
  // ============================================================

  Future<void> _openChat(
    String otherUid,
    String otherName,
  ) async {
    if (otherUid.isEmpty) return;

    try {
      final List<String> ids = [
        currentUid,
        otherUid,
      ]..sort();

      final String chatId = ids.join('_');

      final DocumentReference chatRef =
          FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId);

      final DocumentSnapshot chatDoc =
          await chatRef.get();

      if (!chatDoc.exists) {
        // GET CURRENT USER NAME FROM FIRESTORE
        final DocumentSnapshot currentUserDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUid)
                .get();

        final String currentName =
            (currentUserDoc.data()
                    as Map<String, dynamic>?)?[
                'name'] ??
            FirebaseAuth.instance.currentUser
                    ?.displayName ??
            'User';

        await chatRef.set({
          'participants': ids,
          'participantNames': {
            currentUid: currentName,
            otherUid: otherName,
          },
          'lastMessage': '',
          'lastMessageTime':
              FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherName: otherName,
            otherUid: otherUid,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Open chat error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // FORMAT TIME
  String _formatTime(DateTime dt) {
    final Duration diff =
        DateTime.now().difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor:
            const Color(0xFFF5F8F5),

        appBar: AppBar(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          title: const Text(
            'Messages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor:
                Colors.white60,
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'People'),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            _buildChatsTab(),
            _buildPeopleTab(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CHATS TAB
  // ============================================================

  Widget _buildChatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where(
            'participants',
            arrayContains: currentUid,
          )
          .orderBy(
            'lastMessageTime',
            descending: true,
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

        final List<DocumentSnapshot> docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons
                      .chat_bubble_outline_rounded,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet.',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Go to People tab to start a chat!',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final Map<String, dynamic> data =
                docs[index].data()!
                    as Map<String, dynamic>;

            final Map<String, dynamic>
                participantNames =
                Map<String, dynamic>.from(
              data['participantNames'] ?? {},
            );

            final String otherUid =
                (data['participants'] as List)
                    .firstWhere(
              (id) => id != currentUid,
              orElse: () => '',
            );

            final String otherName =
                participantNames[otherUid] ??
                    'User';

            final String lastMessage =
                data['lastMessage'] ?? '';

            final Timestamp? ts =
                data['lastMessageTime']
                    as Timestamp?;

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor:
                    const Color(0xFFE8F5E9),
                child: Text(
                  otherName.isNotEmpty
                      ? otherName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              title: Text(
                otherName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                lastMessage.isEmpty
                    ? 'Say hello! 👋'
                    : lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              trailing: ts != null
                  ? Text(
                      _formatTime(ts.toDate()),
                      style: TextStyle(
                        color:
                            Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    )
                  : null,
              onTap: () => _openChat(
                otherUid,
                otherName,
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // PEOPLE TAB
  // ============================================================

  Widget _buildPeopleTab() {
    return Column(
      children: [
        // SEARCH BAR
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery =
                    value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(
                Icons.search,
                color: primaryGreen,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // USERS LIST
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(
                    color: primaryGreen,
                  ),
                );
              }

              List<DocumentSnapshot> users =
                  snapshot.data?.docs
                      .where(
                        (doc) =>
                            doc.id != currentUid,
                      )
                      .toList() ??
                  [];

              if (_searchQuery.isNotEmpty) {
                users = users.where((doc) {
                  final Map<String, dynamic>
                      d = doc.data()!
                          as Map<String,
                              dynamic>;
                  final String name =
                      (d['name'] ?? '')
                          .toString()
                          .toLowerCase();
                  return name.contains(
                    _searchQuery,
                  );
                }).toList();
              }

              if (users.isEmpty) {
                return Center(
                  child: Text(
                    'No users found.',
                    style: TextStyle(
                      color:
                          Colors.grey.shade500,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final Map<String, dynamic>
                      data = users[index].data()!
                      as Map<String, dynamic>;

                  final String uid =
                      users[index].id;

                  final String name =
                      data['name'] ?? 'User';

                  final int ecoPoints =
                      data['ecoPoints'] ?? 0;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        12,
                      ),
                      child: Row(
                        children: [
                          // AVATAR
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                const Color(
                              0xFFE8F5E9,
                            ),
                            child: Text(
                              name.isNotEmpty
                                  ? name[0]
                                      .toUpperCase()
                                  : 'U',
                              style:
                                  const TextStyle(
                                color:
                                    primaryGreen,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize: 18,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          // NAME + ECO POINTS
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  name,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.eco,
                                      size: 13,
                                      color:
                                          primaryGreen,
                                    ),
                                    const SizedBox(
                                      width: 4,
                                    ),
                                    Text(
                                      '$ecoPoints EcoPoints',
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            12,
                                        color:
                                            primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // MESSAGE BUTTON
                          GestureDetector(
                            onTap: () {
                              _openChat(
                                uid,
                                name,
                              );
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    primaryGreen,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child: const Text(
                                'Message',
                                style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}