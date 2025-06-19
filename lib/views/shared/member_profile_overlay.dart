import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/views/shared/member_profile_widget.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';

typedef HideCallback = void Function();

class MemberProfileOverlay {
  MemberProfileOverlayController? controller;
  HideCallback? hideCallback;

  void show({
    required BuildContext context,
    required Member member,
    required Member currentUser,
    required bool matchInsight,
    required bool hasFeatureMemberOnlineIndicator,
    HideCallback? hideCallback,
  }) {
    controller = showOverlay(
      context: context,
      member: member,
      currentUser: currentUser,
      matchInsight: matchInsight,
      hasFeatureMemberOnlineIndicator: hasFeatureMemberOnlineIndicator,
      hideCallback: hideCallback,
    );
  }

  void hide() {
    hideCallback?.call();
    controller?.close();
    controller = null;
  }

  MemberProfileOverlayController showOverlay({
    required BuildContext context,
    required Member member,
    required Member currentUser,
    required bool matchInsight,
    required bool hasFeatureMemberOnlineIndicator,
    HideCallback? hideCallback,
  }) {
    // get the state of the parent overlay
    final state = Overlay.of(context);
    this.hideCallback = hideCallback;
    // create the overlay
    // overlays don't have a parent such as a scaffold, so they need to be wrapped with
    // a material component
    final overlay = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.black.withOpacity(0.7),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(member.name!),
              actions: [
                IconButton(
                  onPressed: hide,
                  icon: Icon(Platform.isIOS
                      ? CupertinoIcons.xmark
                      : Icons.close_rounded),
                )
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: MemberProfileWidget(
                member: member,
                currentUser: currentUser,
                matchInsight: matchInsight,
                hasFeatureMemberOnlineIndicator:
                    hasFeatureMemberOnlineIndicator,
                premiumTapped: hide,
                profilePictureTapped: hide,
                verificationTapped: hide,
                reportMemberTapped: hide,
              ),
            ),
          ),
        );
      },
    );

    // insert the overlay into the current state
    state.insert(overlay);

    return MemberProfileOverlayController(
      close: () {
        overlay.remove();
        return true;
      },
    );
  }
}

// available functions
typedef CloseMemberProfileOverlay = bool Function();

@immutable
class MemberProfileOverlayController {
  final CloseMemberProfileOverlay close;

  const MemberProfileOverlayController({
    required this.close,
  });
}
