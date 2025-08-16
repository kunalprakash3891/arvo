import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/helpers/processing/member_processing.dart';
import 'package:nifty_three_bp_app_base/api/auth_result.dart';
import 'package:nifty_three_bp_app_base/api/bad_request_response.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:nifty_three_bp_app_base/api/debounce_bad_request_response.dart';
import 'package:nifty_three_bp_app_base/api/debounce_response.dart';
import 'package:nifty_three_bp_app_base/api/http_response_codes.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/member_avatar.dart';
import 'package:nifty_three_bp_app_base/api/member_blocked.dart';
import 'package:nifty_three_bp_app_base/api/member_delete_request.dart';
import 'package:nifty_three_bp_app_base/api/member_favourite.dart';
import 'package:nifty_three_bp_app_base/api/member_report_request.dart';
import 'package:nifty_three_bp_app_base/api/multiple_photo.dart';
import 'package:nifty_three_bp_app_base/api/photo_verification.dart';
import 'package:nifty_three_bp_app_base/api/pnfpb_firebase_token_registration_result.dart';
import 'package:nifty_three_bp_app_base/api/reported_status.dart';
import 'package:nifty_three_bp_app_base/api/member_suspended_status.dart';
import 'package:nifty_three_bp_app_base/api/members_get_request.dart';
import 'package:nifty_three_bp_app_base/api/message_delete_thread_request.dart';
import 'package:nifty_three_bp_app_base/api/message_mark_read_unread_request.dart';
import 'package:nifty_three_bp_app_base/api/message_send_new_message_request.dart';
import 'package:nifty_three_bp_app_base/api/message_star_unstar_request.dart';
import 'package:nifty_three_bp_app_base/api/message_thread.dart';
import 'package:nifty_three_bp_app_base/api/messages_get_request.dart';
import 'package:nifty_three_bp_app_base/api/notification.dart';
import 'package:nifty_three_bp_app_base/api/notification_update_request.dart';
import 'package:nifty_three_bp_app_base/api/notifications_get_request.dart';
import 'package:nifty_three_bp_app_base/api/post.dart';
import 'package:nifty_three_bp_app_base/api/post_media.dart';
import 'package:nifty_three_bp_app_base/api/posts_get_request.dart';
import 'package:nifty_three_bp_app_base/api/sign_up_availability.dart';
import 'package:nifty_three_bp_app_base/api/sms_verification.dart';
import 'package:nifty_three_bp_app_base/api/validation_result.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field_data.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field_get_request.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field_post_request.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_group.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:nifty_three_bp_app_base/enums/member_photo_type.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';

const authorisationURL = "/wp-json/jwt-auth/v1/token";
const validationURL = "/wp-json/jwt-auth/v1/token/validate";
const membersURL = "/wp-json/buddypress/v1/members";
const meURL = "$membersURL/me";
const xProfileURL = "/wp-json/buddypress/v1/xprofile";
const xProfileFieldsURL = "$xProfileURL/fields";
const xProfileGroupsURL = "$xProfileURL/groups";
const messagesURL = "/wp-json/buddypress/v1/messages";
const messageStarOrUnstarURL = "/wp-json/buddypress/v1/messages/starred";
const messageLastThreadStatusURL = "/wp-json/message-thread-checker/v1/status";
const postsURL = "/wp-json/wp/v2/posts";
const postMediaURL = "/wp-json/wp/v2/media";
const notificationsURL = "/wp-json/buddypress/v1/notifications";
const blockedMembersURL = "/wp-json/buddypress-block-users/v1/blocklist";
const suspendedMemberStatusURL =
    "/wp-json/buddypress-moderation-tools/v1/suspension";
const reportsURL = "/wp-json/buddypress-moderation-tools/v1/reports";
const pnfpbSubscriptionTokenURL = "/wp-json/PNFPBPush/v1/subscriptiontoken";
const passwordResetURL = "/wp-login.php?action=lostpassword";
const favouriteMembersURL = "/wp-json/favourite-users/v1/favourites";
const favouritedByMembersURL = "/wp-json/favourite-users/v1/favouritedby";
const checkSignUpAvailabilityURL =
    "/wp-json/bp-new-signup-endpoints/v1/signup-availability-check";
const signUpURL = "/wp-json/buddypress/v1/signup";
const xProfileSignUpFieldsURL =
    "/wp-json/bp-new-signup-endpoints/v1/signup-fields";
const activateAccountURL = "$signUpURL/activate";
const photoVerificationRequestsURL =
    "/wp-json/nifty-photo-verification-system/v1/verification-requests";
const photoVerificationPromptsURL =
    "/wp-json/nifty-photo-verification-system/v1/prompts";
// TODO: Check the support email below works. Need to add inbox to Outlook.
const supportEmail = 'gday@arvo.dating';

const smsVerificationUrl = "/wp-json/nifty-sms-verification-system/v1";
const smsVerificationAvailableUrl = "$smsVerificationUrl/available";
const smsVerificationPhoneNumberUrl = "$smsVerificationUrl/phonenumber";
const smsVerificationRequestSmsCodeUrl = "$smsVerificationUrl/requestsmscode";
const smsVerificationVerifySmsCodeUrl = "$smsVerificationUrl/verifysmscode";

const multiplePhotoManagementUrl =
    "/wp-json/nifty-multiple-photo-management-system/v1";
const multiplePhotoManagementAvailableUrl =
    "$multiplePhotoManagementUrl/available";

const basicUserAgent =
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36';

const debounceDisposableURL = 'https://disposable.debounce.io/';

