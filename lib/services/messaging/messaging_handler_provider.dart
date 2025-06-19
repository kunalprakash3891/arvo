import 'package:flutter/material.dart';
import 'package:arvo/services/caching/member_directory_provider.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/push_notifications/push_notification_provider.dart';

abstract class MessagingHandlerProvider {
  int get unreadMessageCount;
  set unreadMessageCount(int value);
  ValueNotifier<int> get unreadMessageCountUpdatedNotifier;
  set unreadMessageCountUpdatedNotifier(ValueNotifier<int> value);
  Future<void> initalise(
      ConnectionProvider connectionProvider,
      LocalStorageProvider localStorageProvider,
      MemberDirectoryProvider memberDirectoryProvider,
      PushNotificationProvider pushNotificationProvider);
  Future<void> loadSystemParameters();
  Future<bool> checkUserCanSendNewMessage();
  // Look for member in the member directory, fetch from API if not found.
  Future<Member> findOrFetchRecipient(int memberId);
  Future<bool> checkRecipientIsReachable(Member member);
  Future<void> updateNewMessageSentTimestamp();
  Future<int> refreshUnreadMessageCount();
  Future<void> toggleBlocked(Member member);
  Future<int> getLastMessageThreadId(int memberId);
  int get messageCountLimitPerThread;
  set messageCountLimitPerThread(int value);
  int get maxPendingMessageReplies;
  set maxPendingMessageReplies(int value);
}
