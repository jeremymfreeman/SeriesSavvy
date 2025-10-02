// -----------------------------------------------------------------------
// Filename: widget_app_drawer.dart
// Original Author: Dan Grissom
// Creation Date: 5/27/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the primary scaffold for the app.
//////////////////////////////////////////////////////////////////////////
// Imports
//////////////////////////////////////////////////////////////////////////
// Flutter external package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
// App relative file imports
import '../../screens/settings/screen_profile_edit.dart';
import '../../providers/provider_user_profile.dart';
import '../../screens/settings/screen_settings.dart';
import '../general/widget_profile_avatar.dart';
// Ensure this file contains the definition of ShowInspectScreen
import '../../providers/provider_auth.dart';
import '../../screens/changes/profile.dart'; // Import the new profile screen
import '../../screens/changes/watchlist.dart';
import '../../main.dart';
import '../../screens/changes/user_reviews.dart'; // Import UserReviewScreen

enum BottomNavSelection { HOME_SCREEN, ALTERNATE_SCREEN }

//////////////////////////////////////////////////////////////////
// StateLESS widget which only has data that is initialized when
// widget is created (cannot update except when re-created).
//////////////////////////////////////////////////////////////////
class WidgetAppDrawer extends StatelessWidget {
  ////////////////////////////////////////////////////////////////
  // Primary Flutter method overriden which describes the layout
  // and bindings for this widget.
  ////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final ProviderAuth _providerAuth = ref.watch(providerAuth);
          final ProviderUserProfile _providerUserProfile =
              ref.watch(providerUserProfile);
          return Column(
            children: <Widget>[
              AppBar(
                title: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ProfileAvatar(
                      radius: 15,
                      userImage: _providerUserProfile.userImage,
                      userWholeName: _providerUserProfile.wholeName,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Welcome ${_providerUserProfile.firstName}',
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
                automaticallyImplyLeading: false,
              ),
              ListTile(
                leading: Icon(Icons.home, color: Colors.white),
                title: Text('Home', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Close the drawer
                  Navigator.of(context).pop();
                  // Navigate to home
                  context.push('/');
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.person, color: Colors.white),
                title: Text('Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Close the drawer
                  Navigator.of(context).pop();
                  context.push(ProfileScreen
                      .routeName); // Navigate to the new profile screen
                },
              ),
              ListTile(
                leading: Icon(Icons.rate_review, color: Colors.white),
                title:
                    Text('My Reviews', style: TextStyle(color: Colors.white)),
                onTap: () {
                  context.push(UserReviewScreen.routeName);
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.tv, color: Colors.white),
              //   title:
              //       Text('Show Inspect', style: TextStyle(color: Colors.white)),
              //   onTap: () {
              //     // Close the drawer
              //     Navigator.of(context).pop();
              //     context.push(ShowInspectScreen
              //         .routeName); // Navigate to the show inspect screen
              //   },
              // ),
              ListTile(
                leading: Icon(Icons.access_time, color: Colors.white),
                title: Text('Watchlist', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Close the drawer
                  Navigator.of(context).pop();
                  context.push(WatchlistScreen.routeName);
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.white),
                title: Text('Settings', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Close the drawer
                  Navigator.of(context).pop();
                  context.push(ScreenProfileEdit.routeName);
                },
              ),
              ListTile(
                leading: Icon(Icons.spatial_audio_off, color: Colors.white),
                title: Text('Voice Settings',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Close the drawer
                  Navigator.of(context).pop();
                  context.push(ScreenSettings.routeName, extra: false);
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.white),
                title: Text('Logout', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _providerAuth.clearAuthedUserDetailsAndSignout();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