Future<String> getUserAgent() async {
  PackageInfo? packageInfo;

  try {
    packageInfo = await PackageInfo.fromPlatform();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        {
          final deviceInfo = await DeviceInfoPlugin().androidInfo;
          final userAgent =
              'arvo F./${packageInfo.version}_${packageInfo.buildNumber} (${deviceInfo.manufacturer}; ${deviceInfo.model}; ${deviceInfo.isPhysicalDevice ? 'Physical' : 'Emulator'}; Android ${deviceInfo.version.release})';
          return userAgent;
        }
      case TargetPlatform.iOS:
        {
          final deviceInfo = await DeviceInfoPlugin().iosInfo;
          final deviceType = deviceInfo.data['utsname']['machine'] ?? 'Unknown';
          final userAgent =
              'arvo F./${packageInfo.version}_${packageInfo.buildNumber} (Apple; $deviceType; ${deviceInfo.isPhysicalDevice ? 'Physical' : 'Emulator'}; iOS ${deviceInfo.systemVersion})';
          return userAgent;
        }
      default:
        // No idea which platform we are on, so throw an exception and let the
        // fallback agent take over.
        throw Exception();
    }
  } on Exception catch (_) {
    final userAgent =
        'arvo! F./${packageInfo != null ? packageInfo.version : 0}_${packageInfo != null ? packageInfo.buildNumber : 0} (Fallback)';
    return userAgent;
  }
}

// ArvoHttpClient
class ArvoHttpClient extends http.BaseClient {
  final http.Client _client;
  // NOTE: Use a value of 2 seconds to test intermittent timeouts (future not completed).
  final int _httpTimeOut = 60; // in seconds
  String? userAgent;

  ArvoHttpClient(this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    userAgent ??= await getUserAgent();
    request.headers['Content-Type'] = 'application/json; charset=UTF-8';
    request.headers['User-Agent'] = userAgent!;
    request.persistentConnection = false;
    return _client.send(request).timeout(Duration(seconds: _httpTimeOut));
  }

  Future<http.StreamedResponse> getWithJsonBody(http.Request request) async {
    userAgent ??= await getUserAgent();
    request.headers['Content-Type'] = 'application/json; charset=UTF-8';
    request.headers['User-Agent'] = userAgent!;
    request.persistentConnection = false;
    return _client.send(request).timeout(Duration(seconds: _httpTimeOut));
  }
}

// DebounceHttpClient
// Provides checking for disposable/burner emails.
// https://debounce.io/free-disposable-check-api/
class DebounceHttpClient extends http.BaseClient {
  final http.Client _client;
  final int _httpTimeOut = 20; // in seconds
  String userAgent = basicUserAgent;

  DebounceHttpClient(this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Content-Type'] = 'application/json; charset=UTF-8';
    request.headers['User-Agent'] = userAgent;
    request.persistentConnection = false;
    return _client.send(request).timeout(Duration(seconds: _httpTimeOut));
  }

  Future<http.StreamedResponse> getWithJsonBody(http.Request request) async {
    request.headers['Content-Type'] = 'application/json; charset=UTF-8';
    request.headers['User-Agent'] = userAgent;
    request.persistentConnection = false;
    return _client.send(request).timeout(Duration(seconds: _httpTimeOut));
  }
}

// ArvoConnectionProvider
class ArvoConnectionProvider implements ConnectionProvider {
  late ArvoHttpClient _httpClient;
  late DebounceHttpClient _disposableEmailCheckHttpClient;
  String? _token;

  // create as singleton
  static final _shared = ArvoConnectionProvider._sharedInstance();
  ArvoConnectionProvider._sharedInstance();
  factory ArvoConnectionProvider() => _shared;

  String _getTokenOrThrow() {
    if (_token != null) {
      return _token.toString();
    } else {
      throw GenericUserAccessException(message: 'You are not logged in.');
    }
  }

  Member _getCurrentUserOrThrow() {
    if (_currentUser != null) {
      return _currentUser!;
    } else {
      throw GenericUserAccessException(message: 'Invalid user.');
    }
  }

  Future<void> _refreshCurrentUserActivity() async {
    if (_currentUser!.lastActivityTimestamp == null ||
        DateTime.now()
                .difference(_currentUser!.lastActivityTimestamp!)
                .inMinutes >=
            15) {
      _currentUser = await getCurrentUser();
    }
  }

  @override
  Future<void> initalise(url) async {
    // NOTE: HTTP clients here persist for the lifetime of the app, so they do
    // not need to be closed according to the comments here:
    // https://github.com/dart-lang/http/issues/422.
    _httpClient = ArvoHttpClient(http.Client());
    _url = url;
    _disposableEmailCheckHttpClient = DebounceHttpClient(http.Client());
    return;
  }

  @override
  Future<AuthResult> logIn(
      {required String username, required String password}) async {
    http.Response? response;

    try {
      response = await _httpClient.post(
        Uri.parse(_url + authorisationURL),
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final result = AuthResult.fromJson(jsonDecode(response.body));
        final token = result.token;
        if (token != null && token.isNotEmpty) {
          _token = token;
          _currentUserEmailAddress = result.userEmail;
          _currentUser = await getCurrentUser();
          _xProfileFields = await getXProfileFields();
          return result;
        } else {
          throw InvalidTokenException();
        }
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        if (badRequestResponse.code
            .contains(httpBadResponseMessageCodeAccountNotActivated)) {
          throw AccountNotActivatedException();
        }
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response, unauthenticated: true);
    }
  }

