import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../user_service.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfileAvatar;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  const AppTopBar({super.key, required this.title, this.showProfileAvatar = true, this.actions, this.bottom});

  @override
  Widget build(BuildContext context) {
    final user = UserService().currentUser;
    final allActions = <Widget>[];
    if (actions != null) allActions.addAll(actions!);
    if (showProfileAvatar) {
      allActions.add(
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: GestureDetector(
            onTap: () {},
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: user?.profilePhotoPath != null
                  ? ClipOval(
                      child: Image.file(
                        File(user!.profilePhotoPath!),
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      user?.username[0].toUpperCase() ?? 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ),
        ),
      );
    }

    return AppBar(
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ),
      backgroundColor: DesignTokens.primary,
      actions: allActions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}
