import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AvatarWithStatus extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool? activeStatus;
  final String? lastActiveLabel;

  const AvatarWithStatus({
    super.key,
    this.imageUrl,
    this.radius = 25,
    this.activeStatus,
    this.lastActiveLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey[300],
              backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                  ? NetworkImage(imageUrl!)
                  : null,
              child: (imageUrl == null || imageUrl!.isEmpty)
                  ? Icon(CupertinoIcons.person, size: radius)
                  : null,
            ),
            if (activeStatus == true)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: radius * 0.35,
                  height: radius * 0.35,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                  ),
                ),
              ),
          ],
        ),
        if (activeStatus == false && lastActiveLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(lastActiveLabel!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ),
      ],
    );
  }
}
