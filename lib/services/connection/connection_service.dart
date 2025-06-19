import 'package:nifty_three_bp_app_base/api/auth_result.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/connection/arvo_connection_provider.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/member_avatar.dart';
import 'package:nifty_three_bp_app_base/api/member_blocked.dart';
import 'package:nifty_three_bp_app_base/api/member_delete_request.dart';
import 'package:nifty_three_bp_app_base/api/member_favourite.dart';
import 'package:nifty_three_bp_app_base/api/member_report_request.dart';
import 'package:nifty_three_bp_app_base/api/members_get_request.dart';
import 'package:nifty_three_bp_app_base/api/message_delete_thread_request.dart';
import 'package:nifty_three_bp_app_base/api/message_mark_read_unread_request.dart';
import 'package:nifty_three_bp_app_base/api/message_send_new_message_request.dart';
import 'package:nifty_three_bp_app_base/api/message_star_unstar_request.dart';
import 'package:nifty_three_bp_app_base/api/message_thread.dart';
import 'package:nifty_three_bp_app_base/api/messages_get_request.dart';
import 'package:nifty_three_bp_app_base/api/multiple_photo.dart';
import 'package:nifty_three_bp_app_base/api/notification.dart';
import 'package:nifty_three_bp_app_base/api/notification_update_request.dart';
import 'package:nifty_three_bp_app_base/api/notifications_get_request.dart';
import 'package:nifty_three_bp_app_base/api/photo_verification.dart';
import 'package:nifty_three_bp_app_base/api/pnfpb_firebase_token_registration_result.dart';
import 'package:nifty_three_bp_app_base/api/post.dart';
import 'package:nifty_three_bp_app_base/api/post_media.dart';
import 'package:nifty_three_bp_app_base/api/posts_get_request.dart';
import 'package:nifty_three_bp_app_base/api/sign_up_availability.dart';
import 'package:nifty_three_bp_app_base/api/sms_verification.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field_data.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field_get_request.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field_post_request.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_group.dart';

class ConnectionService implements ConnectionProvider {
  final ConnectionProvider provider;
  const ConnectionService(this.provider);

  factory ConnectionService.arvo() =>
      ConnectionService(ArvoConnectionProvider());

  @override
  Future<void> initalise(url) => provider.initalise(url);

  @override
  String? get serverUrl => provider.serverUrl;

  @override
  set serverUrl(String? value) => provider.serverUrl = value;

  @override
  String? get userAgent => provider.userAgent;

  @override
  String? get token => provider.token;

  @override
  Member? get currentUser => provider.currentUser;

  @override
  String? get currentUserEmailAddress => provider.currentUserEmailAddress;

  @override
  List<XProfileField>? get xProfileFields => provider.xProfileFields;

  @override
  Future<bool> isAuthorisationTokenValid() =>
      provider.isAuthorisationTokenValid();

  @override
  Future<AuthResult> logIn({
    required String username,
    required String password,
  }) =>
      provider.logIn(
        username: username,
        password: password,
      );

  @override
  Future<void> logOut() => provider.logOut();

  @override
  Future<bool> sendPasswordResetEmail(String email) =>
      provider.sendPasswordResetEmail(email);

  @override
  Future<Member> getCurrentUser() => provider.getCurrentUser();

  @override
  Future<void> refreshCurrentUser() => provider.refreshCurrentUser();

  @override
  Future<Member> getMember(int memberId) => provider.getMember(memberId);

  @override
  Future<List<Member>> getMembers(MembersGetRequest membersGetRequest) =>
      provider.getMembers(membersGetRequest);

  @override
  Future<List<XProfileField>> getXProfileFields([int? groupId]) =>
      provider.getXProfileFields(groupId);

  @override
  Future<List<XProfileField>> getXProfileField(int fieldId) =>
      provider.getXProfileField(fieldId);

  @override
  Future<List<XProfileGroup>> getXProfileGroups() =>
      provider.getXProfileGroups();

