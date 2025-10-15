import 'package:arvo/constants/localised_assets.dart';
import 'package:flutter/cupertino.dart';

// TODO: Credit these images.
Map<String, String> avatarPlaceholderMap = {
  'a': avatarPlaceholderBeach,
  'b': avatarPlaceholderGrampians,
  'c': avatarPlaceholderHardwareLane,
  'd': avatarPlaceholderHouse,
  'e': avatarPlaceholderLibrary,
  'f': avatarPlaceholderBeach,
  'g': avatarPlaceholderGrampians,
  'h': avatarPlaceholderHardwareLane,
  'i': avatarPlaceholderHouse,
  'j': avatarPlaceholderLibrary,
  'k': avatarPlaceholderBeach,
  'l': avatarPlaceholderGrampians,
  'm': avatarPlaceholderHardwareLane,
  'n': avatarPlaceholderHouse,
  'o': avatarPlaceholderLibrary,
  'p': avatarPlaceholderBeach,
  'q': avatarPlaceholderGrampians,
  'r': avatarPlaceholderHardwareLane,
  's': avatarPlaceholderHouse,
  't': avatarPlaceholderLibrary,
  'u': avatarPlaceholderBeach,
  'v': avatarPlaceholderGrampians,
  'w': avatarPlaceholderHardwareLane,
  'x': avatarPlaceholderHouse,
  'y': avatarPlaceholderLibrary,
  'z': avatarPlaceholderBeach,
};

AssetImage getAvatarPlaceholderImage(String? memberName) {
  if (memberName == null || memberName.isEmpty) {
    return AssetImage(avatarPlaceholderMap.values.first);
  }

  return AssetImage(avatarPlaceholderMap[memberName[0].toLowerCase()] ??
      avatarPlaceholderMap.values.first);
}
