import 'package:flutter/material.dart';

class AppBarX extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const AppBarX({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null ? Text(title!) : null,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
    );
  }
}
