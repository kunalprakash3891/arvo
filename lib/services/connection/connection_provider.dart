import 'package:nifty_three_bp_app_base/api/auth_result.dart';
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

abstract class ConnectionProvider {
  Future<void> initalise(String url);

  String? get serverUrl;
  set serverUrl(String? value);
  String? get userAgent;
  String? get token;
  Member? get currentUser;
  String? get currentUserEmailAddress;
  List<XProfileField>? get xProfileFields;

  Future<AuthResult> logIn({
    required String username,
    required String password,
  });

  Future<void> logOut();

  Future<bool> sendPasswordResetEmail(String email);

  Future<bool> isAuthorisationTokenValid();

  Future<Member> getCurrentUser();

  Future<void> refreshCurrentUser();

  Future<Member> getMember(int memberId);

  Future<List<Member>> getMembers(MembersGetRequest membersGetRequest);

  Future<List<XProfileField>> getXProfileFields([int? groupId]);

  Future<List<XProfileField>> getXProfileField(int fieldId);

  Future<List<XProfileGroup>> getXProfileGroups();

  Future<List<XProfileFieldData>> getXProfileFieldData(
      XProfileFieldGetRequest xProfileFieldGetRequest);

  Future<List<XProfileFieldData>> updateXProfileFieldData(
      XProfileFieldPostRequest xProfileFieldPostRequest);

  Future<List<MemberAvatar>> updateUserProfilePicture(String filePath);

  Future<MemberAvatarDeleted> deleteUserProfilePicture();

  Future<MemberDeleted> deleteUserAccount(
      MemberDeleteRequest memberDeleteRequest);

  Future<List<MessageThread>> getMessages(
      MessagesGetRequest messagesGetRequest);

  Future<List<MessageThread>> getMessageThread(int messageThreadId);

  Future<List<MessageThread>> sendNewMessage(
      MessageSendNewMessageRequest messageSendNewMessageRequest);

  Future<MessageThreadDeleted> deleteMessageThread(
      MessageDeleteThreadRequest messageDeleteThreadRequest);

  Future<List<Message>> starOrUnstarMessage(
      MessageStarUnstarRequest messageStarUnstarRequest);

  Future<List<MessageThread>> markMessageThreadReadOrUnread(
      MessageMarkReadUnreadRequest messageMarkReadUnreadRequest);

  Future<int> getLastMessageThreadId(int memberId);

  Future<List<Post>> getPosts(PostsGetRequest postsGetRequest);

  Future<PostMedia> getPostMedia(int postMediaId);

  Future<List<Notification>> getNotifications(
      NotificationsGetRequest notificationsGetRequest);

  Future<List<Notification>> updateNotification(
      NotificationUpdateRequest notificationUpdateRequest);

  Future<List<MemberBlocked>> getBlockedMembers(
      BlockedMembersGetRequest blockedMembersGetRequest);

  Future<bool> getMemberBlockedStatus(
      int blockingMemberId, int blockedMemberId);

  Future<MemberBlocked> blockMember(int memberId);

  Future<MemberUnblocked> unblockMember(int memberId);

  Future<bool> getMemberSuspendedStatus(int memberId);

  Future<bool> reportMember(MemberReportRequest memberReportRequest);

  Future<List<MemberFavourite>> getFavouriteMembers(
      MemberFavouritesGetRequest memberFavouritesGetRequest);

  Future<MemberFavourite> addFavouriteMember(int memberId);

  Future<MemberFavouriteRemoved> removeFavouriteMember(int memberId);

  Future<bool> getMemberFavouriteStatus(int memberId);

  Future<List<MemberFavouritedBy>> getFavouritedByMembers(
      MemberFavouritesGetRequest memberFavouritesGetRequest);

  Future<bool> getFavouritedByMemberStatus(int memberId);

  Future<PnfpbFirebaseTokenRegistrationResult> registerFirebaseTokenWithPnfpb(
      String firebaseToken);

  Future<List<XProfileField>> getXProfileSignUpFields();

  Future<SignUpAvailability> checkSignUpAvailability(
      SignUpAvailabilityGetRequest signUpAvailabilityGetRequest);

  Future<bool> signUp(Map<String, dynamic> registrationData);

  Future<bool> activateAccount(String activationKey);

  Future<bool> checkDisposableEmail(String email, bool ignoreExceptions);

  Future<PhotoVerificationStatus> getPhotoVerificationStatus(int memberId);

  Future<PhotoVerificationPrompt> getPhotoVerificationRandomPrompt();

  Future<bool> sendPhotoVerificationRequest(int promptId, String filePath);

  Future<SmsVerificationSystemStatus> getSmsVerificationSystemStatus();

  Future<MemberPhoneNumber> getMemberPhoneNumber(int memberId);

  Future<MemberPhoneNumberDeleted> deleteMemberPhoneNumber(int memberId);

  Future<SmsCodeRequestResult> requestSmsCode(SmsCodeRequest smsCodeRequest);

  Future<VerifySmsCodeResult> verifySmsCode(
      VerifySmsCodeRequest verifySmsCodeRequest);

  Future<MultiplePhotoSystemStatus> getMultiplePhotoSystemStatus();

  Future<List<MemberPhoto>> getUserPhotos();

  Future<List<MemberPhoto>> updateUserPhotos(
      List<MemberPhotoUpdate> memberPhotoUpdates);

  Future<MemberPhotosDeleted> deleteUserPhotos();

  Future<MemberPhotoDeleted> deleteUserPhoto(int mediaId);
}
