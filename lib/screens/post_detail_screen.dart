import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ecoscan/services/notification_service.dart';

class PostDetailScreen
    extends StatefulWidget {
  final String postId;

  final Map<String, dynamic> data;

  // ============================================================
  // TEMPORARY LOCAL IMAGE
  // ============================================================

  final File? temporaryImage;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.data,
    this.temporaryImage,
  });

  @override
  State<PostDetailScreen>
      createState() =>
          _PostDetailScreenState();
}

class _PostDetailScreenState
    extends State<PostDetailScreen> {
  static const Color
      primaryGreen =
      Color(0xFF2E7D32);

  final TextEditingController
      _commentController =
      TextEditingController();

  final String currentUid =
      FirebaseAuth.instance
          .currentUser!
          .uid;

  bool _isSubmitting =
      false;

  bool _isDeleting =
      false;

  @override
  void dispose() {
    _commentController
        .dispose();

    super.dispose();
  }

  // ============================================================
  // DELETE POST
  //
  // IMPORTANT:
  // No Firebase Storage image deletion anymore.
  // ============================================================

  Future<void> _deletePost() async {
    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
        title:
            const Text(
          'Delete Post',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        content:
            const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),
            child:
                Text(
              'Cancel',
              style:
                  TextStyle(
                color: Colors
                    .grey
                    .shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  Colors.red,
              foregroundColor:
                  Colors.white,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  8,
                ),
              ),
            ),
            child:
                const Text(
              'Delete',
            ),
          ),
        ],
      ),
    );

    if (confirm !=
        true) {
      return;
    }

    setState(() {
      _isDeleting =
          true;
    });

    try {
      // ========================================================
      // DELETE COMMENTS
      // ========================================================

      final QuerySnapshot
          comments =
          await FirebaseFirestore
              .instance
              .collection(
                'posts',
              )
              .doc(
                widget.postId,
              )
              .collection(
                'comments',
              )
              .get();

      final WriteBatch batch =
          FirebaseFirestore
              .instance
              .batch();

      for (final DocumentSnapshot
          doc
          in comments.docs) {
        batch.delete(
          doc.reference,
        );
      }

      await batch.commit();

      // ========================================================
      // DELETE POST
      // ========================================================

      await FirebaseFirestore
          .instance
          .collection(
            'posts',
          )
          .doc(
            widget.postId,
          )
          .delete();

      if (mounted) {
        ScaffoldMessenger
            .of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Post deleted successfully',
            ),
            backgroundColor:
                primaryGreen,
          ),
        );

        Navigator.pop(
          context,
          true,
        );
      }
    } catch (e) {
      debugPrint(
        'Delete error: $e',
      );

      if (mounted) {
        ScaffoldMessenger
            .of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to delete post. Please try again.',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting =
              false;
        });
      }
    }
  }

  // ============================================================
  // SUBMIT COMMENT
  // ============================================================

  Future<void>
      _submitComment() async {
    final String text =
        _commentController
            .text
            .trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting =
          true;
    });

    try {
      final User user =
          FirebaseAuth.instance
              .currentUser!;

      final DocumentSnapshot
          userDoc =
          await FirebaseFirestore
              .instance
              .collection(
                'users',
              )
              .doc(
                user.uid,
              )
              .get();

      final String name =
          (userDoc.data()
                  as Map<String,
                      dynamic>?)?['name'] ??
              user.displayName ??
              'User';

      await FirebaseFirestore
          .instance
          .collection(
            'posts',
          )
          .doc(
            widget.postId,
          )
          .collection(
            'comments',
          )
          .add({
        'authorId':
            user.uid,
        'authorName':
            name,
        'text':
            text,
        'createdAt':
            FieldValue
                .serverTimestamp(),
      });

      await FirebaseFirestore
          .instance
          .collection(
            'posts',
          )
          .doc(
            widget.postId,
          )
          .update({
        'commentCount':
            FieldValue.increment(
          1,
        ),
      });

      final String
          postAuthorId =
          widget.data[
                  'authorId'] ??
              '';

      if (postAuthorId
          .isNotEmpty) {
        await NotificationService
            .sendCommentNotification(
          postAuthorId:
              postAuthorId,
          commenterName:
              name,
          commentText:
              text,
          postId:
              widget.postId,
        );
      }

      _commentController
          .clear();
    } catch (e) {
      debugPrint(
        'Comment error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting =
              false;
        });
      }
    }
  }

  // ============================================================
  // TOGGLE LIKE
  // ============================================================

  Future<void>
      _toggleLike(
    List likes,
  ) async {
    final DocumentReference
        ref =
        FirebaseFirestore
            .instance
            .collection(
              'posts',
            )
            .doc(
              widget.postId,
            );

    if (likes.contains(
      currentUid,
    )) {
      await ref.update({
        'likes':
            FieldValue
                .arrayRemove(
          [currentUid],
        ),
        'likeCount':
            FieldValue
                .increment(
          -1,
        ),
      });
    } else {
      await ref.update({
        'likes':
            FieldValue
                .arrayUnion(
          [currentUid],
        ),
        'likeCount':
            FieldValue
                .increment(
          1,
        ),
      });

      final String
          postAuthorId =
          widget.data[
                  'authorId'] ??
              '';

      if (postAuthorId
          .isEmpty) {
        return;
      }

      final DocumentSnapshot
          userDoc =
          await FirebaseFirestore
              .instance
              .collection(
                'users',
              )
              .doc(
                currentUid,
              )
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
        postAuthorId:
            postAuthorId,
        likerName:
            likerName,
        postContent:
            widget.data[
                    'content'] ??
                '',
        postId:
            widget.postId,
      );
    }
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

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
    } else {
      return '${diff.inDays}d ago';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final String name =
        widget.data[
                'authorName'] ??
            'User';

    final String content =
        widget.data[
                'content'] ??
            '';

    final String tag =
        widget.data[
                'tag'] ??
            'General';

    final bool isOwner =
        widget.data[
                'authorId'] ==
            currentUid;

    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF5F8F5,
      ),

      appBar: AppBar(
        backgroundColor:
            primaryGreen,
        foregroundColor:
            Colors.white,
        title:
            const Text(
          'Post',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          if (isOwner)
            _isDeleting
                ? const Padding(
                    padding:
                        EdgeInsets.all(
                      16,
                    ),
                    child:
                        SizedBox(
                      width:
                          20,
                      height:
                          20,
                      child:
                          CircularProgressIndicator(
                        color: Colors
                            .white,
                        strokeWidth:
                            2,
                      ),
                    ),
                  )
                : PopupMenuButton<
                    String>(
                    icon:
                        const Icon(
                      Icons
                          .more_vert,
                      color: Colors
                          .white,
                    ),
                    onSelected:
                        (value) {
                      if (value ==
                          'delete') {
                        _deletePost();
                      }
                    },
                    itemBuilder:
                        (context) =>
                            [
                      const PopupMenuItem(
                        value:
                            'delete',
                        child:
                            Row(
                          children: [
                            Icon(
                              Icons
                                  .delete_outline,
                              color: Colors
                                  .red,
                              size:
                                  20,
                            ),
                            SizedBox(
                              width:
                                  8,
                            ),
                            Text(
                              'Delete Post',
                              style:
                                  TextStyle(
                                color:
                                    Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
        ],
      ),

      body:
          Column(
        children: [
          Expanded(
            child:
                StreamBuilder<
                    DocumentSnapshot>(
              stream:
                  FirebaseFirestore
                      .instance
                      .collection(
                        'posts',
                      )
                      .doc(
                        widget
                            .postId,
                      )
                      .snapshots(),
              builder:
                  (
                context,
                postSnap,
              ) {
                final Map<
                        String,
                        dynamic>
                    postData =
                    postSnap
                            .data
                            ?.data()
                        as Map<String,
                            dynamic>? ??
                        widget.data;

                final List
                    likes =
                    postData[
                            'likes'] ??
                        [];

                final bool
                    isLiked =
                    likes.contains(
                  currentUid,
                );

                return CustomScrollView(
                  slivers: [
                    // ==================================================
                    // POST CARD
                    // ==================================================

                    SliverToBoxAdapter(
                      child:
                          Container(
                        margin:
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .white,
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
                                alpha:
                                    0.05,
                              ),
                              blurRadius:
                                  8,
                              offset:
                                  const Offset(
                                0,
                                2,
                              ),
                            ),
                          ],
                        ),
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .all(
                                16,
                              ),
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  // HEADER
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius:
                                            22,
                                        backgroundColor:
                                            const Color(
                                          0xFFE8F5E9,
                                        ),
                                        child:
                                            Text(
                                          name.isNotEmpty
                                              ? name[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style:
                                              const TextStyle(
                                            color:
                                                primaryGreen,
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize:
                                                18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width:
                                            10,
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
                                                    FontWeight.bold,
                                                fontSize:
                                                    15,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal:
                                                    8,
                                                vertical:
                                                    2,
                                              ),
                                              decoration:
                                                  BoxDecoration(
                                                color:
                                                    primaryGreen.withValues(
                                                  alpha:
                                                      0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                  10,
                                                ),
                                              ),
                                              child:
                                                  Text(
                                                tag,
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      primaryGreen,
                                                  fontSize:
                                                      11,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // CONTENT
                                  if (content
                                      .isNotEmpty) ...[
                                    const SizedBox(
                                      height:
                                          14,
                                    ),
                                    Text(
                                      content,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            15,
                                        height:
                                            1.6,
                                        color:
                                            Colors.black87,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // ==================================================
                            // TEMPORARY IMAGE
                            // ==================================================

                            if (widget
                                    .temporaryImage !=
                                null)
                              ClipRRect(
                                child:
                                    Image.file(
                                  widget
                                      .temporaryImage!,
                                  width:
                                      double.infinity,
                                  fit:
                                      BoxFit.cover,
                                  errorBuilder:
                                      (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return Container(
                                      height:
                                          250,
                                      color: Colors
                                          .grey
                                          .shade100,
                                      child:
                                          const Center(
                                        child:
                                            Text(
                                          'Image unavailable',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                            // ==================================================
                            // LIKE
                            // ==================================================

                            Padding(
                              padding:
                                  const EdgeInsets
                                      .all(
                                16,
                              ),
                              child:
                                  Column(
                                children: [
                                  const Divider(),
                                  const SizedBox(
                                    height:
                                        8,
                                  ),
                                  GestureDetector(
                                    onTap:
                                        () =>
                                            _toggleLike(
                                      likes,
                                    ),
                                    child:
                                        Row(
                                      children: [
                                        Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.grey,
                                          size:
                                              22,
                                        ),
                                        const SizedBox(
                                          width:
                                              6,
                                        ),
                                        Text(
                                          '${likes.length} likes',
                                          style:
                                              TextStyle(
                                            color:
                                                isLiked ? Colors.red : Colors.grey,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==================================================
                    // COMMENTS HEADER
                    // ==================================================

                    SliverToBoxAdapter(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              20,
                          vertical:
                              4,
                        ),
                        child:
                            Text(
                          'Comments',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize:
                                15,
                            color: Colors
                                .grey
                                .shade700,
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // COMMENTS
                    // ==================================================

                    StreamBuilder<
                        QuerySnapshot>(
                      stream:
                          FirebaseFirestore
                              .instance
                              .collection(
                                'posts',
                              )
                              .doc(
                                widget
                                    .postId,
                              )
                              .collection(
                                'comments',
                              )
                              .orderBy(
                                'createdAt',
                                descending:
                                    false,
                              )
                              .snapshots(),
                      builder:
                          (
                        context,
                        commentSnap,
                      ) {
                        if (commentSnap
                                .connectionState ==
                            ConnectionState
                                .waiting) {
                          return const SliverToBoxAdapter(
                            child:
                                Center(
                              child:
                                  Padding(
                                padding:
                                    EdgeInsets.all(
                                  20,
                                ),
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      primaryGreen,
                                ),
                              ),
                            ),
                          );
                        }

                        final List<
                                DocumentSnapshot>
                            comments =
                            commentSnap
                                    .data
                                    ?.docs ??
                                [];

                        if (comments
                            .isEmpty) {
                          return SliverToBoxAdapter(
                            child:
                                Padding(
                              padding:
                                  const EdgeInsets
                                      .all(
                                24,
                              ),
                              child:
                                  Center(
                                child:
                                    Text(
                                  'No comments yet.\nBe the first!',
                                  textAlign:
                                      TextAlign
                                          .center,
                                  style:
                                      TextStyle(
                                    color: Colors
                                        .grey
                                        .shade500,
                                    height:
                                        1.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return SliverList(
                          delegate:
                              SliverChildBuilderDelegate(
                            (
                              context,
                              index,
                            ) {
                              final Map<
                                      String,
                                      dynamic>
                                  c =
                                  comments[
                                          index]
                                      .data()!
                                      as Map<
                                          String,
                                          dynamic>;

                              final Timestamp?
                                  ts =
                                  c['createdAt']
                                      as Timestamp?;

                              final String
                                  authorName =
                                  c['authorName'] ??
                                      'User';

                              return Container(
                                margin:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      16,
                                  vertical:
                                      4,
                                ),
                                padding:
                                    const EdgeInsets
                                        .all(
                                  14,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                ),
                                child:
                                    Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    CircleAvatar(
                                      radius:
                                          16,
                                      backgroundColor:
                                          const Color(
                                        0xFFE8F5E9,
                                      ),
                                      child:
                                          Text(
                                        authorName
                                                .isNotEmpty
                                            ? authorName[0]
                                                .toUpperCase()
                                            : 'U',
                                        style:
                                            const TextStyle(
                                          color:
                                              primaryGreen,
                                          fontSize:
                                              12,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width:
                                          10,
                                    ),
                                    Expanded(
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                authorName,
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize:
                                                      13,
                                                ),
                                              ),
                                              const SizedBox(
                                                width:
                                                    8,
                                              ),
                                              Text(
                                                ts != null
                                                    ? _formatTime(
                                                        ts.toDate(),
                                                      )
                                                    : '',
                                                style:
                                                    TextStyle(
                                                  fontSize:
                                                      11,
                                                  color:
                                                      Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height:
                                                4,
                                          ),
                                          Text(
                                            c['text'] ??
                                                '',
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  13,
                                              height:
                                                  1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount:
                                comments.length,
                          ),
                        );
                      },
                    ),

                    const SliverToBoxAdapter(
                      child:
                          SizedBox(
                        height:
                            20,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ========================================================
          // COMMENT INPUT
          // ========================================================

          Container(
            padding:
                EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery
                      .of(context)
                  .viewInsets
                  .bottom +
                  12,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors
                      .black
                      .withValues(
                    alpha: 0.06,
                  ),
                  blurRadius:
                      8,
                  offset:
                      const Offset(
                    0,
                    -2,
                  ),
                ),
              ],
            ),
            child:
                Row(
              children: [
                Expanded(
                  child:
                      TextField(
                    controller:
                        _commentController,
                    decoration:
                        InputDecoration(
                      hintText:
                          'Write a comment...',
                      filled:
                          true,
                      fillColor:
                          const Color(
                        0xFFF5F8F5,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          25,
                        ),
                        borderSide:
                            BorderSide
                                .none,
                      ),
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            16,
                        vertical:
                            10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                GestureDetector(
                  onTap:
                      _isSubmitting
                          ? null
                          : _submitComment,
                  child:
                      Container(
                    width:
                        44,
                    height:
                        44,
                    decoration:
                        const BoxDecoration(
                      color:
                          primaryGreen,
                      shape:
                          BoxShape
                              .circle,
                    ),
                    child:
                        _isSubmitting
                            ? const Padding(
                                padding:
                                    EdgeInsets.all(
                                  12,
                                ),
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .send_rounded,
                                color:
                                    Colors.white,
                                size:
                                    20,
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
}
