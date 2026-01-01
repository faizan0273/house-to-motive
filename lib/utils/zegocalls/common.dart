// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit/zego_uikit.dart' as zego_uikit;

Widget customAvatarBuilder(
    BuildContext context,
    Size size,
    zego_uikit.ZegoUIKitUser? user,
    Map extraInfo,
    ) {
  if (user == null) {
    return CircleAvatar(
      radius: size.width / 2,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: size.width / 2,
        color: Colors.grey[700],
      ),
    );
  }

  return CachedNetworkImage(
    imageUrl: 'https://robohash.org/${user.id}.png',
    imageBuilder: (context, imageProvider) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    ),
    progressIndicatorBuilder: (context, url, downloadProgress) =>
        CircularProgressIndicator(value: downloadProgress.progress),
    errorWidget: (context, url, error) {
      return CircleAvatar(
        radius: size.width / 2,
        backgroundColor: Colors.grey[300],
        child: user.name.isNotEmpty
            ? Text(
                user.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: size.width / 2,
                  color: Colors.grey[700],
                ),
              )
            : Icon(
                Icons.person,
                size: size.width / 2,
                color: Colors.grey[700],
              ),
      );
    },
  );
}