  @override
  Future<List<XProfileFieldData>> getXProfileFieldData(
          XProfileFieldGetRequest xProfileFieldGetRequest) =>
      provider.getXProfileFieldData(xProfileFieldGetRequest);

  @override
  Future<List<XProfileFieldData>> updateXProfileFieldData(
          XProfileFieldPostRequest xProfileFieldPostRequest) =>
      provider.updateXProfileFieldData(xProfileFieldPostRequest);

  @override
  Future<List<MemberAvatar>> updateUserProfilePicture(String filePath) =>
      provider.updateUserProfilePicture(filePath);

  @override
  Future<MemberAvatarDeleted> deleteUserProfilePicture() =>
      provider.deleteUserProfilePicture();

  @override
  Future<MemberDeleted> deleteUserAccount(
          MemberDeleteRequest memberDeleteRequest) =>
      provider.deleteUserAccount(memberDeleteRequest);

  @override
  Future<List<MessageThread>> getMessages(
          MessagesGetRequest messagesGetRequest) =>
      provider.getMessages(messagesGetRequest);

  @override
  Future<List<MessageThread>> getMessageThread(int messageThreadId) =>
      provider.getMessageThread(messageThreadId);

  @override
  Future<List<MessageThread>> sendNewMessage(
          MessageSendNewMessageRequest messageSendNewMessageRequest) =>
      provider.sendNewMessage(messageSendNewMessageRequest);

  @override
  Future<MessageThreadDeleted> deleteMessageThread(
          MessageDeleteThreadRequest messageDeleteThreadRequest) =>
      provider.deleteMessageThread(messageDeleteThreadRequest);

  @override
  Future<List<Message>> starOrUnstarMessage(
          MessageStarUnstarRequest messageStarUnstarRequest) =>
      provider.starOrUnstarMessage(messageStarUnstarRequest);

  @override
  Future<List<MessageThread>> markMessageThreadReadOrUnread(
          MessageMarkReadUnreadRequest messageMarkReadUnreadRequest) =>
      provider.markMessageThreadReadOrUnread(messageMarkReadUnreadRequest);

  @override
  Future<int> getLastMessageThreadId(int memberId) =>
      provider.getLastMessageThreadId(memberId);

  @override
  Future<List<Post>> getPosts(PostsGetRequest postsGetRequest) =>
      provider.getPosts(postsGetRequest);

  @override
  Future<PostMedia> getPostMedia(int postMediaId) =>
      provider.getPostMedia(postMediaId);

  @override
  Future<List<Notification>> getNotifications(
          NotificationsGetRequest notificationsGetRequest) =>
      provider.getNotifications(notificationsGetRequest);

  @override
  Future<List<Notification>> updateNotification(
          NotificationUpdateRequest notificationUpdateRequest) =>
      provider.updateNotification(notificationUpdateRequest);

  @override
  Future<List<MemberBlocked>> getBlockedMembers(
          BlockedMembersGetRequest blockedMembersGetRequest) =>
      provider.getBlockedMembers(blockedMembersGetRequest);

  @override
  Future<bool> getMemberBlockedStatus(
          int blockingMemberId, int blockedMemberId) =>
      provider.getMemberBlockedStatus(blockingMemberId, blockedMemberId);

  @override
  Future<MemberBlocked> blockMember(int memberId) =>
      provider.blockMember(memberId);

  @override
  Future<MemberUnblocked> unblockMember(int memberId) =>
      provider.unblockMember(memberId);

  @override
  Future<bool> getMemberSuspendedStatus(int memberId) =>
      provider.getMemberSuspendedStatus(memberId);

  @override
  Future<bool> reportMember(MemberReportRequest memberReportRequest) =>
      provider.reportMember(memberReportRequest);

  @override
  Future<List<MemberFavourite>> getFavouriteMembers(
          MemberFavouritesGetRequest memberFavouritesGetRequest) =>
      provider.getFavouriteMembers(memberFavouritesGetRequest);

