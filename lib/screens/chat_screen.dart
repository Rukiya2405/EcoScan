import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ecoscan/services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherName;
  final String otherUid;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherName,
    required this.otherUid,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  static const Color primaryGreen =
      Color(0xFF2E7D32);

  final TextEditingController
      _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final String currentUid =
      FirebaseAuth.instance.currentUser!.uid;

  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    final String text =
        _messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    try {
      final String currentName =
          FirebaseAuth.instance.currentUser
                  ?.displayName ??
              'User';

      // ADD MESSAGE
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': currentUid,
        'senderName': currentName,
        'text': text,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      // UPDATE LAST MESSAGE
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': text,
        'lastMessageTime':
            FieldValue.serverTimestamp(),
      });

      // SEND NOTIFICATION
      await NotificationService
          .sendMessageNotification(
        toUserId: widget.otherUid,
        senderName: currentName,
        messageText: text,

        // IMPORTANT
        chatId: widget.chatId,
      );

      // SCROLL TO BOTTOM
      Future.delayed(
        const Duration(
          milliseconds: 100,
        ),
        () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController
                  .position.maxScrollExtent,
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.easeOut,
            );
          }
        },
      );
    } catch (e) {
      debugPrint(
        'Send message error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(DateTime dt) {
    final String hour =
        dt.hour.toString().padLeft(2, '0');

    final String minute =
        dt.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F8F5),

      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  Colors.white.withValues(
                alpha: 0.3,
              ),
              child: Text(
                widget.otherName.isNotEmpty
                    ? widget.otherName[0]
                        .toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.otherName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ======================================================
          // MESSAGES
          // ======================================================

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy(
                    'createdAt',
                    descending: false,
                  )
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

                final List<DocumentSnapshot>
                    messages =
                    snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons
                              .waving_hand_rounded,
                          size: 48,
                          color:
                              Colors.grey.shade300,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          'Say hello to ${widget.otherName}!',
                          style: TextStyle(
                            color: Colors
                                .grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller:
                      _scrollController,
                  padding:
                      const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder:
                      (context, index) {
                    final Map<String, dynamic>
                        msg =
                        messages[index]
                                .data()!
                            as Map<String,
                                dynamic>;

                    final bool isMe =
                        msg['senderId'] ==
                            currentUid;

                    final Timestamp? ts =
                        msg['createdAt']
                            as Timestamp?;

                    final String time =
                        ts != null
                            ? _formatTime(
                                ts.toDate(),
                              )
                            : '';

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin:
                            const EdgeInsets.only(
                          bottom: 8,
                        ),
                        constraints:
                            BoxConstraints(
                          maxWidth:
                              MediaQuery.of(
                                    context,
                                  ).size.width *
                                  0.72,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe
                                  ? CrossAxisAlignment
                                      .end
                                  : CrossAxisAlignment
                                      .start,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: isMe
                                    ? primaryGreen
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius
                                        .only(
                                  topLeft:
                                      const Radius
                                          .circular(
                                    16,
                                  ),
                                  topRight:
                                      const Radius
                                          .circular(
                                    16,
                                  ),
                                  bottomLeft:
                                      Radius.circular(
                                    isMe
                                        ? 16
                                        : 4,
                                  ),
                                  bottomRight:
                                      Radius.circular(
                                    isMe
                                        ? 4
                                        : 16,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors
                                        .black
                                        .withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 4,
                                    offset:
                                        const Offset(
                                      0,
                                      2,
                                    ),
                                  ),
                                ],
                              ),
                              child: Text(
                                msg['text'] ??
                                    '',
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors
                                    .grey.shade500,
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

          // ======================================================
          // MESSAGE INPUT
          // ======================================================

          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom:
                  MediaQuery.of(context)
                      .viewInsets
                      .bottom +
                  12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(
                    alpha: 0.06,
                  ),
                  blurRadius: 8,
                  offset:
                      const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _messageController,
                    textInputAction:
                        TextInputAction.send,
                    onSubmitted: (_) =>
                        _sendMessage(),
                    decoration:
                        InputDecoration(
                      hintText:
                          'Type a message...',
                      filled: true,
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
                            BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending
                      ? null
                      : _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration:
                        const BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding:
                                EdgeInsets.all(
                              12,
                            ),
                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .send_rounded,
                            color:
                                Colors.white,
                            size: 20,
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