  @override
  Future<void> logOut() async {
    _token = null;
    _currentUser = null;
    return;
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    http.Response? response;

    try {
      Map<String, String> headers = {
        'Content-Type': 'multipart/form-data; charset=UTF-8',
        'Accept': 'application/json',
        'User-Agent': await getUserAgent(),
      };

      Map<String, String> body = {'user_login': email};

      var request =
          http.MultipartRequest('POST', Uri.parse(_url + passwordResetURL))
            ..fields.addAll(body)
            ..headers.addAll(headers);

      var streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);

      if ([httpSuccessStatusCode, httpRedirectStatusCode]
          .contains(streamedResponse.statusCode)) {
        return true;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<bool> isAuthorisationTokenValid() async {
    final token = _getTokenOrThrow();

    http.Response? response;

    try {
      response = await _httpClient.post(
        Uri.parse(_url + validationURL),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        return ValidationResult.fromJson(jsonDecode(response.body))
                .data
                ?.status ==
            httpSuccessStatusCode;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<Member> getCurrentUser() async {
    final token = _getTokenOrThrow();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse(_url + meURL),
      );
      request.body = jsonEncode(<String, bool>{
        'populate_extras': true,
      });
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final member = Member.fromJson(jsonDecode(response.body));
        populateMemberAgeGenderLocation(member);
        populateLastActivity(member);
        populateMemberProfileCompletionPercentage(member);
        member.matchWeight = 100;
        return member;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<void> refreshCurrentUser() async {
    _currentUser = await getCurrentUser();
  }

  @override
  Future<Member> getMember(int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse('$_url$membersURL/$memberId'),
      );
      request.body = jsonEncode(<String, bool>{
        'populate_extras': true,
      });
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final member = Member.fromJson(jsonDecode(response.body));
        populateMemberAgeGenderLocation(member);
        populateMatchPercentage(currentUser!, member);
        populateLastActivity(member);
        return member;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<Member>> getMembers(MembersGetRequest membersGetRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse(_url + membersURL),
      );
      request.body = jsonEncode(membersGetRequest.toJson());
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final members = List<Member>.from(
            json.decode(response.body).map((item) => Member.fromJson(item)));
        for (final member in members) {
          populateMemberAgeGenderLocation(member);
          populateMatchPercentage(currentUser!, member);
          populateLastActivity(member);
          //members endpoint should never return blocked members.
          member.isBlocked = false;
        }
        return members;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<XProfileField>> getXProfileFields([int? groupId]) async {
    final token = _getTokenOrThrow();

    http.Response? response;

    try {
      if (groupId != null) {
        final request = http.Request(
          'GET',
          Uri.parse(_url + xProfileFieldsURL),
        );
        request.body = jsonEncode(<String, int>{
          'profile_group_id': groupId,
        });
        request.headers
            .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

        final streamedResponse = await _httpClient.getWithJsonBody(request);
        response = await http.Response.fromStream(streamedResponse);
      } else {
        response = await _httpClient.get(
          Uri.parse(_url + xProfileFieldsURL),
          headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
        );
      }

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<XProfileField>.from(json
            .decode(response.body)
            .map((item) => XProfileField.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<XProfileField>> getXProfileField(int fieldId) async {
    final token = _getTokenOrThrow();

    http.Response? response;

    try {
      response = await _httpClient.get(
        Uri.parse('$_url$xProfileFieldsURL/$fieldId'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<XProfileField>.from(json
            .decode(response.body)
            .map((item) => XProfileField.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<XProfileGroup>> getXProfileGroups() async {
    final token = _getTokenOrThrow();

    http.Response? response;

    try {
      response = await _httpClient.get(
        Uri.parse(_url + xProfileGroupsURL),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<XProfileGroup>.from(json
            .decode(response.body)
            .map((item) => XProfileGroup.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<XProfileFieldData>> getXProfileFieldData(
      XProfileFieldGetRequest xProfileFieldGetRequest) async {
    final token = _getTokenOrThrow();

    http.Response? response;

    final fieldId = xProfileFieldGetRequest.fieldId;
    final userId = xProfileFieldGetRequest.userId;

    try {
      final request = http.Request(
        'GET',
        Uri.parse('$_url$xProfileURL/$fieldId/data/$userId'),
      );
      request.body = jsonEncode(xProfileFieldGetRequest.toJson());
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<XProfileFieldData>.from(json
            .decode(response.body)
            .map((item) => XProfileFieldData.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<XProfileFieldData>> updateXProfileFieldData(
      XProfileFieldPostRequest xProfileFieldPostRequest) async {
    final token = _getTokenOrThrow();

    http.Response? response;

    final fieldId = xProfileFieldPostRequest.fieldId;
    final userId = xProfileFieldPostRequest.userId;

    try {
      response = await _httpClient.post(
        Uri.parse('$_url$xProfileURL/$fieldId/data/$userId'),
        body: jsonEncode(
          xProfileFieldPostRequest.toJson(),
        ),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<XProfileFieldData>.from(json
            .decode(response.body)
            .map((item) => XProfileFieldData.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<MemberAvatar>> updateUserProfilePicture(String filePath) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();

    http.Response? response;

    final userId = currentUser?.id;

    final file = File(filePath);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_url$membersURL/$userId/avatar'),
      );
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});
      request.fields['action'] = 'bp_avatar_upload';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        await File.fromUri(Uri.parse(file.path)).readAsBytes(),
        contentType: MediaType('image', 'jpeg'),
        filename: basename(file.path),
      ));

      final streamedResponse = await _httpClient.send(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<MemberAvatar>.from(json
            .decode(response.body)
            .map((item) => MemberAvatar.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<MemberAvatarDeleted> deleteUserProfilePicture() async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();

    http.Response? response;

    final userId = currentUser?.id;

    try {
      response = await _httpClient.delete(
        Uri.parse('$_url$membersURL/$userId/avatar'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final memberAvatarDeleted =
            MemberAvatarDeleted.fromJson(jsonDecode(response.body));
        return memberAvatarDeleted;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<MemberDeleted> deleteUserAccount(
      MemberDeleteRequest memberDeleteRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();

    http.Response? response;

    try {
      response = await _httpClient.delete(
        Uri.parse(_url + meURL),
        body: jsonEncode(
          memberDeleteRequest.toJson(),
        ),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final memberDeleted = MemberDeleted.fromJson(jsonDecode(response.body));
        return memberDeleted;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<MessageThread>> getMessages(
      MessagesGetRequest messagesGetRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse(_url + messagesURL),
      );
      request.body = jsonEncode(messagesGetRequest.toJson());
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<MessageThread>.from(json
            .decode(response.body)
            .map((item) => MessageThread.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<MessageThread>> getMessageThread(int messageThreadId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse('$_url$messagesURL/$messageThreadId'),
      );
      request.body = jsonEncode(<String, String>{
        'context': 'edit',
      });
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<MessageThread>.from(json
            .decode(response.body)
            .map((item) => MessageThread.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<MessageThread>> sendNewMessage(
      MessageSendNewMessageRequest messageSendNewMessageRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      response = await _httpClient.post(
        Uri.parse(_url + messagesURL),
        body: jsonEncode(
          messageSendNewMessageRequest.toJson(),
        ),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<MessageThread>.from(json
            .decode(response.body)
            .map((item) => MessageThread.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<MessageThreadDeleted> deleteMessageThread(
      MessageDeleteThreadRequest messageDeleteThreadRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    final threadId = messageDeleteThreadRequest.id;

    try {
      response = await _httpClient.delete(
        Uri.parse('$_url$messagesURL/$threadId'),
        body: jsonEncode(
          messageDeleteThreadRequest.toJson(),
        ),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final messageThreadDeleted =
            MessageThreadDeleted.fromJson(jsonDecode(response.body));
        return messageThreadDeleted;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<Message>> starOrUnstarMessage(
      MessageStarUnstarRequest messageStarUnstarRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    final messageId = messageStarUnstarRequest.id;

    try {
      response = await _httpClient.post(
        Uri.parse('$_url$messageStarOrUnstarURL/$messageId'),
        body: jsonEncode(
          messageStarUnstarRequest.toJson(),
        ),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<Message>.from(
            json.decode(response.body).map((item) => Message.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<MessageThread>> markMessageThreadReadOrUnread(
      MessageMarkReadUnreadRequest messageMarkReadUnreadRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    final threadId = messageMarkReadUnreadRequest.threadId;

    try {
      response = await _httpClient.put(
        Uri.parse('$_url$messagesURL/$threadId'),
        body: jsonEncode(
          messageMarkReadUnreadRequest.toJson(),
        ),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<MessageThread>.from(json
            .decode(response.body)
            .map((item) => MessageThread.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<int> getLastMessageThreadId(int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      response = await _httpClient.get(
        Uri.parse('$_url$messageLastThreadStatusURL/$memberId'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final lastMessageThreadStatus =
            LastMessageThreadStatus.fromJson(jsonDecode(response.body));
        return lastMessageThreadStatus.threadId;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<Post>> getPosts(PostsGetRequest postsGetRequest) async {
    final token = _getTokenOrThrow();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse(_url + postsURL),
      );
      request.body = jsonEncode(postsGetRequest.toJson());
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<Post>.from(
            json.decode(response.body).map((item) => Post.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<PostMedia> getPostMedia(int postMediaId) async {
    final token = _getTokenOrThrow();

    http.Response? response;

    try {
      response = await _httpClient.get(
        Uri.parse('$_url$postMediaURL/$postMediaId'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final postMedia = PostMedia.fromJson(jsonDecode(response.body));
        return postMedia;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<Notification>> getNotifications(
      NotificationsGetRequest notificationsGetRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse(_url + notificationsURL),
      );
      request.body = jsonEncode(notificationsGetRequest.toJson());
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<Notification>.from(json
            .decode(response.body)
            .map((item) => Notification.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<Notification>> updateNotification(
      NotificationUpdateRequest notificationUpdateRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    final notificationId = notificationUpdateRequest.id;

    try {
      response = await _httpClient.put(
        Uri.parse('$_url$notificationsURL/$notificationId'),
        body: jsonEncode(
          notificationUpdateRequest.toJson(),
        ),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<Notification>.from(json
            .decode(response.body)
            .map((item) => Notification.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<MemberBlocked>> getBlockedMembers(
      BlockedMembersGetRequest blockedMembersGetRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse(_url + blockedMembersURL),
      );
      request.body = jsonEncode(blockedMembersGetRequest.toJson());
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<MemberBlocked>.from(json
            .decode(response.body)
            .map((item) => MemberBlocked.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<bool> getMemberBlockedStatus(
      int blockingMemberId, int blockedMemberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse('$_url$blockedMembersURL/status'),
      );
      request.body = jsonEncode(<String, int>{
        'blocked_by_user_id': blockingMemberId,
        'blocked_user_id': blockedMemberId,
      });
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final blocked =
            MemberBlockedStatus.fromJson(jsonDecode(response.body)).blocked;
        return blocked;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<MemberBlocked> blockMember(int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      response = await _httpClient.post(
        Uri.parse(_url + blockedMembersURL),
        body: jsonEncode(<String, int>{
          'user_id': memberId,
        }),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpCreatedStatusCode) {
        final memberBlocked = MemberBlocked.fromJson(jsonDecode(response.body));
        return memberBlocked;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<MemberUnblocked> unblockMember(int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      response = await _httpClient.delete(
        Uri.parse(_url + blockedMembersURL),
        body: jsonEncode(<String, int>{
          'user_id': memberId,
        }),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final memberUnblocked =
            MemberUnblocked.fromJson(jsonDecode(response.body));
        return memberUnblocked;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<bool> getMemberSuspendedStatus(int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      response = await _httpClient.get(
        Uri.parse('$_url$suspendedMemberStatusURL/$memberId'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final suspended =
            MemberSuspendedStatus.fromJson(jsonDecode(response.body)).suspended;
        return suspended;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<bool> reportMember(MemberReportRequest memberReportRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      response = await _httpClient.post(
        Uri.parse(_url + reportsURL),
        body: jsonEncode(memberReportRequest),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpCreatedStatusCode) {
        final reported =
            ReportedStatus.fromJson(jsonDecode(response.body)).reported;
        return reported;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<MemberFavourite>> getFavouriteMembers(
      MemberFavouritesGetRequest memberFavouritesGetRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse(_url + favouriteMembersURL),
      );
      request.body = jsonEncode(memberFavouritesGetRequest.toJson());
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final favouriteMembers = List<MemberFavourite>.from(json
            .decode(response.body)
            .map((item) => MemberFavourite.fromJson(item)));
        for (int i = favouriteMembers.length - 1; i >= 0; i--) {
          if (favouriteMembers[i].member == null) {
            favouriteMembers.removeAt(i);
          }
          populateMemberAgeGenderLocation(favouriteMembers[i].member!);
          populateMatchPercentage(currentUser!, favouriteMembers[i].member!);
          populateLastActivity(favouriteMembers[i].member!);
          favouriteMembers[i].member!.isBlocked = false;
          favouriteMembers[i].member!.isFavourite = true;
        }
        return favouriteMembers;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<MemberFavourite> addFavouriteMember(int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      response = await _httpClient.post(
        Uri.parse(_url + favouriteMembersURL),
        body: jsonEncode(<String, int>{
          'user_id': memberId,
        }),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpCreatedStatusCode) {
        final memberFavorite =
            MemberFavourite.fromJson(jsonDecode(response.body));
        return memberFavorite;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<MemberFavouriteRemoved> removeFavouriteMember(int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      response = await _httpClient.delete(
        Uri.parse(_url + favouriteMembersURL),
        body: jsonEncode(<String, int>{
          'user_id': memberId,
        }),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final memberFavouriteRemoved =
            MemberFavouriteRemoved.fromJson(jsonDecode(response.body));
        return memberFavouriteRemoved;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<bool> getMemberFavouriteStatus(int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse('$_url$favouriteMembersURL/status'),
      );
      request.body = jsonEncode(<String, int>{
        'favourite_user_id': memberId,
      });
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final favourite =
            MemberFavouriteStatus.fromJson(jsonDecode(response.body)).favourite;
        return favourite;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<MemberFavouritedBy>> getFavouritedByMembers(
      MemberFavouritesGetRequest memberFavouritesGetRequest) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse(_url + favouritedByMembersURL),
      );
      request.body = jsonEncode(memberFavouritesGetRequest.toJson());
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final favouriteMembers = List<MemberFavouritedBy>.from(json
            .decode(response.body)
            .map((item) => MemberFavouritedBy.fromJson(item)));
        for (final favouriteMember in favouriteMembers) {
          populateMemberAgeGenderLocation(favouriteMember.member);
          populateMatchPercentage(currentUser!, favouriteMember.member);
          populateLastActivity(favouriteMember.member);
          favouriteMember.member.isBlocked = false;
        }
        return favouriteMembers;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<bool> getFavouritedByMemberStatus(int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse('$_url$favouriteMembersURL/status'),
      );
      request.body = jsonEncode(<String, int>{
        'favourited_by_user_id': memberId,
      });
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final favourite =
            MemberFavouriteStatus.fromJson(jsonDecode(response.body)).favourite;
        return favourite;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<PhotoVerificationStatus> getPhotoVerificationStatus(
      int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse('$_url$photoVerificationRequestsURL/status'),
      );
      request.body = jsonEncode(<String, int>{
        'user_id': memberId,
      });
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final photoVerificationStatus =
            PhotoVerificationStatus.fromJson(jsonDecode(response.body));
        return photoVerificationStatus;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<PhotoVerificationPrompt> getPhotoVerificationRandomPrompt() async {
    final token = _getTokenOrThrow();

    http.Response? response;

    try {
      response = await _httpClient.get(
        Uri.parse('$_url$photoVerificationPromptsURL/random'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final photoVerificationPrompt =
            PhotoVerificationPrompt.fromJson(jsonDecode(response.body));
        return photoVerificationPrompt;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<bool> sendPhotoVerificationRequest(
      int promptId, String filePath) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();

    http.Response? response;

    final file = File(filePath);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_url$photoVerificationRequestsURL/?prompt_id=$promptId'),
      );
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        await File.fromUri(Uri.parse(file.path)).readAsBytes(),
        contentType: MediaType('image', 'jpeg'),
        filename: basename(file.path),
      ));

      final streamedResponse = await _httpClient.send(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpCreatedStatusCode) {
        final requested =
            PhotoVerificationRequestResult.fromJson(jsonDecode(response.body))
                .requested;
        return requested;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<PnfpbFirebaseTokenRegistrationResult> registerFirebaseTokenWithPnfpb(
      String firebaseToken) async {
    final token = _getTokenOrThrow();

    http.Response? response;

    try {
      response = await _httpClient.post(
        Uri.parse(_url + pnfpbSubscriptionTokenURL),
        body: jsonEncode(<String, String>{
          'token': firebaseToken,
        }),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final registrationResult =
            PnfpbFirebaseTokenRegistrationResult.fromJson(
                jsonDecode(response.body));
        return registrationResult;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  late String _url;

  @override
  String get serverUrl => _url;

  @override
  set serverUrl(String? value) {
    assert(value != null);
    _url = value!;
  }

  @override
  String? get userAgent => _httpClient.userAgent;

  @override
  String? get token => _token;

  @override
  Member? get currentUser => _currentUser;

  Member? _currentUser;
  set currentUser(Member? value) {
    assert(currentUser != null);
    _currentUser = value;
  }

  @override
  String? get currentUserEmailAddress => _currentUserEmailAddress;

  String? _currentUserEmailAddress;
  set currentUserEmailAddress(String? value) {
    assert(_currentUserEmailAddress != null);
    _currentUserEmailAddress = value;
  }

  @override
  List<XProfileField>? get xProfileFields => _xProfileFields;

  List<XProfileField>? _xProfileFields;
  set xProfileFields(List<XProfileField>? value) {
    assert(xProfileFields != null);
    _xProfileFields = value;
  }

  Exception _processException(
    Exception exception,
    http.Response? response, {
    bool unauthenticated = false,
  }) {
    //Note: The exception types here need to contain at least a message, otherwise they won't get captured by the catch(e) from the caller.
    if (response != null && response.body.isNotEmpty) {
      if (response.body.contains('You are temporarily locked out') ||
          response.body.contains('error code: 1015')) {
        return GenericUserAccessException(
            title: 'Temporary Lock',
            message:
                'You have been temporarily locked out due to multiple failed log in attempts. Please try again later.');
      } else if (response.body.contains(
              'Your access to this site has been limited by the site owner') ||
          response.body.contains('error code: 1005') ||
          response.body.contains('error code: 1006') ||
          response.body.contains('error code: 1020')) {
        return GenericUserAccessException(
            title: 'Blocked',
            message:
                'Your access to this service has been blocked. If you think you have been blocked in error, please email $supportEmail.');
      }
    }

    if (exception is BadRequestResponseException) {
      var data = exception.badRequestResponse.data;
      if (data != null) {
        final smsVerificationTooManyRequestsException =
            SMSVerificationNotAvailableException(
          title: "Too Many Requests",
          message:
              "You've submitted too many SMS code requests. Please try again later.",
        );
        switch (data.status) {
          case httpBadResponseCodeNotAuthenticated:
          case httpBadResponseCodeForbidden:
            {
              if (unauthenticated) {
                if (exception.badRequestResponse.code ==
                    httpBadResponseMessageCodeRestCannotAccess) {
                  return GenericRequestException(
                      exception.badRequestResponse.message);
                }
                const errorMessage =
                    'The email and password combination you entered is incorrect. Please check and try again.';
                // For activated accounts.
                if (exception.badRequestResponse.message.contains('ERROR:') &&
                    exception.badRequestResponse.message
                        .contains('Lost your password?')) {
                  return GenericRequestException(errorMessage);
                }
                // For pending accounts.
                if (exception.badRequestResponse.message.contains(
                    'Error: The username or password you entered is incorrect.')) {
                  return GenericRequestException(errorMessage);
                }
              } else if (exception.badRequestResponse.code ==
                      httpBadResponseNiftyThreeInvalidMemberId ||
                  exception.badRequestResponse.code ==
                      httpBadResponseNiftyThreeSuspendedUser ||
                  exception.badRequestResponse.code ==
                      httpBadResponseNiftyThreeBlockedUser) {
                return InvalidUserException();
              } else if (exception.badRequestResponse.code ==
                  httpBadResponseNiftyThreePhotoVerificationRequestExists) {
                return GenericRequestException(
                    exception.badRequestResponse.message);
              } else if (exception.badRequestResponse.code ==
                  httpBadResponseNiftyThreeSmsVerificationPhoneNumberBlacklisted) {
                return SMSVerificationNotAvailableException(
                  title: "Blacklisted",
                  message:
                      "The phone number that you have entered has been blacklisted. Please use another phone number.",
                );
              } else if (exception.badRequestResponse.code ==
                  httpBadRequestPhotoVerificationRequired) {
                return GenericRequestException(
                    "Please verify your account first before uploading a profile photo.");
              } else if (exception.badRequestResponse.code ==
                  httpBadResponseNiftyThreePhotoVerificationRequestRestricted) {
                return GenericRequestException(
                    "You recently submitted a verification request, please wait a while before trying again.");
              } else if (exception.badRequestResponse.code ==
                  httpBadResponseInvalidMemberId) {
                return DeletedUserException();
              } else if (exception.badRequestResponse.code ==
                  httpBadResponseNiftyThreeUnsupportedAppVersion) {
                return GenericUserAccessException(
                    title: 'Unsupported App Version',
                    message: exception.badRequestResponse.message);
              } else {
                return GenericUserAccessException(
                    title: 'Session Expired',
                    message: 'Your session has expired, please log in again.');
              }
            }
          case httpBadRequest:
            {
              if (exception.badRequestResponse.message.contains(
                  'For best image quality, upload a picture larger than 350 x 400 pixels.')) {
                return GenericRequestException(
                    'Picture is too small. For best image quality, upload a picture larger than 350 x 400 pixels.');
              }

              if (exception.badRequestResponse.message
                  .contains('You already reported it earlier.')) {
                return DuplicateReportException();
              }

              if (exception.badRequestResponse.code ==
                      httpBadResponseNiftyThreeInvalidMemberId ||
                  exception.badRequestResponse.code ==
                      httpBadResponseNiftyThreeSuspendedUser ||
                  exception.badRequestResponse.code ==
                      httpBadResponseNiftyThreeBlockedUser) {
                return InvalidUserException();
              } else if (exception.badRequestResponse.code ==
                  httpBadResponseInvalidMemberId) {
                return DeletedUserException();
              } else if (exception.badRequestResponse.code ==
                  httpBadResponseNiftyThreeSmsVerificationOtpSendError) {
                if (exception.badRequestResponse.message.contains('HTTP 429')) {
                  return smsVerificationTooManyRequestsException;
                }
                return SMSVerificationNotAvailableException();
              }
            }
          case httpBadResponseCodeNotFound:
            {
              if (exception.badRequestResponse.code ==
                  httpBadResponseMessageCodeNoRestRoute) {
                return GenericRequestException(
                    localisedErrorMessageCouldNotProcessRequest);
              } else if (exception.badRequestResponse.code ==
                      httpBadResponseNiftyThreeInvalidMemberId ||
                  exception.badRequestResponse.code ==
                      httpBadResponseNiftyThreeSuspendedUser ||
                  exception.badRequestResponse.code ==
                      httpBadResponseNiftyThreeBlockedUser) {
                return InvalidUserException();
              } else if (exception.badRequestResponse.code ==
                  httpBadResponseInvalidMemberId) {
                return DeletedUserException();
              }
            }
          case httpBadResponseCodeTooManyRequests:
            {
              if (exception.badRequestResponse.code ==
                  httpBadResponseNiftyThreeSmsVerificationRateLimitExceeded) {
                return smsVerificationTooManyRequestsException;
              }
            }
        }
      }
    } else if (response != null &&
        (response.statusCode == httpInternalServerError ||
            response.statusCode == httpServiceUnavailable)) {
      const errorMessage = localisedErrorMessageCouldNotProcessRequest;
      if (unauthenticated) {
        return GenericRequestException(errorMessage);
      }
      return GenericUserAccessException(
          title: localisedGenericFriendlyErrorTitleText, message: errorMessage);
    } else if (exception is FormatException) {
      return GenericRequestException('Unexpected data format encountered.');
    } else if (exception is TimeoutException) {
      return GenericRequestException(
          'Could not complete the request. Please check your connection, or try again later.');
    } else if (exception is SocketException) {
      const errorMessage =
          'Could not connect. Please check your connection, or try again later.';
      if (unauthenticated) {
        return GenericRequestException(errorMessage);
      }
      return GenericUserAccessException(
          title: localisedGenericFriendlyErrorTitleText, message: errorMessage);
    } else if (exception is HttpException) {
      return GenericRequestException(
          localisedErrorMessageGenericRequestException);
    } else if (exception is http.ClientException) {
      return GenericRequestException(
          localisedErrorMessageGenericRequestException);
    }

    return exception;
  }

  @override
  Future<List<XProfileField>> getXProfileSignUpFields() async {
    http.Response? response;

    try {
      response = await _httpClient.get(
        Uri.parse(_url + xProfileSignUpFieldsURL),
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<XProfileField>.from(json
            .decode(response.body)
            .map((item) => XProfileField.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response, unauthenticated: true);
    }
  }

  @override
  Future<SignUpAvailability> checkSignUpAvailability(
      SignUpAvailabilityGetRequest signUpAvailabilityGetRequest) async {
    http.Response? response;

    try {
      final request = http.Request(
        'GET',
        Uri.parse(_url + checkSignUpAvailabilityURL),
      );
      request.body = jsonEncode(signUpAvailabilityGetRequest.toJson());

      final streamedResponse = await _httpClient.getWithJsonBody(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpSuccessStatusCode) {
        final signUpAvailability =
            SignUpAvailability.fromJson(jsonDecode(response.body));
        return signUpAvailability;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response, unauthenticated: true);
    }
  }

  @override
  Future<bool> signUp(Map<String, dynamic> registrationData) async {
    http.Response? response;

    try {
      response = await _httpClient.post(
        Uri.parse(_url + signUpURL),
        body: jsonEncode(
          registrationData,
        ),
      );

      if (response.statusCode == httpSuccessStatusCode) {
        return true;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response, unauthenticated: true);
    }
  }

  @override
  Future<bool> activateAccount(String activationKey) async {
    http.Response? response;

    try {
      response = await _httpClient.put(
        Uri.parse('$_url$activateAccountURL/$activationKey'),
        body: jsonEncode(<String, String>{
          'context': 'edit',
          'activation_key': activationKey
        }),
      );

      if (response.statusCode == httpSuccessStatusCode) {
        return true;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response, unauthenticated: true);
    }
  }

  // Disposable email functions
  @override
  Future<bool> checkDisposableEmail(String email, bool ignoreExceptions) async {
    http.Response? response;

    try {
      response = await _disposableEmailCheckHttpClient.get(
        Uri.parse('$debounceDisposableURL?email=$email'),
      );

      // 200 is returned regardless of if there is an error in the request.
      if (response.statusCode == httpSuccessStatusCode) {
        final json = jsonDecode(response.body);
        if (json['disposable'] != null) {
          return DebounceResponse.fromJson(json).disposable;
        } else if (json['debounce'] != null) {
          final debounceBadRequestResponse =
              DebounceBadRequestResponse.fromJson(jsonDecode(response.body));
          throw DebounceBadRequestResponseException(debounceBadRequestResponse);
        }
      }

      if (ignoreExceptions) return false;
      throw GenericRequestException('Unexpected response.');
    } on Exception catch (e) {
      if (ignoreExceptions) return false;
      throw _processDebounceException(e, response);
    }
  }

  Exception _processDebounceException(
    Exception exception,
    http.Response? response,
  ) {
    if (exception is DebounceBadRequestResponseException) {
      var data = exception.debounceBadRequestResponse.data;
      if (data != null) {
        return GenericRequestException(
            data.error ?? localisedErrorMessageGenericRequestException);
      }
    } else if (exception is FormatException) {
      return GenericRequestException('Unexpected data format encountered.');
    } else if (exception is TimeoutException) {
      return GenericRequestException(
          'Could not complete the request. Please check your connection, or try again later.');
    } else if (exception is SocketException) {
      return GenericUserAccessException(
          title: localisedGenericFriendlyErrorTitleText,
          message:
              'Could not connect. Please check your connection, or try again later.');
    } else if (exception is HttpException) {
      return GenericRequestException(
          localisedErrorMessageGenericRequestException);
    } else if (exception is http.ClientException) {
      return GenericRequestException(
          localisedErrorMessageGenericRequestException);
    }

    return exception;
  }

  @override
  Future<MemberPhoneNumberDeleted> deleteMemberPhoneNumber(int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      response = await _httpClient.delete(
        Uri.parse('$_url$smsVerificationPhoneNumberUrl/$memberId'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final memberPhoneNumberDeleted =
            MemberPhoneNumberDeleted.fromJson(jsonDecode(response.body));
        return memberPhoneNumberDeleted;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<MemberPhoneNumber> getMemberPhoneNumber(int memberId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();
    await _refreshCurrentUserActivity();

    http.Response? response;

    try {
      response = await _httpClient.get(
        Uri.parse('$_url$smsVerificationPhoneNumberUrl/$memberId'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final memberPhoneNumber =
            MemberPhoneNumber.fromJson(jsonDecode(response.body));
        return memberPhoneNumber;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<SmsVerificationSystemStatus> getSmsVerificationSystemStatus() async {
    http.Response? response;

    try {
      response = await _httpClient.get(
        Uri.parse(_url + smsVerificationAvailableUrl),
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final smsVerificationSystemStatus =
            SmsVerificationSystemStatus.fromJson(jsonDecode(response.body));
        return smsVerificationSystemStatus;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<SmsCodeRequestResult> requestSmsCode(
      SmsCodeRequest smsCodeRequest) async {
    http.Response? response;

    try {
      response = await _httpClient.post(
          Uri.parse(_url + smsVerificationRequestSmsCodeUrl),
          body: jsonEncode(
            smsCodeRequest.toJson(),
          ),
          headers: _currentUser != null
              ? {HttpHeaders.authorizationHeader: "Bearer $token"}
              : null);

      if (response.statusCode == httpSuccessStatusCode) {
        final smsCodeRequestResult =
            SmsCodeRequestResult.fromJson(jsonDecode(response.body));
        return smsCodeRequestResult;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<VerifySmsCodeResult> verifySmsCode(
      VerifySmsCodeRequest verifySmsCodeRequest) async {
    http.Response? response;

    try {
      response = await _httpClient.post(
          Uri.parse(_url + smsVerificationVerifySmsCodeUrl),
          body: jsonEncode(
            verifySmsCodeRequest.toJson(),
          ),
          headers: _currentUser != null
              ? {HttpHeaders.authorizationHeader: "Bearer $token"}
              : null);

      if (response.statusCode == httpSuccessStatusCode) {
        final verifySmsCodeResult =
            VerifySmsCodeResult.fromJson(jsonDecode(response.body));
        if (_currentUser != null) {
          await refreshCurrentUser();
        } else {
          final authResult = verifySmsCodeResult.auth;
          if (authResult != null &&
              authResult.token != null &&
              authResult.token!.isNotEmpty) {
            _token = authResult.token;
            _currentUserEmailAddress = authResult.userEmail;
            _currentUser = await getCurrentUser();
            _xProfileFields = await getXProfileFields();
          }
        }
        return verifySmsCodeResult;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<MultiplePhotoSystemStatus> getMultiplePhotoSystemStatus() async {
    http.Response? response;

    try {
      response = await _httpClient.get(
        Uri.parse(_url + multiplePhotoManagementAvailableUrl),
        //TODO: Does this need to be here? It's not there in hello!. Maybe if the user is verified this is not required.
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final multiplePhotoSystemStatus =
            MultiplePhotoSystemStatus.fromJson(jsonDecode(response.body));
        return multiplePhotoSystemStatus;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<MemberPhoto>> getUserPhotos() async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();

    http.Response? response;

    final userId = currentUser?.id;

    try {
      response = await _httpClient.get(
        Uri.parse('$_url$multiplePhotoManagementUrl/$userId/photos'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final result = List<MemberPhoto>.from(json
            .decode(response.body)
            .map((item) => MemberPhoto.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response, unauthenticated: true);
    }
  }

  @override
  Future<MemberPhotosDeleted> deleteUserPhotos() async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();

    http.Response? response;

    final userId = currentUser?.id;

    try {
      response = await _httpClient.delete(
        Uri.parse('$_url$multiplePhotoManagementUrl/$userId/photos'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final memberPhotosDeleted =
            MemberPhotosDeleted.fromJson(jsonDecode(response.body));
        return memberPhotosDeleted;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<MemberPhotoDeleted> deleteUserPhoto(int mediaId) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();

    http.Response? response;

    final userId = currentUser?.id;

    try {
      response = await _httpClient.delete(
        Uri.parse('$_url$multiplePhotoManagementUrl/$userId/photos/$mediaId'),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );

      if (response.statusCode == httpSuccessStatusCode) {
        final memberPhotoDeleted =
            MemberPhotoDeleted.fromJson(jsonDecode(response.body));
        return memberPhotoDeleted;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }

  @override
  Future<List<MemberPhoto>> updateUserPhotos(
      List<MemberPhotoUpdate> memberPhotoUpdates) async {
    final token = _getTokenOrThrow();
    _getCurrentUserOrThrow();

    http.Response? response;

    final userId = currentUser?.id;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_url$multiplePhotoManagementUrl/$userId/photos'),
      );
      request.headers
          .addAll({HttpHeaders.authorizationHeader: "Bearer $token"});
      for (int i = 0; i < memberPhotoUpdates.length; i++) {
        if (memberPhotoUpdates[i].file != null) {
          final file = File(memberPhotoUpdates[i].file!);
          request.files.add(http.MultipartFile.fromBytes(
            'file$i',
            await File.fromUri(Uri.parse(file.path)).readAsBytes(),
            contentType: MediaType('image', 'jpeg'),
            filename: basename(file.path),
          ));
          request.fields['photos[$i][file]'] = 'file$i';
        }
        if (memberPhotoUpdates[i].mediaId != null) {
          request.fields['photos[$i][media_id]'] =
              memberPhotoUpdates[i].mediaId!.toString();
        }
        request.fields['photos[$i][sequence]'] =
            memberPhotoUpdates[i].sequence.toString();
        request.fields['photos[$i][type]'] =
            memberPhotoUpdates[i].type == MemberPhotoType.avatar
                ? 'avatar'
                : 'photo';
      }

      final streamedResponse = await _httpClient.send(request);
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == httpCreatedStatusCode) {
        final result = List<MemberPhoto>.from(json
            .decode(response.body)
            .map((item) => MemberPhoto.fromJson(item)));
        return result;
      } else {
        final badRequestResponse =
            BadRequestResponse.fromJson(jsonDecode(response.body));
        throw BadRequestResponseException(badRequestResponse);
      }
    } on Exception catch (e) {
      throw _processException(e, response);
    }
  }
}
