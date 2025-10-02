// -----------------------------------------------------------------------
// Filename: screen_home.dart
// Original Author: Dan Grissom
// Creation Date: 10/31/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the primary app bar.

//////////////////////////////////////////////////////////////////////////
// Imports
//////////////////////////////////////////////////////////////////////////
// Flutter imports

// Flutter external package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// App relative file imports
import '../../util/message_display/snackbar.dart';
import '../../screens/changes/search.dart'; // Add this import

class WidgetPrimaryAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  // Constant parameters passedin
  final Widget title;
  final List<Widget>? actionButtons;
  bool inCurrentMeeting;

  WidgetPrimaryAppBar({Key? key, required this.title, this.actionButtons, this.inCurrentMeeting = false})
      : super(key: key);
  // UserData().updateProfileImage();

  @override
  ConsumerState<WidgetPrimaryAppBar> createState() => _PrimaryAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

//////////////////////////////////////////////////////////////////
// The actual STATE which is managed by the above widget.
//////////////////////////////////////////////////////////////////
class _PrimaryAppBar extends ConsumerState<WidgetPrimaryAppBar> {
  // The "instance variables" managed in this state
  var _isInit = true;

  ////////////////////////////////////////////////////////////////
  // Gets the current state of the providers for consumption on
  // this page
  ////////////////////////////////////////////////////////////////
  _init() async {
    // Get providers
  }

  ////////////////////////////////////////////////////////////////
  // Runs the following code once upon initialization
  ////////////////////////////////////////////////////////////////
  @override
  void didChangeDependencies() {
    // If first time running this code, update provider settings
    if (_isInit) {
      _init();
    }

    // Now initialized; run super method
    _isInit = false;
    super.didChangeDependencies();
  }

  ////////////////////////////////////////////////////////////////
  // Primary Flutter method overriden which describes the layout
  // and bindings for this widget.
  ////////////////////////////////////////////////////////////////
@override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: widget.title,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white), // Change hamburger menu button to white
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color.fromARGB(255, 255, 255, 255)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchUserScreen(),
              ),
            );
          },
        ),
        if (widget.actionButtons != null)
          ...widget.actionButtons!.map((e) {
            return e;
          }).toList()
      ],
    );
  }
}
