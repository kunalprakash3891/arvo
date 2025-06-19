import 'package:flutter/material.dart';
import 'package:nifty_three_bp_app_base/api/multiple_photo.dart';
import 'package:nifty_three_bp_app_base/api/sms_verification.dart';
import 'package:nifty_three_bp_app_base/constants/reporting.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:nifty_three_bp_app_base/enums/member_photo_type.dart';
import 'package:nifty_three_bp_app_base/enums/photo_verification_status_type.dart';
import 'package:nifty_three_bp_app_base/extensions/string.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/http_response_codes.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/member_blocked.dart';
import 'package:nifty_three_bp_app_base/api/member_favourite.dart';
import 'package:nifty_three_bp_app_base/api/member_report_request.dart';
import 'package:nifty_three_bp_app_base/api/members_get_request.dart';
import 'package:nifty_three_bp_app_base/api/message_delete_thread_request.dart';
import 'package:nifty_three_bp_app_base/api/message_mark_read_unread_request.dart';
import 'package:nifty_three_bp_app_base/api/message_send_new_message_request.dart';
import 'package:nifty_three_bp_app_base/api/message_star_unstar_request.dart';
import 'package:nifty_three_bp_app_base/api/messages_get_request.dart';
import 'package:nifty_three_bp_app_base/api/notification_update_request.dart';
import 'package:nifty_three_bp_app_base/api/notifications_get_request.dart';
import 'package:nifty_three_bp_app_base/api/posts_get_request.dart';
import 'package:nifty_three_bp_app_base/api/sign_up_availability.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field_post_request.dart';
import 'package:arvo/utilities/ip.dart';
import 'package:app_base/extensions/string_extensions.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  int appDemoUserId = 44;
  String appDemoUserName = 'appdemo';
  int testDemoUserId = 77;
  int testSuspendedUserId = 78;
  String testSuspendedUserName = 'testsuspended';
  int helloAdminUserId = 36;
  String testMobilePhoneNumber = '+61490391264';

  final provider = ConnectionService.arvo();
  provider.initalise(arvoTestURL);
  WidgetsFlutterBinding.ensureInitialized();

  Future<Member?> logInAppDemo() async {
    await provider.logIn(
      username: appDemoUserName,
      password: '5UUdF0&Mdt3AoyDzkIElg^qL',
    );
    return provider.currentUser;
  }

  Future<Member?> logInTestDemo() async {
    await provider.logIn(
      username: 'testdemo',
      password: 'B4gC86*#SZXcBhpiPQRi9Dyp',
    );
    return provider.currentUser;
  }

  Future<Member?> logInTestSuspended() async {
    await provider.logIn(
      username: testSuspendedUserName,
      password: 'SK6nr%cMvVh8&pqp#778fl(L',
    );
    return provider.currentUser;
  }

  group('[Authentication]', () {
    test('User should be null after initialisation', () {
      expect(provider.currentUser, null);
    });

    test('Attempting to retrieve the current user should fail if not logged in',
        () async {
      try {
        await provider.getCurrentUser();
      } on Exception catch (e) {
        expect(e, isA<GenericUserAccessException>());
      }
    });

    test('Should not be able to log in with an invalid user', () async {
      try {
        await provider.logIn(
            username: 'invaliduser@invaliddomain.com',
            password: 'invalidpassword');
      } on Exception catch (e) {
        expect(e, isA<GenericRequestException>());
      }
    });

    test(
        'Should not be able to log in with a valid user but incorrect password',
        () async {
      try {
        await provider.logIn(
            username: appDemoUserName, password: 'invalidpassword');
      } on Exception catch (e) {
        expect(e, isA<GenericRequestException>());
      }
    });

    test('Should be able to log in with a valid user', () async {
      final user = await logInAppDemo();
      expect(user, isNotNull);
      expect(user!.id, appDemoUserId);
      expect(user.name, 'hello! Bot');
    });

    test('Authorisation token should be valid', () async {
      await logInAppDemo();
      expect(await provider.isAuthorisationTokenValid(), true);
    });

    test('Should be able to log out and log in again', () async {
      await provider.logOut();
      await logInAppDemo();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.id, appDemoUserId);
      expect(user.name, 'hello! Bot');
    });
  });

  group('[Profile]', () {
    test('Retrieve XProfile data', () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      final xProfileFields = await provider.getXProfileFields();
      expect(xProfileFields, isNotNull);
      expect(xProfileFields.length, isNot(0));

      final xProfileGroups = await provider.getXProfileGroups();
      expect(xProfileGroups, isNotNull);
      expect(xProfileGroups.length, isNot(0));
    });

    test("Retrieve and update 'What you need to know about me' field",
        () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      final xProfileFields =
          await provider.getXProfileField(xProfileFieldWhatYouNeedToKnow);
      expect(xProfileFields, isNotNull);
      expect(xProfileFields.length, 1);
      expect(xProfileFields.first.id, xProfileFieldWhatYouNeedToKnow);

      const fieldValue = 'Field updated by hello! automated testing.';
      var xProfileFieldPostRequest = XProfileFieldPostRequest(
        fieldId: xProfileFieldWhatYouNeedToKnow,
        userId: appDemoUserId,
        value: fieldValue,
      );

      final xProfileFieldData =
          await provider.updateXProfileFieldData(xProfileFieldPostRequest);

      expect(xProfileFieldData, isNotNull);
      expect(xProfileFieldData.length, 1);
      expect(xProfileFieldData.first.fieldId, 347);
      expect(xProfileFieldData.first.userId, appDemoUserId);
      expect(xProfileFieldData.first.value.unserialized!.first, fieldValue);
    });

    test("Retrieve and update 'Location' field (selectbox)", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      final xProfileFields =
          await provider.getXProfileField(xProfileFieldLocation);
      expect(xProfileFields, isNotNull);
      expect(xProfileFields.length, 1);
      expect(xProfileFields.first.id, xProfileFieldLocation);

      final memberField = provider.currentUser!.xProfile!.groups
          .where((group) => group.id == xProfileGroupAboutMe)
          .first
          .fields
          .where((field) => field.id == xProfileFieldLocation)
          .first;

      // Update location to "Nadi, Fiji" if "Côte d'Ivoire" or vice versa.
      var fieldValue = "Nadi, Fiji";
      if (memberField.value!.unserialized!.first == fieldValue) {
        fieldValue = "Côte d'Ivoire";
      }
      var xProfileFieldPostRequest = XProfileFieldPostRequest(
        fieldId: xProfileFieldLocation,
        userId: appDemoUserId,
        value: fieldValue.addEscapeCharacters(),
      );

      var xProfileFieldData =
          await provider.updateXProfileFieldData(xProfileFieldPostRequest);

      expect(xProfileFieldData, isNotNull);
      expect(xProfileFieldData.length, 1);
      expect(xProfileFieldData.first.fieldId, xProfileFieldLocation);
      expect(xProfileFieldData.first.userId, appDemoUserId);
      expect(xProfileFieldData.first.value.unserialized!.first, fieldValue);

      // Now swap the values, update and check. .
      fieldValue = "Nadi, Fiji";
      if (xProfileFieldData.first.value.unserialized!.first == fieldValue) {
        fieldValue = "Côte d'Ivoire";
      }
      xProfileFieldPostRequest = XProfileFieldPostRequest(
        fieldId: xProfileFieldLocation,
        userId: appDemoUserId,
        value: fieldValue.addEscapeCharacters(),
      );

      xProfileFieldData =
          await provider.updateXProfileFieldData(xProfileFieldPostRequest);

      expect(xProfileFieldData, isNotNull);
      expect(xProfileFieldData.length, 1);
      expect(xProfileFieldData.first.fieldId, xProfileFieldLocation);
      expect(xProfileFieldData.first.userId, appDemoUserId);
      expect(xProfileFieldData.first.value.unserialized!.first, fieldValue);
    });

    test("Retrieve and update 'Hobbies' field (checkbox)", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      final xProfileFields =
          await provider.getXProfileField(xProfileFieldHobbies);
      expect(xProfileFields, isNotNull);
      expect(xProfileFields.length, 1);
      expect(xProfileFields.first.id, xProfileFieldHobbies);

      final memberField = provider.currentUser!.xProfile!.groups
          .where((group) => group.id == xProfileGroupInterests)
          .first
          .fields
          .where((field) => field.id == xProfileFieldHobbies)
          .first;

      const fieldValueIDontHaveAnyHobbies = "I don't have any hobbies";
      const fieldValueArtsAndCrafts = "Arts & Craft";
      const fieldValueHangingWithFriends = "Hanging Out with Friends";
      const fieldValueTravelling = "Travelling";

      // Update value to "Arts & Craft, Hanging Out with Friends, Travelling" if
      // "I don't have any hobbies" or vice versa.
      var fieldValue = fieldValueIDontHaveAnyHobbies;
      if (memberField.value!.unserialized!.first
              .removeEscapeCharacters()
              .parseHTML() ==
          fieldValueIDontHaveAnyHobbies) {
        fieldValue = [
          fieldValueArtsAndCrafts,
          fieldValueHangingWithFriends,
          fieldValueTravelling
        ].join(',');
      }
      var xProfileFieldPostRequest = XProfileFieldPostRequest(
        fieldId: xProfileFieldHobbies,
        userId: appDemoUserId,
        value: fieldValue.addEscapeCharacters(),
      );

      var xProfileFieldData =
          await provider.updateXProfileFieldData(xProfileFieldPostRequest);

      expect(xProfileFieldData, isNotNull);
      expect(xProfileFieldData.length, 1);
      expect(xProfileFieldData.first.fieldId, xProfileFieldHobbies);
      expect(xProfileFieldData.first.userId, appDemoUserId);
      if (fieldValue == fieldValueIDontHaveAnyHobbies) {
        expect(
            xProfileFieldData.first.value.unserialized!.first
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueIDontHaveAnyHobbies);
      }
      if (fieldValue ==
          [
            fieldValueArtsAndCrafts,
            fieldValueHangingWithFriends,
            fieldValueTravelling
          ].join(',')) {
        expect(
            xProfileFieldData.first.value.unserialized!.first
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueArtsAndCrafts);
        expect(
            xProfileFieldData.first.value.unserialized![1]
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueHangingWithFriends);
        expect(
            xProfileFieldData.first.value.unserialized![2]
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueTravelling);
      }

      // Now swap the values, update and check.
      fieldValue = fieldValueIDontHaveAnyHobbies;
      if (xProfileFieldData.first.value.unserialized!.first
              .toString()
              .removeEscapeCharacters()
              .parseHTML() ==
          fieldValueIDontHaveAnyHobbies) {
        fieldValue = [
          fieldValueArtsAndCrafts,
          fieldValueHangingWithFriends,
          fieldValueTravelling
        ].join(',');
      }
      xProfileFieldPostRequest = XProfileFieldPostRequest(
        fieldId: xProfileFieldHobbies,
        userId: appDemoUserId,
        value: fieldValue.addEscapeCharacters(),
      );

      xProfileFieldData =
          await provider.updateXProfileFieldData(xProfileFieldPostRequest);

      expect(xProfileFieldData, isNotNull);
      expect(xProfileFieldData.length, 1);
      expect(xProfileFieldData.first.fieldId, xProfileFieldHobbies);
      expect(xProfileFieldData.first.userId, appDemoUserId);
      if (fieldValue == fieldValueIDontHaveAnyHobbies) {
        expect(
            xProfileFieldData.first.value.unserialized!.first
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueIDontHaveAnyHobbies);
      } else {
        expect(
            xProfileFieldData.first.value.unserialized!.first
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueArtsAndCrafts);
        expect(
            xProfileFieldData.first.value.unserialized![1]
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueHangingWithFriends);
        expect(
            xProfileFieldData.first.value.unserialized![2]
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueTravelling);
      }
    });

    test("Retrieve and update 'Main Language' field (multiselectbox)",
        () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      final xProfileFields =
          await provider.getXProfileField(xProfileFieldMainLanguage);
      expect(xProfileFields, isNotNull);
      expect(xProfileFields.length, 1);
      expect(xProfileFields.first.id, xProfileFieldMainLanguage);

      final memberField = provider.currentUser!.xProfile!.groups
          .where((group) => group.id == xProfileGroupBackground)
          .first
          .fields
          .where((field) => field.id == xProfileFieldMainLanguage)
          .first;

      const fieldValueFijian = "Fijian";
      const fieldValueArabic = "Arabic";
      const fieldValueFijiHindi = "Fiji Hindi";
      const fieldValueVietnamese = "Vietnamese";

      // Update value to "Arts & Craft, Hanging Out with Friends, Travelling" if
      // "I don't have any hobbies" or vice versa.
      var fieldValue = fieldValueFijian;
      if (memberField.value!.unserialized!.first
              .removeEscapeCharacters()
              .parseHTML() ==
          fieldValueFijian) {
        fieldValue = [
          fieldValueArabic,
          fieldValueFijiHindi,
          fieldValueVietnamese
        ].join(',');
      }
      var xProfileFieldPostRequest = XProfileFieldPostRequest(
        fieldId: xProfileFieldMainLanguage,
        userId: appDemoUserId,
        value: fieldValue.addEscapeCharacters(),
      );

      var xProfileFieldData =
          await provider.updateXProfileFieldData(xProfileFieldPostRequest);

      expect(xProfileFieldData, isNotNull);
      expect(xProfileFieldData.length, 1);
      expect(xProfileFieldData.first.fieldId, xProfileFieldMainLanguage);
      expect(xProfileFieldData.first.userId, appDemoUserId);
      if (fieldValue == fieldValueFijian) {
        expect(
            xProfileFieldData.first.value.unserialized!.first
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueFijian);
      }
      if (fieldValue ==
          [fieldValueArabic, fieldValueFijiHindi, fieldValueVietnamese]
              .join(',')) {
        expect(
            xProfileFieldData.first.value.unserialized!.first
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueArabic);
        expect(
            xProfileFieldData.first.value.unserialized![1]
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueFijiHindi);
        expect(
            xProfileFieldData.first.value.unserialized![2]
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueVietnamese);
      }

      // Now swap the values, update and check.
      fieldValue = fieldValueFijian;
      if (xProfileFieldData.first.value.unserialized!.first
              .toString()
              .removeEscapeCharacters()
              .parseHTML() ==
          fieldValueFijian) {
        fieldValue = [
          fieldValueArabic,
          fieldValueFijiHindi,
          fieldValueVietnamese
        ].join(',');
      }
      xProfileFieldPostRequest = XProfileFieldPostRequest(
        fieldId: xProfileFieldMainLanguage,
        userId: appDemoUserId,
        value: fieldValue.addEscapeCharacters(),
      );

      xProfileFieldData =
          await provider.updateXProfileFieldData(xProfileFieldPostRequest);

      expect(xProfileFieldData, isNotNull);
      expect(xProfileFieldData.length, 1);
      expect(xProfileFieldData.first.fieldId, xProfileFieldMainLanguage);
      expect(xProfileFieldData.first.userId, appDemoUserId);
      if (fieldValue == fieldValueFijian) {
        expect(
            xProfileFieldData.first.value.unserialized!.first
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueFijian);
      } else {
        expect(
            xProfileFieldData.first.value.unserialized!.first
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueArabic);
        expect(
            xProfileFieldData.first.value.unserialized![1]
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueFijiHindi);
        expect(
            xProfileFieldData.first.value.unserialized![2]
                .toString()
                .removeEscapeCharacters()
                .parseHTML(),
            fieldValueVietnamese);
      }
    });

    test('Upload profile picture', () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // Check if we can upload first.
      final result = await provider.getPhotoVerificationStatus(appDemoUserId);
      expect(result, isNotNull);
      expect(result.status, const TypeMatcher<PhotoVerificationStatusType>());

      if (result.status == PhotoVerificationStatusType.approved) {
        final memberAvatar = await provider
            .updateUserProfilePicture('test/resources/hello_frangipani.png');
        expect(memberAvatar, isNotNull);
      }
    });
  });

  group('[Members]', () {
    test('Retrieve members', () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }
      var membersGetRequest = const MembersGetRequest(
        page: 1,
        perPage: 2,
      );
      var results = await provider.getMembers(membersGetRequest);
      expect(results, isNotNull);
      expect(results.length, 2);

      membersGetRequest = const MembersGetRequest(
        page: 2,
        perPage: 2,
      );
      results = await provider.getMembers(membersGetRequest);
      expect(results, isNotNull);
      expect(results.length, 2);

      membersGetRequest = const MembersGetRequest(
          page: 1,
          perPage: 1,
          searchKey: "search key that should not return any results");
      results = await provider.getMembers(membersGetRequest);
      expect(results, isNotNull);
      expect(results.length, 0);
    });

    test("Retrieve a specific member", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      final otherUser = await provider.getMember(testDemoUserId);
      expect(otherUser, isNotNull);
      expect(otherUser.id, testDemoUserId);
    });
  });

  group('[Messaging]', () {
    test('Retrieve messages', () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      var messagesGetRequest = MessagesGetRequest(
        userId: appDemoUserId,
        page: 1,
        perPage: 10,
        messagesPage: 1,
        messagesPerPage: 10,
      );
      var results = await provider.getMessages(messagesGetRequest);
      expect(results, isNotNull);

      messagesGetRequest = MessagesGetRequest(
        userId: appDemoUserId,
        page: 1,
        perPage: 10,
        messagesPage: 1,
        messagesPerPage: 10,
        searchKey: "search key that should not return any results",
      );

      results = await provider.getMessages(messagesGetRequest);
      expect(results, isNotNull);
      expect(results.length, 0);
    });

    test(
        'Send a new message, star/unstar, mark read/unread, reply, and then delete the message thread',
        () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      const subject = 'Thread generated by hello! automated testing';
      const messageContent = 'Ah - Aurora borealis!?';
      const messageReply =
          'At this time of year, at this time of day, in this part of the country, localized entirely within your kitchen!?';

      // start a new thread
      var messageSendNewMessageRequest = MessageSendNewMessageRequest(
        id: 0,
        subject: subject,
        message: messageContent,
        recipients: [testDemoUserId],
        senderId: appDemoUserId,
      );
      var results = await provider.sendNewMessage(messageSendNewMessageRequest);
      expect(results, isNotNull);
      expect(results.length, 1);
      expect(results.first.messages.length, 1);
      expect(results.first.messages.first.message.raw, messageContent);
      expect(results.first.recipients.length, 2);
      expect(results.first.subject.raw, subject);
      await Future.delayed(const Duration(seconds: 10));

      int threadId = results.first.id;

      // retrieve the sent box and check our sent message exists
      var messagesGetRequest = MessagesGetRequest(
        userId: appDemoUserId,
        box: 'sentbox',
        page: 1,
        perPage: 10,
        messagesPage: 1,
        messagesPerPage: 10,
      );
      results = await provider.getMessages(messagesGetRequest);
      expect(results, isNotNull);
      expect(results.length, isNot(0));
      expect(
          results.where((messageThread) => messageThread.id == threadId).length,
          1);

      // star the sent message
      var messageStarUnstarRequest = MessageStarUnstarRequest(
        id: results.first.messages.first.id,
      );
      final starResults =
          await provider.starOrUnstarMessage(messageStarUnstarRequest);
      expect(starResults, isNotNull);
      expect(starResults.length, 1);
      expect(starResults.first.isStarred, true);

      // unstar the sent message
      final unstarResults =
          await provider.starOrUnstarMessage(messageStarUnstarRequest);
      expect(unstarResults, isNotNull);
      expect(unstarResults.length, 1);
      expect(unstarResults.first.isStarred, false);

      // mark the thread as read
      var messageMarkReadRequest = MessageMarkReadUnreadRequest(
        threadId: threadId,
        userId: appDemoUserId,
        read: true,
        unread: false,
      );
      var messageThread =
          await provider.markMessageThreadReadOrUnread(messageMarkReadRequest);
      expect(messageThread.first.unreadCount, 0);

      // mark the thread as unread
      var messageMarkUnreadRequest = MessageMarkReadUnreadRequest(
        threadId: threadId,
        userId: appDemoUserId,
        read: false,
        unread: true,
      );
      messageThread = await provider
          .markMessageThreadReadOrUnread(messageMarkUnreadRequest);
      expect(messageThread.first.unreadCount, 1);

      // send a reply
      messageSendNewMessageRequest = MessageSendNewMessageRequest(
        id: threadId,
        message: messageReply,
        recipients: [testDemoUserId],
        senderId: appDemoUserId,
      );
      results = await provider.sendNewMessage(messageSendNewMessageRequest);
      expect(results, isNotNull);
      expect(results.length, 1);
      expect(results.first.messages.length, 2);
      expect(results.first.messages.first.message.raw, messageContent);
      expect(results.first.messages[1].message.raw, messageReply);
      expect(results.first.recipients.length, 2);
      expect(results.first.subject.raw, subject);
      await Future.delayed(const Duration(seconds: 10));

      // delete the message thread
      final messageDeleteThreadRequest = MessageDeleteThreadRequest(
        id: threadId,
        userId: appDemoUserId,
      );

      final deleteResult =
          await provider.deleteMessageThread(messageDeleteThreadRequest);
      expect(deleteResult, isNotNull);
      expect(deleteResult.deleted, true);
      expect(deleteResult.previous.id, threadId);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));

  group('[Posts]', () {
    test('Retrieve posts and post media', () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      var postSearchRequest = const PostsGetRequest(
        id: 0,
        page: 1,
        perPage: 10,
        sticky: false,
      );
      final results = await provider.getPosts(postSearchRequest);
      expect(results, isNotNull);
      expect(results.length, isNot(0));

      // get associated media for the first post
      final postMediaId = results.first.featuredMedia;
      if (postMediaId == 0) {
        expect(results.first.featuredMediaURL, isNull);
      } else {
        final postMedia = await provider.getPostMedia(postMediaId);
        expect(postMedia, isNotNull);
        expect(postMedia.guid.rendered, isNotEmpty);
      }
    });
  });

  group('[Notifications]', () {
    test(
        'Retrieve previous notifications if any, then mark one notification as new, and then mark it again as notified',
        () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      var notificationsGetRequest = NotificationsGetRequest(
        page: 1,
        perPage: 10,
        userId: appDemoUserId,
        isNew: false,
      );
      var results = await provider.getNotifications(notificationsGetRequest);
      expect(results, isNotNull);
      if (results.isNotEmpty) {
        expect(results.where((notification) => notification.isNew).length, 0);

        // mark the first notification as new
        final notificationId = results.first.id;

        var notificationUpdateRequest = NotificationUpdateRequest(
          id: notificationId,
          isNew: true,
        );
        results = await provider.updateNotification(notificationUpdateRequest);
        expect(results, isNotNull);
        expect(results.length, 1);
        expect(results.where((notification) => notification.isNew).length, 1);

        // now mark the notification as notified
        notificationUpdateRequest = NotificationUpdateRequest(
          id: notificationId,
          isNew: false,
        );
        results = await provider.updateNotification(notificationUpdateRequest);
        expect(results, isNotNull);
        expect(results.length, 1);
        expect(results.where((notification) => notification.isNew).length, 0);
      }
    });
  });

  group('[Member Blocking/Unblocking]', () {
    test(
        "Check a member's blocked status, block (if unblocked), unblock (if blocked), fetch and check blocked list",
        () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // get any member
      var membersGetRequest = const MembersGetRequest(
        page: 1,
        perPage: 5,
      );
      var results = await provider.getMembers(membersGetRequest);
      expect(results, isNotNull);
      expect(results.length, 5);

      // ignore AppDemo and admin if it's in the result set
      final memberId = results
          .where((member) =>
              member.id != appDemoUserId && member.id != helloAdminUserId)
          .first
          .id;

      // check the blocked status
      var isBlocked =
          await provider.getMemberBlockedStatus(appDemoUserId, memberId);

      if (isBlocked) {
        // member is already blocked, get the blocked list and check they are in the list
        const blockedMembersGetRequest = BlockedMembersGetRequest(
          page: 1,
          perPage: 25,
        );
        var blockedMembers =
            await provider.getBlockedMembers(blockedMembersGetRequest);
        expect(blockedMembers, isNotNull);
        expect(blockedMembers.length, isNot(0));
        expect(
            blockedMembers
                .where(
                    (blockedMember) => blockedMember.blockedUserId == memberId)
                .length,
            1);

        // unblock them
        final memberUnblocked = await provider.unblockMember(memberId);
        expect(memberUnblocked, isNotNull);
        expect(memberUnblocked.unblocked, true);
        expect(memberUnblocked.previous.blockedUserId, memberId);
        await Future.delayed(const Duration(seconds: 10));

        //check they have been removed from the blocked list
        blockedMembers =
            await provider.getBlockedMembers(blockedMembersGetRequest);
        expect(blockedMembers, isNotNull);
        expect(
            blockedMembers
                .where(
                    (blockedMember) => blockedMember.blockedUserId == memberId)
                .length,
            0);

        //block them again
        final memberBlocked = await provider.blockMember(memberId);
        expect(memberBlocked, isNotNull);
        expect(memberBlocked.userId, appDemoUserId);
        expect(memberBlocked.blockedUserId, memberId);
        await Future.delayed(const Duration(seconds: 10));
      } else {
        // member is not blocked, get the blocked list and check they aren't in the list
        const blockedMembersGetRequest = BlockedMembersGetRequest(
          page: 1,
          perPage: 25,
        );
        var blockedMembers =
            await provider.getBlockedMembers(blockedMembersGetRequest);
        expect(blockedMembers, isNotNull);
        expect(
            blockedMembers
                .where(
                    (blockedMember) => blockedMember.blockedUserId == memberId)
                .length,
            0);

        //block them
        final memberBlocked = await provider.blockMember(memberId);
        expect(memberBlocked, isNotNull);
        expect(memberBlocked.userId, appDemoUserId);
        expect(memberBlocked.blockedUserId, memberId);
        await Future.delayed(const Duration(seconds: 10));

        // get the blocked list and check they are in the list
        blockedMembers =
            await provider.getBlockedMembers(blockedMembersGetRequest);
        expect(blockedMembers, isNotNull);
        expect(blockedMembers.length, isNot(0));
        expect(
            blockedMembers
                .where(
                    (blockedMember) => blockedMember.blockedUserId == memberId)
                .length,
            1);

        // unblock them again
        final memberUnblocked = await provider.unblockMember(memberId);
        expect(memberUnblocked, isNotNull);
        expect(memberUnblocked.unblocked, true);
        expect(memberUnblocked.previous.blockedUserId, memberId);
        await Future.delayed(const Duration(seconds: 10));
      }
    });

    test(
        "Get blocked by another member, check that we can no longer search, access the member directly, or message that member",
        () async {
      if (provider.currentUser != null) {
        await provider.logOut();
      }

      // log in as blocking member and check AppDemo is not blocked, if blocked, unblock
      var blockingMember = await logInTestDemo();
      expect(blockingMember, isNotNull);
      expect(blockingMember!.id, testDemoUserId);

      // check the blocked status
      final isBlocked = await provider.getMemberBlockedStatus(
          blockingMember.id, appDemoUserId);

      // unblock if blocked
      if (isBlocked) {
        final memberUnblocked = await provider.unblockMember(appDemoUserId);
        expect(memberUnblocked, isNotNull);
        expect(memberUnblocked.unblocked, true);
        expect(memberUnblocked.previous.blockedUserId, appDemoUserId);
        await Future.delayed(const Duration(seconds: 10));
      }

      await provider.logOut();

      // log in as AppDemo
      var appDemoUser = await logInAppDemo();
      expect(appDemoUser, isNotNull);
      expect(appDemoUser!.id, appDemoUserId);

      // not blocked, so we should be able to get the member directly or via search
      var member = await provider.getMember(blockingMember.id);
      expect(member, isNotNull);
      expect(member.id, blockingMember.id);

      var membersGetRequest = MembersGetRequest(
        searchKey: member.userLogin,
        page: 1,
        perPage: 25,
      );
      var members = await provider.getMembers(membersGetRequest);
      expect(members, isNotNull);
      expect(members.length, isNonZero);
      expect(
          members.where((member) => member.id == blockingMember!.id).length, 1);

      // we should be able to message the member
      const subject = 'Thread generated by hello! automated testing';
      const messageContent =
          "This message should be received successfully because I haven't been blocked.";
      const messageReply =
          "This message should also be received successfully, because I was blocked and now I'm unblocked again.";

      // start a new thread
      var messageSendNewMessageRequest = MessageSendNewMessageRequest(
        id: 0,
        subject: subject,
        message: messageContent,
        recipients: [blockingMember.id],
        senderId: appDemoUserId,
      );
      var results = await provider.sendNewMessage(messageSendNewMessageRequest);
      expect(results, isNotNull);
      expect(results.length, 1);
      expect(results.first.messages.length, 1);
      expect(results.first.messages.first.message.raw, messageContent);
      expect(results.first.recipients.length, 2);
      expect(results.first.subject.raw, subject);
      await Future.delayed(const Duration(seconds: 10));

      int threadId = results.first.id;

      // retrieve the sent box and check our sent message exists
      var messagesGetRequest = MessagesGetRequest(
        userId: appDemoUserId,
        box: 'sentbox',
        page: 1,
        perPage: 10,
        messagesPage: 1,
        messagesPerPage: 10,
      );
      results = await provider.getMessages(messagesGetRequest);
      expect(results, isNotNull);
      expect(results.length, isNot(0));
      expect(
          results.where((messageThread) => messageThread.id == threadId).length,
          1);

      // now log out, then log in as blocking member and block AppDemo
      await provider.logOut();
      expect(provider.token, null);
      expect(provider.currentUser, null);

      // log in as blocking member
      blockingMember = await logInTestDemo();
      expect(blockingMember, isNotNull);
      expect(blockingMember!.id, testDemoUserId);

      // block AppDemo
      final memberBlocked = await provider.blockMember(appDemoUserId);
      expect(memberBlocked, isNotNull);
      expect(memberBlocked.userId, blockingMember.id);
      expect(memberBlocked.blockedUserId, appDemoUserId);
      await Future.delayed(const Duration(seconds: 10));

      // log out
      await provider.logOut();
      expect(provider.token, null);
      expect(provider.currentUser, null);

      // log in again as AppDemo, check blocking member can no longer be accessed
      appDemoUser = await logInAppDemo();
      expect(appDemoUser, isNotNull);
      expect(appDemoUser!.id, appDemoUserId);

      // now blocked, so we should not be able to get the member directly or via members directory
      try {
        member = await provider.getMember(blockingMember.id);
      } on Exception catch (e) {
        expect(e, isA<InvalidUserException>());
      }

      membersGetRequest = MembersGetRequest(
        searchKey: blockingMember.userLogin,
        page: 1,
        perPage: 25,
      );
      members = await provider.getMembers(membersGetRequest);
      expect(members, isNotNull);
      expect(
          members.where((member) => member.id == blockingMember!.id).length, 0);

      // should not be able to send a reply to our earlier message thread
      try {
        messageSendNewMessageRequest = MessageSendNewMessageRequest(
          id: threadId,
          message: messageReply,
          recipients: [testDemoUserId],
          senderId: appDemoUserId,
        );
        results = await provider.sendNewMessage(messageSendNewMessageRequest);
      } on Exception catch (e) {
        expect(e, isA<BadRequestResponseException>());
        final badRequestResponse =
            (e as BadRequestResponseException).badRequestResponse;
        expect(badRequestResponse.code, 'block_users_reply_restricted');
      }

      // now log out, then log in as blocking member and unblock AppDemo
      await provider.logOut();
      expect(provider.token, null);
      expect(provider.currentUser, null);

      // log in as blocking member
      blockingMember = await logInTestDemo();
      expect(blockingMember, isNotNull);
      expect(blockingMember!.id, testDemoUserId);

      // unblock AppDemo
      final memberUnblocked = await provider.unblockMember(appDemoUserId);
      expect(memberUnblocked, isNotNull);
      expect(memberUnblocked.previous.userId, blockingMember.id);
      expect(memberUnblocked.previous.blockedUserId, appDemoUserId);
      await Future.delayed(const Duration(seconds: 10));

      // log out
      await provider.logOut();
      expect(provider.token, null);
      expect(provider.currentUser, null);

      // log in again as AppDemo, we should be able to access the blocking member again
      appDemoUser = await logInAppDemo();
      expect(appDemoUser, isNotNull);
      expect(appDemoUser!.id, appDemoUserId);

      member = await provider.getMember(blockingMember.id);
      expect(member, isNotNull);
      expect(member.id, blockingMember.id);

      membersGetRequest = MembersGetRequest(
        searchKey: member.userLogin,
        page: 1,
        perPage: 25,
      );
      members = await provider.getMembers(membersGetRequest);
      expect(members, isNotNull);
      expect(members.length, isNonZero);
      expect(
          members.where((member) => member.id == blockingMember!.id).length, 1);

      // send a reply to previous message thread
      messageSendNewMessageRequest = MessageSendNewMessageRequest(
        id: threadId,
        message: messageReply,
        recipients: [testDemoUserId],
        senderId: appDemoUserId,
      );
      results = await provider.sendNewMessage(messageSendNewMessageRequest);
      expect(results, isNotNull);
      expect(results.length, 1);
      expect(results.first.messages.length, 2);
      expect(results.first.messages.first.message.raw, messageContent);
      expect(results.first.messages[1].message.raw, messageReply);
      expect(results.first.recipients.length, 2);
      expect(results.first.subject.raw, subject);
      await Future.delayed(const Duration(seconds: 10));
    });
  }, timeout: const Timeout(Duration(minutes: 2)));

  group('[Member Suspension]', () {
    test("Check AppDemo is not suspended", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // check the blocked status
      var isSuspended = await provider.getMemberSuspendedStatus(appDemoUserId);
      expect(isSuspended, false);
    });

    test("Check that a suspended user cannot log in", () async {
      if (provider.currentUser != null) {
        await provider.logOut();
      }

      try {
        await logInTestSuspended();
      } on Exception catch (e) {
        expect(e, isA<BadRequestResponseException>());
        final badRequestResponse =
            (e as BadRequestResponseException).badRequestResponse;
        expect(badRequestResponse.code, '[jwt_auth] bpmts_suspended_user');
        expect(badRequestResponse.data!.status, httpBadResponseCodeForbidden);
      }
    });

    test("Check that a suspended user's profile cannot be accessed", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // we should not be able to get the member directly or via search
      try {
        await provider.getMember(testSuspendedUserId);
      } on Exception catch (e) {
        expect(e, isA<InvalidUserException>());
      }

      var membersGetRequest = MembersGetRequest(
        searchKey: testSuspendedUserName,
        page: 1,
        perPage: 25,
      );
      var members = await provider.getMembers(membersGetRequest);
      expect(members, isNotNull);
      expect(members.where((member) => member.id == testSuspendedUserId).length,
          0);
    });
  });

  group('[Reports]', () {
    test("Submit a member report", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // get any member
      var membersGetRequest = const MembersGetRequest(
        page: 1,
        perPage: 5,
      );
      var results = await provider.getMembers(membersGetRequest);
      expect(results, isNotNull);
      expect(results.length, 5);

      // ignore AppDemo and admin if it's in the result set
      final memberId = results
          .where((member) =>
              member.id != appDemoUserId && member.id != helloAdminUserId)
          .first
          .id;

      final ip = await getPublicIP();

      var memberReportRequest = MemberReportRequest(
        memberId: memberId,
        userId: appDemoUserId,
        category: reportCategoryProfileContent,
        subject: 'Auto-generated Report',
        message: 'Submitted by hello! automated testing.',
        name: provider.currentUser!.name!,
        email: 'appdemo@hellofiji.dating',
        ip: ip,
      );

      try {
        final reported = await provider.reportMember(memberReportRequest);
        expect(reported, isNotNull);
        expect(reported, true);
      } on Exception catch (e) {
        expect(e, isA<DuplicateReportException>());
      }
    });
  });

  group('[Favourites]', () {
    test(
        "Check if a member is in our favourites list, add (if they are not), remove (if they are), fetch and check favourites list",
        () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // get any member
      var membersGetRequest = const MembersGetRequest(
        page: 1,
        perPage: 5,
      );
      var results = await provider.getMembers(membersGetRequest);
      expect(results, isNotNull);
      expect(results.length, 5);

      // ignore AppDemo and admin if it's in the result set
      final memberId = results
          .where((member) =>
              member.id != appDemoUserId && member.id != helloAdminUserId)
          .first
          .id;

      // check the favourite status
      var isFavourite = await provider.getMemberFavouriteStatus(memberId);

      if (isFavourite) {
        // member is already in our favourites list, get the favourites list and check they are in the list
        const memberFavouritesGetRequest = MemberFavouritesGetRequest(
          page: 1,
          perPage: 25,
        );
        var favouriteMembers =
            await provider.getFavouriteMembers(memberFavouritesGetRequest);
        expect(favouriteMembers, isNotNull);
        expect(favouriteMembers.length, isNot(0));
        expect(
            favouriteMembers
                .where((favouriteMember) =>
                    favouriteMember.favouriteUserId == memberId)
                .length,
            1);

        // remove them from our favourites list
        final memberFavouriteRemoved =
            await provider.removeFavouriteMember(memberId);
        expect(memberFavouriteRemoved, isNotNull);
        expect(memberFavouriteRemoved.deleted, true);
        expect(memberFavouriteRemoved.previous.favouriteUserId, memberId);
        expect(memberFavouriteRemoved.previous.member, isNotNull);
        expect(memberFavouriteRemoved.previous.member?.id, memberId);
        await Future.delayed(const Duration(seconds: 10));

        //check they have been removed from our favourites list
        favouriteMembers =
            await provider.getFavouriteMembers(memberFavouritesGetRequest);
        expect(favouriteMembers, isNotNull);
        expect(
            favouriteMembers
                .where((favouriteMember) =>
                    favouriteMember.favouriteUserId == memberId)
                .length,
            0);

        //add them again
        final memberFavourite = await provider.addFavouriteMember(memberId);
        expect(memberFavourite, isNotNull);
        expect(memberFavourite.userId, appDemoUserId);
        expect(memberFavourite.favouriteUserId, memberId);
        expect(memberFavourite.member, isNotNull);
        expect(memberFavourite.member?.id, memberId);
        await Future.delayed(const Duration(seconds: 10));
      } else {
        // member is not not in our favourites list, get the favourites list and check they aren't in the list
        const memberFavouritesGetRequest = MemberFavouritesGetRequest(
          page: 1,
          perPage: 25,
        );
        var favouriteMembers =
            await provider.getFavouriteMembers(memberFavouritesGetRequest);
        expect(favouriteMembers, isNotNull);
        expect(
            favouriteMembers
                .where((favouriteMember) => favouriteMember.id == memberId)
                .length,
            0);

        // add them to our favourites list
        final memberFavourite = await provider.addFavouriteMember(memberId);
        expect(memberFavourite, isNotNull);
        expect(memberFavourite.userId, appDemoUserId);
        expect(memberFavourite.favouriteUserId, memberId);
        expect(memberFavourite.member, isNotNull);
        expect(memberFavourite.member?.id, memberId);
        await Future.delayed(const Duration(seconds: 10));

        // get the favourites list and check they are in the list
        favouriteMembers =
            await provider.getFavouriteMembers(memberFavouritesGetRequest);
        expect(favouriteMembers, isNotNull);
        expect(favouriteMembers.length, isNot(0));
        expect(
            favouriteMembers
                .where((favouriteMember) =>
                    favouriteMember.favouriteUserId == memberId)
                .length,
            1);

        // remove them from our favourites list
        final memberFavouriteRemoved =
            await provider.removeFavouriteMember(memberId);
        expect(memberFavouriteRemoved, isNotNull);
        expect(memberFavouriteRemoved.deleted, true);
        expect(memberFavouriteRemoved.previous.favouriteUserId, memberId);
        expect(memberFavouriteRemoved.previous.member, isNotNull);
        expect(memberFavouriteRemoved.previous.member?.id, memberId);
        await Future.delayed(const Duration(seconds: 10));
      }
    });

    test(
        "Get added as a favourite by another member, check that we can see the other member in our favourited by list",
        () async {
      if (provider.currentUser != null) {
        await provider.logOut();
      }

      // log in as favouriting member and check AppDemo is not a favourite, if is favourite, then remove favourite
      var favouritingMember = await logInTestDemo();
      expect(favouritingMember, isNotNull);
      expect(favouritingMember!.id, testDemoUserId);

      // check the favourite status
      var favourite = await provider.getMemberFavouriteStatus(appDemoUserId);

      // remove favourite, if favourite
      if (favourite) {
        final memberFavouriteRemoved =
            await provider.removeFavouriteMember(appDemoUserId);
        expect(memberFavouriteRemoved, isNotNull);
        expect(memberFavouriteRemoved.deleted, true);
        expect(memberFavouriteRemoved.previous.favouriteUserId, appDemoUserId);
        expect(memberFavouriteRemoved.previous.member?.userLogin.toLowerCase(),
            appDemoUserName);
        await Future.delayed(const Duration(seconds: 10));
      }

      await provider.logOut();

      // log in as AppDemo
      var appDemoUser = await logInAppDemo();
      expect(appDemoUser, isNotNull);
      expect(appDemoUser!.id, appDemoUserId);

      // not favourited, so we should not find favouriting member in the favourited by list
      const memberFavouritesGetRequest = MemberFavouritesGetRequest(
        page: 1,
        perPage: 25,
      );
      var favouritedByMembers =
          await provider.getFavouritedByMembers(memberFavouritesGetRequest);
      expect(favouritedByMembers, isNotNull);
      expect(
          favouritedByMembers
              .where((favouritedByMember) =>
                  favouritedByMember.member.id == favouritingMember!.id)
              .length,
          0);

      // favourited by member status should return false
      favourite = await provider.getFavouritedByMemberStatus(testDemoUserId);
      expect(favourite, false);

      await provider.logOut();

      // log in as favouriting member and add AppDemo as a favourite
      favouritingMember = await logInTestDemo();
      expect(favouritingMember, isNotNull);
      expect(favouritingMember!.id, testDemoUserId);

      final memberFavourite = await provider.addFavouriteMember(appDemoUserId);
      expect(memberFavourite, isNotNull);
      expect(memberFavourite.userId, testDemoUserId);
      expect(memberFavourite.favouriteUserId, appDemoUserId);
      expect(memberFavourite.member, isNotNull);
      expect(memberFavourite.member?.id, appDemoUserId);
      await Future.delayed(const Duration(seconds: 10));

      await provider.logOut();

      // log in as AppDemo
      appDemoUser = await logInAppDemo();
      expect(appDemoUser, isNotNull);
      expect(appDemoUser!.id, appDemoUserId);

      // now favourited, so we should find favouriting member in the favourited by list
      favouritedByMembers =
          await provider.getFavouritedByMembers(memberFavouritesGetRequest);
      expect(favouritedByMembers, isNotNull);
      expect(
          favouritedByMembers
              .where((favouritedByMember) =>
                  favouritedByMember.member.id == favouritingMember!.id)
              .length,
          1);

      // favourited by member status should return true
      favourite = await provider.getFavouritedByMemberStatus(testDemoUserId);
      expect(favourite, true);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));

  group('[Debounce Disposable Email Checking]', () {
    test("Check valid (non-disposable) email", () async {
      // Log out if logged in, we do should not to be logged in for this test.
      if (provider.currentUser != null) {
        await provider.logOut();
      }
      // Should return false.
      final isDisposable = await provider.checkDisposableEmail(
          'niftythreecreative@gmail.com', false);
      expect(isDisposable, false);
    });

    test("Check invalid (disposable) email", () async {
      // Log out if logged in, we do should not to be logged in for this test.
      if (provider.currentUser != null) {
        await provider.logOut();
      }
      // Should return true.
      final isDisposable =
          await provider.checkDisposableEmail('disposable@gufum.com', false);
      expect(isDisposable, true);
    });

    test("Check error response", () async {
      // Log out if logged in, we do should not to be logged in for this test.
      if (provider.currentUser != null) {
        await provider.logOut();
      }
      try {
        await provider.checkDisposableEmail('1234567890', false);
      } on Exception catch (e) {
        expect(e, isA<GenericRequestException>());
      }
    });

    test("Check forced ignore exceptions", () async {
      // Log out if logged in, we do should not to be logged in for this test.
      if (provider.currentUser != null) {
        await provider.logOut();
      }
      // Should return false.
      var isDisposable =
          await provider.checkDisposableEmail('1234567890', true);
      expect(isDisposable, false);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));

  group('[Sign Up]', () {
    test("Check if currently non-registered user login returns as available",
        () async {
      // Log out if logged in, we do should not to be logged in for this test.
      if (provider.currentUser != null) {
        await provider.logOut();
      }

      const signUpAvailabilityGetRequest = SignUpAvailabilityGetRequest(
          userLogin: 'thisusernameisnotregistered');
      final results =
          await provider.checkSignUpAvailability(signUpAvailabilityGetRequest);
      expect(results, isNotNull);
      expect(results.userLogin, true);
    });

    test("Check if currently non-registered user email returns as available",
        () async {
      // Log out if logged in, we do should not to be logged in for this test.
      if (provider.currentUser != null) {
        await provider.logOut();
      }

      const signUpAvailabilityGetRequest = SignUpAvailabilityGetRequest(
          userEmail: 'thisemailisnotregistered@hellofiji.dating');
      final results =
          await provider.checkSignUpAvailability(signUpAvailabilityGetRequest);
      expect(results, isNotNull);
      expect(results.userEmail, true);
    });

    test(
        "Check if currently non-registered user login and user email returns as available",
        () async {
      // Log out if logged in, we do should not to be logged in for this test.
      if (provider.currentUser != null) {
        await provider.logOut();
      }

      const signUpAvailabilityGetRequest = SignUpAvailabilityGetRequest(
        userLogin: 'thisusernameisnotregistered',
        userEmail: 'thisemailisnotregistered@hellofiji.dating',
      );
      final results =
          await provider.checkSignUpAvailability(signUpAvailabilityGetRequest);
      expect(results, isNotNull);
      expect(results.userLogin, true);
      expect(results.userEmail, true);
    });

    test("Check if currently registered user login returns as not available",
        () async {
      // Log out if logged in, we do should not to be logged in for this test.
      if (provider.currentUser != null) {
        await provider.logOut();
      }

      final signUpAvailabilityGetRequest =
          SignUpAvailabilityGetRequest(userLogin: appDemoUserName);
      final results =
          await provider.checkSignUpAvailability(signUpAvailabilityGetRequest);
      expect(results, isNotNull);
      expect(results.userLogin, false);
    });

    test("Check if currently registered user email returns as not available",
        () async {
      // Log out if logged in, we do should not to be logged in for this test.
      if (provider.currentUser != null) {
        await provider.logOut();
      }

      const signUpAvailabilityGetRequest =
          SignUpAvailabilityGetRequest(userEmail: 'appdemo@hellofiji.dating');
      final results =
          await provider.checkSignUpAvailability(signUpAvailabilityGetRequest);
      expect(results, isNotNull);
      expect(results.userEmail, false);
    });

    test(
        "Check if currently registered user login and user email returns as not available",
        () async {
      // Log out if logged in, we do should not to be logged in for this test.
      if (provider.currentUser != null) {
        await provider.logOut();
      }

      var signUpAvailabilityGetRequest = SignUpAvailabilityGetRequest(
        userLogin: appDemoUserName,
        userEmail: 'appdemo@hellofiji.dating',
      );
      final results =
          await provider.checkSignUpAvailability(signUpAvailabilityGetRequest);
      expect(results, isNotNull);
      expect(results.userLogin, false);
      expect(results.userEmail, false);
    });

    test("Register a new user", () async {
      // Log out if logged in, we do should not to be logged in for this test.
      if (provider.currentUser != null) {
        await provider.logOut();
      }

      // List of emails allocated for sign up testing.
      List<String> emailAddresses = [
        'unitone@hellofiji.dating',
        'unittwo@hellofiji.dating',
        'unitthree@hellofiji.dating',
        'unitfour@hellofiji.dating',
        'unitfive@hellofiji.dating',
      ];

      // Iterate through the list and find an available email address to use,
      // otherwise throw an exception.
      String? signUpUserLogin;
      String? signUpUserEmail;

      for (final emailAddress in emailAddresses) {
        final userLogin = emailAddress.substring(0, emailAddress.indexOf('@'));
        final signUpAvailabilityGetRequest = SignUpAvailabilityGetRequest(
          userLogin: userLogin,
          userEmail: emailAddress,
        );
        final results = await provider
            .checkSignUpAvailability(signUpAvailabilityGetRequest);
        if (results.userEmail && results.userLogin) {
          signUpUserLogin = userLogin;
          signUpUserEmail = emailAddress;
          break;
        }
      }

      if (signUpUserEmail == null) {
        throw Exception(
            'No email addresses available for test, please delete pending accounts.');
      }

      final Map<String, Object> registrationData = {"context": "edit"};

      // Populate registration data.
      registrationData['user_login'] = signUpUserLogin!;
      registrationData['user_email'] = signUpUserEmail;
      registrationData['password'] = 'zisa7=crado?e25!brIh';
      // Terms Acceptance.
      registrationData['field_2996'] = '1';

      // Try registering here, should fail.
      try {
        final registered = await provider.signUp(registrationData);
        expect(registered, false);
      } on Exception catch (e) {
        expect(e, isA<BadRequestResponseException>());
      }

      // About Me.
      registrationData['user_name'] = 'hello! Automated Testing';
      registrationData['field_$xProfileFieldName'] = 'hello! Automated Testing';
      registrationData['field_$xProfileFieldBirthdate'] = '1969-07-16 00:00:00';
      registrationData['field_$xProfileFieldGender'] = 'Male';
      registrationData['field_$xProfileFieldSexualOrientation'] =
          'Heterosexual';
      registrationData['field_$xProfileFieldLocation'] = 'Nadi, Fiji';
      registrationData['field_$xProfileFieldStatus'] = 'Single';
      registrationData['field_$xProfileFieldLookingFor'] = [
        'Male',
        'Female',
        'Transgender',
        'Non-binary',
        'Other',
      ];
      registrationData['field_$xProfileFieldConnection'] = [
        'Short-term Dating',
        'Long-term Dating',
      ];
      // Background.
      registrationData['field_$xProfileFieldMainLanguage'] = [
        'English',
        'Fijian',
        'Fiji Hindi',
      ];
      registrationData['field_$xProfileFieldEthnicity'] = [
        'Fijian',
        'Indo-Fijian',
        ('Black / African').addEscapeCharacters(),
      ];
      registrationData['field_$xProfileFieldPassion'] = [
        'Animals',
        ('Health & Fitness').addEscapeCharacters(),
        'Photography',
        'Travel',
      ];
      registrationData['field_$xProfileFieldOftenAlcohol'] =
          'Once or twice a month';
      registrationData['field_$xProfileFieldOftenSmoke'] = 'Never';
      registrationData['field_$xProfileFieldWantKids'] = 'Definitely!';
      // Interests.
      registrationData['field_$xProfileFieldHobbies'] = [
        ('Arts & Craft').addEscapeCharacters(),
        'Exploring the Outdoors',
        'Listening to Music',
        ('Sport & Exercise').addEscapeCharacters(),
      ];
      registrationData['field_$xProfileFieldFavouriteMovies'] = [
        'Comedy',
        'Mystery',
        'Sci-Fi',
      ];
      registrationData['field_$xProfileFieldFavouriteMusic'] = [
        ('Alternative/Indie').addEscapeCharacters(),
        'Heavy Metal',
        'Hip-Hop',
        'Rock',
      ];
      registrationData['field_$xProfileFieldFavouriteCuisine'] = [
        'Greek',
        'Italian',
        'Japanese',
        'Mexican',
      ];
      registrationData['field_$xProfileFieldFavouriteSweet'] = [
        ('Biscuits & Cookies').addEscapeCharacters(),
        'Cream Bun',
        'Ice-cream',
        'Indian Sweets',
        'Other',
      ];
      registrationData['field_$xProfileFieldFavouriteDrink'] = [
        'Coconut Water',
        'Coffee',
        'Rum',
      ];
      registrationData['field_$xProfileFieldFavouriteSport'] = ['Gym'];
      registrationData['field_$xProfileFieldFavouriteBooks'] = [
        ("I don't like reading").addEscapeCharacters()
      ];
      registrationData['field_$xProfileFieldFavouriteGames'] = [
        'Board Games',
        'Carrom Board',
        'Jigsaw Puzzles',
        'Word Search'
      ];
      registrationData['field_$xProfileFieldPets'] = [
        'Cat',
        'Dog',
        'Horse',
      ];
      // Optional
      registrationData['field_$xProfileFieldWhatYouNeedToKnow'] =
          ("numeric row symbols: ~!@#\$%^&*()_+=\npunctuations: {}|\\;'\"<,>.?/\nquoted line: 'One small step for a man, one giant leap for mankind.'\nquotes inside quotes: 'There's that word again. \"Heavy.\"'")
              .addEscapeCharacters();
      registrationData['field_$xProfileFieldWhatImLookingFor'] =
          ("numeric row symbols: ~!@#\$%^&*()_+=\npunctuations: {}|\\;'\"<,>.?/\nquoted line: 'One small step for a man, one giant leap for mankind.'\nquotes inside quotes: 'There's that word again. \"Heavy.\"'")
              .addEscapeCharacters();

      final registered = await provider.signUp(registrationData);
      expect(registered, true);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));

  group('[Photo Verification]', () {
    test("Check our verification status", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      final result = await provider.getPhotoVerificationStatus(appDemoUserId);
      expect(result, isNotNull);
      expect(result.status, const TypeMatcher<PhotoVerificationStatusType>());
    });

    test("Check another member's verification status", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      final result = await provider.getPhotoVerificationStatus(testDemoUserId);
      expect(result, isNotNull);
      expect(result.status, const TypeMatcher<PhotoVerificationStatusType>());
    });

    test("Check a suspended member's verification status", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      final result =
          await provider.getPhotoVerificationStatus(testSuspendedUserId);
      expect(result, isNotNull);
      expect(result.status, const TypeMatcher<PhotoVerificationStatusType>());
    });

    test("Request a random verification prompt", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      final result = await provider.getPhotoVerificationRandomPrompt();
      expect(result, isNotNull);
      expect(result.id, isNonNegative);
      expect(Uri.parse(result.image).isAbsolute, true);
    });

    test("Send a verification request", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // check if we can send a verification request first
      final verificationStatus =
          await provider.getPhotoVerificationStatus(appDemoUserId);
      if ((verificationStatus.status ==
                  PhotoVerificationStatusType.unverified ||
              verificationStatus.status ==
                  PhotoVerificationStatusType.rejected) &&
          !verificationStatus.restricted) {
        // status has returned as unverified/rejected and not restricted, so go
        // ahead and request a prompt
        final promptId = (await provider.getPhotoVerificationRandomPrompt()).id;
        // send the verification request
        var result = await provider.sendPhotoVerificationRequest(
            promptId, 'test/resources/hello_frangipani.png');
        expect(result, true);
      }
    });

    test("Send a verification request when status is already pending/approved",
        () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // request a prompt
      final promptId = (await provider.getPhotoVerificationRandomPrompt()).id;

      // send a verification request to set status to pending
      // (if not already pending or approved)
      final verificationStatus =
          await provider.getPhotoVerificationStatus(appDemoUserId);
      if ((verificationStatus.status ==
                  PhotoVerificationStatusType.unverified ||
              verificationStatus.status ==
                  PhotoVerificationStatusType.rejected) &&
          !verificationStatus.restricted) {
        // send the verification request
        var result = await provider.sendPhotoVerificationRequest(
            promptId, 'test/resources/hello_frangipani.png');
        expect(result, true);
      }

      // send a verification request which should throw an exception since
      // status is pending or approved
      try {
        await provider.sendPhotoVerificationRequest(
            promptId, 'test/resources/hello_frangipani.png');
      } on Exception catch (e) {
        expect(e, isA<GenericRequestException>());
      }
    });
  }, timeout: const Timeout(Duration(minutes: 2)));

  group('[SMS Verification]', () {
    test("Check SMS verification system status", () async {
      // Log out if already logged in.
      await provider.logOut();

      final result = await provider.getSmsVerificationSystemStatus();
      expect(result, isNotNull);
      expect(result.available, const TypeMatcher<bool>());
      expect(result.enforceVerification, const TypeMatcher<bool>());
    });

    test("Request an SMS verification code", () async {
      // Log out if already logged in.
      await provider.logOut();

      final uuid = const Uuid().v1();

      final smsCodeRequest =
          SmsCodeRequest(deviceId: uuid, phoneNumber: testMobilePhoneNumber);

      final result = await provider.requestSmsCode(smsCodeRequest);
      expect(result, isNotNull);
      expect(result.requested, const TypeMatcher<bool>());
      expect(result.verified, const TypeMatcher<bool>());
      expect(result.requestId, const TypeMatcher<String>());
    });
  }, timeout: const Timeout(Duration(minutes: 5)));

  group('[Multiple Photos]', () {
    test("Check multiple photos management system status", () async {
      // Log out if already logged in.
      await provider.logOut();

      final result = await provider.getMultiplePhotoSystemStatus();
      expect(result, isNotNull);
      expect(result.available, const TypeMatcher<bool>());
      expect(result.maximumAllowed, const TypeMatcher<int>());
    });

    test("Upload photos.", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // Check if we can upload first.
      final result = await provider.getPhotoVerificationStatus(appDemoUserId);
      expect(result, isNotNull);
      expect(result.status, const TypeMatcher<PhotoVerificationStatusType>());

      if (result.status == PhotoVerificationStatusType.approved) {
        // Upload a few photos and verify their status.
        const testPhotoFilePath = 'test/resources/hello_frangipani.png';
        List<MemberPhotoUpdate> memberPhotoUpdates = [
          const MemberPhotoUpdate(
              file: testPhotoFilePath,
              sequence: 0,
              type: MemberPhotoType.avatar),
          const MemberPhotoUpdate(
              file: testPhotoFilePath,
              sequence: 1,
              type: MemberPhotoType.gallery),
          const MemberPhotoUpdate(
              file: testPhotoFilePath,
              sequence: 2,
              type: MemberPhotoType.gallery)
        ];
        var updateUserPhotosResult =
            await provider.updateUserPhotos(memberPhotoUpdates);
        expect(updateUserPhotosResult.length, memberPhotoUpdates.length);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.sequence == 0)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.sequence == 1)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.sequence == 2)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where(
                    (memberPhoto) => memberPhoto.type == MemberPhotoType.avatar)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) =>
                    memberPhoto.type == MemberPhotoType.gallery)
                .length,
            2);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) =>
                    memberPhoto.status ==
                    MemberPhotoModerationStatusType.pending)
                .length,
            3);
        for (final memberPhoto in updateUserPhotosResult) {
          expect(memberPhoto.mediaId, greaterThan(-1));
          expect(memberPhoto.urls.full, const TypeMatcher<String>());
          expect(memberPhoto.urls.thumb, const TypeMatcher<String>());
        }
      }
    });

    test("Change photo seqeuences.", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // Check if we can upload first.
      final result = await provider.getPhotoVerificationStatus(appDemoUserId);
      expect(result, isNotNull);
      expect(result.status, const TypeMatcher<PhotoVerificationStatusType>());

      if (result.status == PhotoVerificationStatusType.approved) {
        final userPhotos = await provider.getUserPhotos();
        if (userPhotos.isNotEmpty) {
          List<MemberPhotoUpdate> memberPhotoUpdates = [];
          final newAvatarMediaId = userPhotos.last.mediaId;
          for (int i = 0; i < userPhotos.length; i++) {
            // Increment each sequence by 1, unless it if is the last one, in which case set it to 0.
            memberPhotoUpdates.add(MemberPhotoUpdate(
                mediaId: userPhotos[i].mediaId,
                sequence:
                    i == userPhotos.length - 1 ? 0 : userPhotos[i].sequence + 1,
                type: i == userPhotos.length - 1
                    ? MemberPhotoType.avatar
                    : MemberPhotoType.gallery));
          }
          final updateUserPhotosResult =
              await provider.updateUserPhotos(memberPhotoUpdates);
          expect(updateUserPhotosResult.length, memberPhotoUpdates.length);
          expect(
              updateUserPhotosResult
                  .where((memberPhoto) => memberPhoto.sequence == 0)
                  .length,
              1);
          expect(
              updateUserPhotosResult
                  .where((memberPhoto) => memberPhoto.sequence == 1)
                  .length,
              1);
          expect(
              updateUserPhotosResult
                  .where((memberPhoto) => memberPhoto.sequence == 2)
                  .length,
              1);
          expect(
              updateUserPhotosResult
                  .where((memberPhoto) =>
                      memberPhoto.type == MemberPhotoType.avatar)
                  .length,
              1);
          expect(
              updateUserPhotosResult
                  .where((memberPhoto) =>
                      memberPhoto.type == MemberPhotoType.gallery)
                  .length,
              2);
          expect(
              updateUserPhotosResult
                  .where((memberPhoto) =>
                      memberPhoto.status ==
                      MemberPhotoModerationStatusType.pending)
                  .length,
              3);
          // Confirm that the avatar has changed.
          expect(
              updateUserPhotosResult
                  .where((memberPhoto) =>
                      memberPhoto.type == MemberPhotoType.avatar)
                  .first
                  .mediaId,
              newAvatarMediaId);
          for (final memberPhoto in updateUserPhotosResult) {
            expect(memberPhoto.mediaId, greaterThan(-1));
            expect(memberPhoto.urls.full, const TypeMatcher<String>());
            expect(memberPhoto.urls.thumb, const TypeMatcher<String>());
          }
        }
      }
    });

    test("Attempt to upload multiple avatars.", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // Check if we can upload first.
      final result = await provider.getPhotoVerificationStatus(appDemoUserId);
      expect(result, isNotNull);
      expect(result.status, const TypeMatcher<PhotoVerificationStatusType>());

      if (result.status == PhotoVerificationStatusType.approved) {
        // Upload a few photos, all with the type set to avatar.
        const testPhotoFilePath = 'test/resources/hello_frangipani.png';
        List<MemberPhotoUpdate> memberPhotoUpdates = [
          const MemberPhotoUpdate(
              file: testPhotoFilePath,
              sequence: 0,
              type: MemberPhotoType.avatar),
          const MemberPhotoUpdate(
              file: testPhotoFilePath,
              sequence: 1,
              type: MemberPhotoType.avatar),
          const MemberPhotoUpdate(
              file: testPhotoFilePath,
              sequence: 2,
              type: MemberPhotoType.avatar)
        ];
        try {
          await provider.updateUserPhotos(memberPhotoUpdates);
        } on Exception catch (e) {
          expect(e, isA<BadRequestResponseException>());
        }
      }
    });

    test("Upload photos along with changed sequences.", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // Check if we can upload first.
      final result = await provider.getPhotoVerificationStatus(appDemoUserId);
      expect(result, isNotNull);
      expect(result.status, const TypeMatcher<PhotoVerificationStatusType>());

      if (result.status == PhotoVerificationStatusType.approved) {
        // Upload a few photos and verify their status.
        const testPhotoFilePath1 = 'test/resources/hello_frangipani.png';
        List<MemberPhotoUpdate> memberPhotoUpdates = [
          const MemberPhotoUpdate(
              file: testPhotoFilePath1,
              sequence: 0,
              type: MemberPhotoType.avatar),
          const MemberPhotoUpdate(
              file: testPhotoFilePath1,
              sequence: 1,
              type: MemberPhotoType.gallery),
          const MemberPhotoUpdate(
              file: testPhotoFilePath1,
              sequence: 2,
              type: MemberPhotoType.gallery)
        ];
        var updateUserPhotosResult =
            await provider.updateUserPhotos(memberPhotoUpdates);
        expect(updateUserPhotosResult.length, memberPhotoUpdates.length);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.sequence == 0)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.sequence == 1)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.sequence == 2)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where(
                    (memberPhoto) => memberPhoto.type == MemberPhotoType.avatar)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) =>
                    memberPhoto.type == MemberPhotoType.gallery)
                .length,
            2);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) =>
                    memberPhoto.status ==
                    MemberPhotoModerationStatusType.pending)
                .length,
            3);
        for (final memberPhoto in updateUserPhotosResult) {
          expect(memberPhoto.mediaId, greaterThan(-1));
          expect(memberPhoto.urls.full, const TypeMatcher<String>());
          expect(memberPhoto.urls.thumb, const TypeMatcher<String>());
        }

        // Add a new photo, and change the sequence of an existing photo (the rest should get deleted).
        const testPhotoFilePath2 = 'test/resources/friends.jpg';
        final lastPhotoMediaId = updateUserPhotosResult.last.mediaId;
        const newSequenceNo = 1;
        memberPhotoUpdates = [
          const MemberPhotoUpdate(
              file: testPhotoFilePath2,
              sequence: 0,
              type: MemberPhotoType.avatar),
          MemberPhotoUpdate(
              mediaId: lastPhotoMediaId,
              sequence: newSequenceNo,
              type: MemberPhotoType.gallery),
          const MemberPhotoUpdate(
              file: testPhotoFilePath1,
              sequence: 2,
              type: MemberPhotoType.gallery),
          const MemberPhotoUpdate(
              file: testPhotoFilePath2,
              sequence: 3,
              type: MemberPhotoType.gallery)
        ];

        updateUserPhotosResult =
            await provider.updateUserPhotos(memberPhotoUpdates);
        expect(updateUserPhotosResult.length, memberPhotoUpdates.length);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.sequence == 0)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.sequence == 1)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.sequence == 2)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.sequence == 3)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where(
                    (memberPhoto) => memberPhoto.type == MemberPhotoType.avatar)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) =>
                    memberPhoto.type == MemberPhotoType.gallery)
                .length,
            3);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) =>
                    memberPhoto.status ==
                    MemberPhotoModerationStatusType.pending)
                .length,
            4);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.mediaId == lastPhotoMediaId)
                .length,
            1);
        expect(
            updateUserPhotosResult
                .where((memberPhoto) => memberPhoto.mediaId == lastPhotoMediaId)
                .first
                .sequence,
            newSequenceNo);
        for (final memberPhoto in updateUserPhotosResult) {
          expect(memberPhoto.mediaId, greaterThan(-1));
          expect(memberPhoto.urls.full, const TypeMatcher<String>());
          expect(memberPhoto.urls.thumb, const TypeMatcher<String>());
        }
      }
    });

    test("Retrieve photos, delete all photos if any exist.", () async {
      if (provider.currentUser == null) {
        await logInAppDemo();
      }

      // Check if we are verified first.
      final result = await provider.getPhotoVerificationStatus(appDemoUserId);
      expect(result, isNotNull);
      expect(result.status, const TypeMatcher<PhotoVerificationStatusType>());

      if (result.status == PhotoVerificationStatusType.approved) {
        final userPhotos = await provider.getUserPhotos();
        expect(userPhotos, isNotNull);

        if (userPhotos.isNotEmpty) {
          // There are some existing photos, verify the first one, and then delete them all.
          expect(userPhotos, const TypeMatcher<List<MemberPhoto>>());
          final existingPhotoCount = userPhotos.length;
          final memberPhoto = userPhotos.first;
          expect(memberPhoto.mediaId, greaterThan(-1));
          expect(memberPhoto.sequence, greaterThan(-1));
          expect(memberPhoto.urls.thumb, const TypeMatcher<String>());
          expect(memberPhoto.urls.full, const TypeMatcher<String>());

          final memberPhotosDeleted = await provider.deleteUserPhotos();
          expect(memberPhotosDeleted.deleted, true);
          expect(memberPhotosDeleted.previous,
              const TypeMatcher<List<MemberPhoto>>());
          expect(memberPhotosDeleted.previous.length, existingPhotoCount);
        }
      }
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
