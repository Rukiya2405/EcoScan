import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ecoscan/screens/chat_list_screen.dart';
import 'package:ecoscan/screens/create_post_screen.dart';
import 'package:ecoscan/screens/post_detail_screen.dart';
import 'package:ecoscan/services/notification_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() =>
      _CommunityScreenState();
}

class _CommunityScreenState
    extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen =
      Color(0xFF2E7D32);

  late TabController _tabController;

  final String currentUid =
      FirebaseAuth.instance.currentUser!.uid;

  // ============================================================
  // TEMPORARY IMAGES
  //
  // These are ONLY stored in memory.
  //
  // They are NOT uploaded to Firebase Storage.
  // They are NOT saved in Firestore.
  //
  // When the app is restarted, they disappear.
  // ============================================================

  final Map<String, File> _temporaryImages = {};

  @override
  void initState() {
    super.initState();

    _tabController =
        TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  Future<void> _createPost() async {
    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CreatePostScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    // User cancelled / went back.
    if (result == null) {
      return;
    }

    // Make sure we received a Map.
    if (result is! Map) {
      return;
    }

    // ============================================================
    // GET TEMPORARY IMAGE
    // ============================================================

    final dynamic image =
        result['imageFile'];

    final String? postId =
        result['postId'];

    if (image is File &&
        postId != null &&
        postId.isNotEmpty) {
      setState(() {
        _temporaryImages[postId] =
            image;
      });

      debugPrint(
        'Temporary image added for post: $postId',
      );
    }
  }

  // ============================================================
  // LIKE / UNLIKE POST
  // ============================================================

  Future<void> _toggleLike(
    String postId,
    List likes,
    String postAuthorId,
    String postContent,
  ) async {
    final DocumentReference ref =
        FirebaseFirestore.instance
            .collection('posts')
            .doc(postId);

    try {
      if (likes.contains(
        currentUid,
      )) {
        await ref.update({
          'likes':
              FieldValue.arrayRemove(
            [currentUid],
          ),
          'likeCount':
              FieldValue.increment(
            -1,
          ),
        });
      } else {
        await ref.update({
          'likes':
              FieldValue.arrayUnion(
            [currentUid],
          ),
          'likeCount':
              FieldValue.increment(
            1,
          ),
        });

        final DocumentSnapshot
            userDoc =
            await FirebaseFirestore
                .instance
                .collection('users')
                .doc(currentUid)
                .get();

        final String likerName =
            (userDoc.data()
                    as Map<String,
                        dynamic>?)?['name'] ??
                FirebaseAuth
                    .instance
                    .currentUser
                    ?.displayName ??
                'Someone';

        await NotificationService
            .sendLikeNotification(
          postId: postId,
          postAuthorId:
              postAuthorId,
          likerName: likerName,
          postContent:
              postContent,
        );
      }
    } catch (e) {
      debugPrint(
        'Toggle like error: $e',
      );
    }
  }

  // ============================================================
  // OPEN POST DETAIL
  // ============================================================

  Future<void> _openPost(
    String postId,
    Map<String, dynamic> data,
  ) async {
    final File? temporaryImage =
        _temporaryImages[postId];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PostDetailScreen(
          postId: postId,
          data: data,

          // PASS TEMPORARY IMAGE
          temporaryImage:
              temporaryImage,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F8F5),

      appBar: AppBar(
        backgroundColor:
            primaryGreen,
        foregroundColor:
            Colors.white,
        title: const Text(
          'Community',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ChatListScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons
                  .chat_bubble_outline_rounded,
            ),
            tooltip: 'Messages',
          ),
        ],
        bottom: TabBar(
          controller:
              _tabController,
          indicatorColor:
              Colors.white,
          labelColor:
              Colors.white,
          unselectedLabelColor:
              Colors.white60,
          tabs: const [
            Tab(
              text: 'Feed',
            ),
            Tab(
              text: 'Top Posts',
            ),
          ],
        ),
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed:
            _createPost,
        backgroundColor:
            primaryGreen,
        foregroundColor:
            Colors.white,
        child: const Icon(
          Icons.add,
        ),
      ),

      body: TabBarView(
        controller:
            _tabController,
        children: [
          _PostFeed(
            query:
                FirebaseFirestore
                    .instance
                    .collection(
                      'posts',
                    )
                    .orderBy(
                      'createdAt',
                      descending:
                          true,
                    ),
            currentUid:
                currentUid,
            temporaryImages:
                _temporaryImages,
            onLike:
                _toggleLike,
            onTap:
                _openPost,
          ),

          _PostFeed(
            query:
                FirebaseFirestore
                    .instance
                    .collection(
                      'posts',
                    )
                    .orderBy(
                      'likeCount',
                      descending:
                          true,
                    ),
            currentUid:
                currentUid,
            temporaryImages:
                _temporaryImages,
            onLike:
                _toggleLike,
            onTap:
                _openPost,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// POST FEED
// ================================================================

class _PostFeed
    extends StatelessWidget {
  final Query query;

  final String currentUid;

  final Map<String, File>
      temporaryImages;

  final Future<void> Function(
    String postId,
    List likes,
    String postAuthorId,
    String postContent,
  ) onLike;

  final Future<void> Function(
    String postId,
    Map<String, dynamic> data,
  ) onTap;

  const _PostFeed({
    required this.query,
    required this.currentUid,
    required this.temporaryImages,
    required this.onLike,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<
        QuerySnapshot>(
      stream:
          query.snapshots(),
      builder:
          (context, snapshot) {
        if (snapshot
                .connectionState ==
            ConnectionState
                .waiting) {
          return const Center(
            child:
                CircularProgressIndicator(
              color:
                  Color(0xFF2E7D32),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
            ),
          );
        }

        final List<
                DocumentSnapshot>
            docs =
            snapshot.data
                    ?.docs ??
                [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                Icon(
                  Icons
                      .eco_outlined,
                  size: 64,
                  color: Colors
                      .grey
                      .shade400,
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  'No posts yet.',
                  style:
                      TextStyle(
                    fontSize: 16,
                    color: Colors
                        .grey
                        .shade500,
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'Be the first to share!',
                  style:
                      TextStyle(
                    fontSize: 13,
                    color: Colors
                        .grey
                        .shade400,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(
            top: 12,
            bottom: 80,
          ),
          itemCount:
              docs.length,
          itemBuilder:
              (context, index) {
            final DocumentSnapshot
                doc =
                docs[index];

            final Map<String,
                    dynamic>
                data =
                doc.data()
                    as Map<String,
                        dynamic>;

            final List likes =
                data['likes'] ??
                    [];

            final bool
                isLiked =
                likes.contains(
              currentUid,
            );

            final String
                postAuthorId =
                data['authorId'] ??
                    '';

            final String
                postContent =
                data['content'] ??
                    '';

            final File?
                temporaryImage =
                temporaryImages[
                    doc.id];

            return _PostCard(
              postId:
                  doc.id,
              data:
                  data,
              temporaryImage:
                  temporaryImage,
              isLiked:
                  isLiked,
              likeCount:
                  likes.length,
              onLike: () =>
                  onLike(
                doc.id,
                likes,
                postAuthorId,
                postContent,
              ),
              onTap: () =>
                  onTap(
                doc.id,
                data,
              ),
            );
          },
        );
      },
    );
  }
}

// ================================================================
// POST CARD
// ================================================================

class _PostCard
    extends StatelessWidget {
  static const Color
      primaryGreen =
      Color(0xFF2E7D32);

  final String postId;

  final Map<String,
      dynamic> data;

  final File? temporaryImage;

  final bool isLiked;

  final int likeCount;

  final VoidCallback onLike;

  final VoidCallback onTap;

  const _PostCard({
    required this.postId,
    required this.data,
    required this.temporaryImage,
    required this.isLiked,
    required this.likeCount,
    required this.onLike,
    required this.onTap,
  });

  Color _tagColor(
    String tag,
  ) {
    switch (tag) {
      case 'Recycling':
        return Colors.blue
            .shade600;

      case 'Scan':
        return Colors.orange
            .shade600;

      case 'Achievement':
        return Colors.purple
            .shade600;

      case 'Tip':
        return Colors.teal
            .shade600;

      default:
        return primaryGreen;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final String name =
        data['authorName'] ??
            'User';

    final String content =
        data['content'] ??
            '';

    final String tag =
        data['tag'] ??
            'General';

    final int commentCount =
        data['commentCount'] ??
            0;

    final Timestamp? ts =
        data['createdAt']
            as Timestamp?;

    final String timeAgo =
        ts != null
            ? _formatTime(
                ts.toDate(),
              )
            : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius
                  .circular(
            16,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors
                  .black
                  .withValues(
                alpha: 0.05,
              ),
              blurRadius: 8,
              offset:
                  const Offset(
                0,
                2,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Padding(
              padding:
                  const EdgeInsets
                      .all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  // HEADER
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            const Color(
                          0xFFE8F5E9,
                        ),
                        child:
                            Text(
                          name
                                  .isNotEmpty
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
                            fontSize:
                                16,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            Column(
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
                                fontSize:
                                    14,
                              ),
                            ),
                            Text(
                              timeAgo,
                              style:
                                  TextStyle(
                                fontSize:
                                    11,
                                color: Colors
                                    .grey
                                    .shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              10,
                          vertical:
                              4,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              _tagColor(
                            tag,
                          ).withValues(
                            alpha:
                                0.1,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child:
                            Text(
                          tag,
                          style:
                              TextStyle(
                            color:
                                _tagColor(
                              tag,
                            ),
                            fontSize:
                                11,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // CONTENT
                  if (content
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      content,
                      style:
                          const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color:
                            Colors.black87,
                      ),
                      maxLines:
                          4,
                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // ====================================================
            // TEMPORARY LOCAL IMAGE
            // ====================================================

            if (temporaryImage !=
                null)
              ClipRRect(
                borderRadius:
                    const BorderRadius
                        .only(
                  bottomLeft:
                      Radius
                          .circular(
                    16,
                  ),
                  bottomRight:
                      Radius
                          .circular(
                    16,
                  ),
                ),
                child:
                    Image.file(
                  temporaryImage!,
                  width:
                      double.infinity,
                  height: 200,
                  fit:
                      BoxFit.cover,
                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      height: 200,
                      color: Colors
                          .grey
                          .shade100,
                      child:
                          const Center(
                        child: Text(
                          'Image unavailable',
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ====================================================
            // LIKE / COMMENT
            // ====================================================

            Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap:
                        onLike,
                    child:
                        Row(
                      children: [
                        Icon(
                          isLiked
                              ? Icons
                                  .favorite
                              : Icons
                                  .favorite_border,
                          color: isLiked
                              ? Colors
                                  .red
                              : Colors
                                  .grey
                                  .shade500,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          '$likeCount',
                          style:
                              TextStyle(
                            color: isLiked
                                ? Colors
                                    .red
                                : Colors
                                    .grey
                                    .shade500,
                            fontSize:
                                13,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 20,
                  ),

                  Row(
                    children: [
                      Icon(
                        Icons
                            .chat_bubble_outline,
                        color: Colors
                            .grey
                            .shade500,
                        size: 18,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        '$commentCount',
                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade500,
                          fontSize:
                              13,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Text(
                    'Read more',
                    style:
                        TextStyle(
                      fontSize:
                          12,
                      color:
                          primaryGreen,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(
    DateTime dt,
  ) {
    final Duration diff =
        DateTime.now()
            .difference(dt);

    if (diff.inSeconds <
        60) {
      return 'Just now';
    } else if (diff.inMinutes <
        60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours <
        24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays <
        7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