  @override
  Future<MemberFavourite> addFavouriteMember(int memberId) =>
      provider.addFavouriteMember(memberId);

  @override
  Future<MemberFavouriteRemoved> removeFavouriteMember(int memberId) =>
      provider.removeFavouriteMember(memberId);

  @override
  Future<bool> getMemberFavouriteStatus(int memberId) =>
      provider.getMemberFavouriteStatus(memberId);

  @override
  Future<List<MemberFavouritedBy>> getFavouritedByMembers(
          MemberFavouritesGetRequest memberFavouritesGetRequest) =>
      provider.getFavouritedByMembers(memberFavouritesGetRequest);

  @override
  Future<bool> getFavouritedByMemberStatus(int memberId) =>
      provider.getFavouritedByMemberStatus(memberId);

  @override
  Future<PnfpbFirebaseTokenRegistrationResult> registerFirebaseTokenWithPnfpb(
          String firebaseToken) =>
      provider.registerFirebaseTokenWithPnfpb(firebaseToken);

  @override
  Future<List<XProfileField>> getXProfileSignUpFields() =>
      provider.getXProfileSignUpFields();

  @override
  Future<SignUpAvailability> checkSignUpAvailability(
          SignUpAvailabilityGetRequest signUpAvailabilityGetRequest) =>
      provider.checkSignUpAvailability(signUpAvailabilityGetRequest);

  @override
  Future<bool> signUp(Map<String, dynamic> registrationData) =>
      provider.signUp(registrationData);

  @override
  Future<bool> activateAccount(String activationKey) =>
      provider.activateAccount(activationKey);

  @override
  Future<bool> checkDisposableEmail(String email, bool ignoreExceptions) =>
      provider.checkDisposableEmail(email, ignoreExceptions);

  @override
  Future<PhotoVerificationStatus> getPhotoVerificationStatus(int memberId) =>
      provider.getPhotoVerificationStatus(memberId);

  @override
  Future<PhotoVerificationPrompt> getPhotoVerificationRandomPrompt() =>
      provider.getPhotoVerificationRandomPrompt();

  @override
  Future<bool> sendPhotoVerificationRequest(int promptId, String filePath) =>
      provider.sendPhotoVerificationRequest(promptId, filePath);

  @override
  Future<SmsVerificationSystemStatus> getSmsVerificationSystemStatus() =>
      provider.getSmsVerificationSystemStatus();

  @override
  Future<MemberPhoneNumber> getMemberPhoneNumber(int memberId) =>
      provider.getMemberPhoneNumber(memberId);

  @override
  Future<MemberPhoneNumberDeleted> deleteMemberPhoneNumber(int memberId) =>
      provider.deleteMemberPhoneNumber(memberId);

  @override
  Future<SmsCodeRequestResult> requestSmsCode(SmsCodeRequest smsCodeRequest) =>
      provider.requestSmsCode(smsCodeRequest);

  @override
  Future<VerifySmsCodeResult> verifySmsCode(
          VerifySmsCodeRequest verifySmsCodeRequest) =>
      provider.verifySmsCode(verifySmsCodeRequest);

  @override
  Future<MultiplePhotoSystemStatus> getMultiplePhotoSystemStatus() =>
      provider.getMultiplePhotoSystemStatus();

  @override
  Future<List<MemberPhoto>> getUserPhotos() => provider.getUserPhotos();

  @override
  Future<List<MemberPhoto>> updateUserPhotos(
          List<MemberPhotoUpdate> memberPhotoUpdates) =>
      provider.updateUserPhotos(memberPhotoUpdates);

  @override
  Future<MemberPhotosDeleted> deleteUserPhotos() => provider.deleteUserPhotos();

  @override
  Future<MemberPhotoDeleted> deleteUserPhoto(int mediaId) =>
      provider.deleteUserPhoto(mediaId);
}
