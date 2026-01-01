import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:house_to_motive/controller/getchat_controller.dart';
import 'package:house_to_motive/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit/zego_uikit.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.name,
    this.pic,
    required this.chatRoomId,
    this.currentUserId,
    this.urls,
    required this.receiverEmail,
    required this.receiverId
  });

  final String name;
  final String? pic;
  final String receiverEmail;
  final String chatRoomId;
  final String? currentUserId;
  final String? urls;
  final String receiverId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController messageController = TextEditingController();
  bool isBlocked = false;
  bool isBlockedByOtherUser = false;

  @override
  void initState() {
    super.initState();
    checkIfUserIsBlocked();
  }

  void checkIfUserIsBlocked() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .get();

    DocumentSnapshot otherUserDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.receiverId)
        .get();

    // Get blocked users list, if it doesn't exist, set to empty list
    List<dynamic> myBlockedUsers =
        (currentUserDoc.data() as Map<String, dynamic>?)?["blockedUsers"] ?? [];
    List<dynamic> theirBlockedUsers =
        (otherUserDoc.data() as Map<String, dynamic>?)?["blockedUsers"] ?? [];

    setState(() {
      isBlocked = myBlockedUsers.contains(widget.receiverId);
      isBlockedByOtherUser = theirBlockedUsers.contains(currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    messageController.text = widget.urls ?? '';
    final GetChatSController getChatSController = Get.put(GetChatSController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xffF6F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xff025B8F),
        leadingWidth: 2.h,
        leading: IconButton(
          onPressed: () {
            log('message');
            Get.back();
          },
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 16.px,
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                  widget.pic!.isEmpty
                      ? 'https://static.vecteezy.com/system/resources/thumbnails/002/534/006/small/social-media-chatting-online-blank-profile-picture-head-and-body-icon-people-standing-icon-grey-background-free-vector.jpg'
                      : widget.pic!,
                  scale: 1.0),
            ),
            SizedBox(width: 1.h),
            widget.name.length > 8
                ? Text(
                    widget.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.px,
                    ),
                  )
                : Text(
                    widget.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.px,
                    ),
                  ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                showReportOptions(context, widget.receiverId);
              } else if (value == 'block') {
                showBlockConfirmationDialog(widget.receiverId);
              } else if (value == 'unblock') {
                unblockUser(widget.receiverId);
              }
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: isBlocked ? 'unblock' : 'block',
                child: Row(
                  children: [
                    Icon(isBlocked ? Icons.check_circle : Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text(isBlocked ? "Unblock" : "Block"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Report"),
                  ],
                ),
              ),
            ],
          ),
          // PopupMenuButton<String>(
          //   onSelected: (value) {
          //     if (value == 'block') {
          //       showBlockConfirmationDialog(widget.receiverId);
          //     } else if (value == 'unblock') {
          //       unblockUser(widget.receiverId);
          //     }
          //   },
          //   icon: const Icon(Icons.more_vert, color: Colors.white),
          //   itemBuilder: (context) => [
          //     PopupMenuItem(
          //       value: isBlocked ? 'unblock' : 'block',
          //       child: Row(
          //         children: [
          //           Icon(isBlocked ? Icons.check_circle : Icons.block, color: Colors.red),
          //           SizedBox(width: 8),
          //           Text(isBlocked ? "Unblock" : "Block"),
          //         ],
          //       ),
          //     ),
          //     PopupMenuItem(
          //       value: 'report',
          //       child: Row(
          //         children: const [
          //           Icon(Icons.report, color: Colors.red),
          //           SizedBox(width: 8),
          //           Text("Report"),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chatRoom")
                  .doc(widget.chatRoomId)
                  .collection("chats")
                  .orderBy("time", descending: false)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No messages"),
                    );
                  }
                  snapshot.data!.docs.last;
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      Map<String, dynamic> map = snapshot.data!.docs[index]
                          .data() as Map<String, dynamic>;
                      return messages(size, map, context);
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                } else {
                  return Center(child: const CircularProgressIndicator());
                }
              },
            ),
          ),
          // Container(
          //   color: const Color(0xffFFFFFF),
          //   height: 10.h,
          //   child: isBlocked
          //       ? Center(
          //     child: Text(
          //       "You have blocked this user",
          //       style: TextStyle(color: Colors.red, fontSize: 14.px),
          //     ),
          //   )
          //       : Padding(
          //     padding: EdgeInsets.symmetric(horizontal: 1.6.h),
          //     child: Row(
          //       children: [
          //         Expanded(
          //           child: TextField(
          //             controller: messageController,
          //             style: TextStyle(
          //               fontSize: 15.px,
          //               color: const Color(0xff8A8B8F),
          //             ),
          //             decoration: InputDecoration(
          //               hintText: 'Send a message...',
          //               hintStyle: TextStyle(
          //                 color: const Color(0xff8A8B8F),
          //                 fontWeight: FontWeight.normal,
          //                 fontSize: 15.px,
          //               ),
          //               fillColor: const Color(0xffF1F1F3),
          //               isCollapsed: true,
          //               filled: true,
          //               contentPadding: EdgeInsets.symmetric(
          //                 horizontal: 2.h,
          //                 vertical: 1.h,
          //               ),
          //               border: const OutlineInputBorder(
          //                 borderSide: BorderSide.none,
          //               ),
          //             ),
          //           ),
          //         ),
          //         SizedBox(width: 1.h),
          //         GestureDetector(
          //           onTap: () {
          //             onSendMessage();
          //           },
          //           child: Image.asset(
          //             'assets/pngs/send.png',
          //             height: 4.5.h,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          messageInputField()
        ],
      ),
    );
  }

  Widget messageInputField() {
    if (isBlocked) {
      return Center(
        child: Text(
          "You have blocked this user. Unblock to continue the conversation.",
          style: TextStyle(color: Colors.red, fontSize: 14.px),
          textAlign: TextAlign.center,
        ),
      );
    } else if (isBlockedByOtherUser) {
      return Center(
        child: Text(
          "This user has restricted communication with you. You cannot send messages.",
          style: TextStyle(color: Colors.red, fontSize: 14.px),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.6.h),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                style: TextStyle(
                  fontSize: 15.px,
                  color: const Color(0xff8A8B8F),
                ),
                decoration: InputDecoration(
                  hintText: 'Send a message...',
                  hintStyle: TextStyle(
                    color: const Color(0xff8A8B8F),
                    fontWeight: FontWeight.normal,
                    fontSize: 15.px,
                  ),
                  fillColor: const Color(0xffF1F1F3),
                  isCollapsed: true,
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 2.h,
                    vertical: 1.h,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 1.h),
            GestureDetector(
              onTap: () {
                onSendMessage();
              },
              child: Image.asset(
                'assets/pngs/send.png',
                height: 4.5.h,
              ),
            ),
          ],
        ),
      );
    }
  }

  String formattedTime =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  Future<void> blockUser(String blockedUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .update({
        "blockedUsers": FieldValue.arrayUnion([blockedUserId])
      });

      setState(() {
        isBlocked = true;
      });

      log("User $blockedUserId blocked successfully.");
    } catch (e) {
      log("Error blocking user: $e");
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .update({
        "blockedUsers": FieldValue.arrayRemove([blockedUserId])
      });

      setState(() {
        isBlocked = false;
      });

      log("User $blockedUserId unblocked successfully.");
    } catch (e) {
      log("Error unblocking user: $e");
    }
  }


  void showBlockConfirmationDialog(String blockedUserId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Block User"),
        content: const Text("Are you sure you want to block this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              blockUser(blockedUserId);
              Navigator.pop(context);
            },
            child: const Text("Block", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  void onSendMessage() async {
    String messageText = messageController.text;
    if (messageText.isNotEmpty) {
      String currentUserID = FirebaseAuth.instance.currentUser!.uid;

      Map<String, dynamic> messageData = {
        "sendBy": currentUserID,
        "receiveBy": widget.receiverEmail,
        "message": messageText,
        "type": "text",
        "time": FieldValue.serverTimestamp(),
      };

      DocumentReference messageRef = await FirebaseFirestore.instance
          .collection("chatRoom")
          .doc(widget.chatRoomId)
          .collection("chats")
          .add(messageData);
      updateActiveChatListInFirestore(widget.receiverEmail);
      updateOtherActiveChatListInFirestore(
          FirebaseAuth.instance.currentUser!.uid);
      updateLastMessage(messageText, formattedTime.toString());
      messageController.clear();

      Set<String> uniqueUserIds = {currentUserID, widget.receiverEmail};

      List<String> allUserIds = uniqueUserIds.toList();

      for (String userId in allUserIds) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          List<String> userChatRooms =
              List<String>.from(userSnapshot["chatRooms"] ?? []);

          userChatRooms.add(widget.chatRoomId);

          await FirebaseFirestore.instance
              .collection("users")
              .doc(userId)
              .update({
            "chatRooms": userChatRooms,
          });
        } else {
          log("User document does not exist for ID: $userId");
        }
      }

      log("All users in the chat room: $allUserIds");

      messageController.clear();
    } else {
      log("Enter some text");
    }
  }

  Future<void> updateActiveChatListInFirestore(String? activeChatUser) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        "activeChatUser": FieldValue.arrayUnion([activeChatUser])
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error updating active chat user list: $e");
      }
    }
  }

  Future<void> updateLastMessage(
      String? lastMessage, String? lastMessageTime) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.receiverEmail)
          .update({
        "lastMessage": lastMessage,
        'lastMessageTime': lastMessageTime,
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error updating active chat user list: $e");
      }
    }
  }

  void showReportOptions(BuildContext context, String reportedUserId) {
    List<String> reportReasons = [
      "Nudity or sexual activity",
      "Hate speech or symbols",
      "Violence or dangerous organizations",
      "Harassment or bullying",
      "False information",
      "Spam",
      "Scam or fraud",
      "Intellectual property violation",
      "Suicide or self-injury",
      "Other"
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Wrap(
          children: reportReasons
              .map((reason) => ListTile(
            title: Text(reason),
            onTap: () {
              Navigator.pop(context);
              showReportConfirmation(context, reportedUserId, reason);
            },
          ))
              .toList(),
        );
      },
    );
  }

  void showReportConfirmation(BuildContext context, String reportedUserId, String reason) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Report"),
          content: Text("Are you sure you want to report this user for '$reason'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                submitReport(reportedUserId, reason);
                Navigator.pop(context);
              },
              child: const Text("Report", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> submitReport(String reportedUserId, String reason) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection("reports").add({
      "reportedBy": currentUserId,
      "reportedUser": reportedUserId,
      "reason": reason,
      "timestamp": FieldValue.serverTimestamp(),
    });
    Utils().ToastMessage("Your report has been submitted. Thank you for helping us keep the community safe.");
  }

  Future<void> updateOtherActiveChatListInFirestore(
      String? activeChatUser) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.receiverEmail)
          .update({
        "activeChatUser":
            FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid])
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error updating active chat user list: $e");
      }
    }
  }

  Widget sendCallButton({
    required bool isVideoCall,
    required String inviteeUserID,
    void Function(String code, String message, List<String>)? onCallFinished,
  }) {
    return ZegoSendCallInvitationButton(
      isVideoCall: isVideoCall,
      invitees: [
        ZegoUIKitUser(id: inviteeUserID, name: widget.name)
      ],
      resourceID: 'zego_call',
      icon: ButtonIcon(
        backgroundColor: Colors.transparent,
        icon: isVideoCall
            ? const Icon(
                Icons.video_call,
                size: 24,
                color: Colors.white,
              )
            : const Icon(
                Icons.call,
                size: 20,
                color: Colors.white,
              ),
      ),
      iconSize: const Size(35, 35),
      buttonSize: const Size(50, 50),
      onPressed: onCallFinished,
    );
  }

  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
    bool isSender = map["sendBy"] == FirebaseAuth.instance.currentUser!.uid;

    return Container(
      width: size.width,
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.6.h, vertical: 0.6.h),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.8,
          ),
          padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 1.6.h),
          decoration: BoxDecoration(
            color: isSender ? const Color(0xff4DA6FF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            map["message"],
            style: GoogleFonts.inter(
              color: isSender ? Colors.white : const Color(0xff3C3F41),
              fontSize: 14.px,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
