import 'dart:io';

import 'package:app_base/dialogs/widget_information_dialog.dart';
import 'package:arvo/constants/localised_assets.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/views/shared/avatar_placeholder.dart';
import 'package:arvo/views/shared/x_profile_concat_location_utilities.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/views/member_reporting/report_member_view.dart';
import 'package:nifty_three_bp_app_base/api/multiple_photo.dart';
import 'package:nifty_three_bp_app_base/constants/reporting.dart';
import 'package:nifty_three_bp_app_base/enums/member_photo_type.dart';
import 'package:nifty_three_bp_app_base/enums/photo_verification_status_type.dart';
import 'package:nifty_three_bp_app_base/extensions/string.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:nifty_three_bp_app_base/views/widgets/circle_avatar.dart';
import 'package:nifty_three_bp_app_base/views/picture_viewer_view.dart';
import 'package:app_base/dialogs/success_dialog.dart';
import 'package:app_base/extensions/string_extensions.dart';
import 'package:app_base/widgets/quick_info_widget.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

typedef EditProfilePicturesCallback = void Function(BuildContext);
typedef EditProfileGroupCallback = void Function(BuildContext, int);
typedef PhotoVerificationCallback = void Function(BuildContext);
typedef ToggleMatchInsightCallback = void Function();
typedef PremiumTappedCallback = void Function();
typedef ProfilePictureTappedCallback = void Function();
typedef VerificationTappedCallback = void Function();
typedef ReportMemberTappedCallback = void Function();

class MemberProfileWidget extends StatelessWidget {
  final String serverUrl;
  final Member member;
  final Member currentUser;
  final EditProfilePicturesCallback? editProfilePictures;
  final EditProfileGroupCallback? editProfileGroup;
  final PhotoVerificationCallback? verify;
  final ToggleMatchInsightCallback? toggleMatchInsight;
  final PremiumTappedCallback? premiumTapped;
  final bool matchInsight;
  final bool hasFeatureMemberOnlineIndicator;
  final ScrollController? scrollController;
  final ProfilePictureTappedCallback? profilePictureTapped;
  final VerificationTappedCallback? verificationTapped;
  final ReportMemberTappedCallback? reportMemberTapped;
  const MemberProfileWidget(
      {super.key,
      required this.serverUrl,
      required this.member,
      required this.currentUser,
      this.editProfilePictures,
      this.editProfileGroup,
      this.verify,
      this.toggleMatchInsight,
      this.premiumTapped,
      required this.matchInsight,
      required this.hasFeatureMemberOnlineIndicator,
      this.scrollController,
      this.profilePictureTapped,
      this.verificationTapped,
      this.reportMemberTapped});

  @override
  Widget build(BuildContext context) {
    return _buildMemberProfileWidget(context);
  }

  Widget _buildMemberProfileWidget(BuildContext context) {
    List<Widget> profileDataWidgets = [];
    // Fields that will be skipped and not displayed.
    List<int> ignoreDataFields = [
      xProfileFieldName,
      xProfileFieldTermsAcceptance,
    ];
    // Fields that will be displayed as a collection of items.
    List<int> quickInfoDataFields = [
      xProfileFieldGender,
      xProfileFieldLocation,
      xProfileFieldBirthdate,
      xProfileFieldStatus,
      xProfileFieldSexualOrientation,
      xProfileFieldOftenAlcohol,
      xProfileFieldOftenSmoke,
      xProfileFieldConnection,
      xProfileFieldLookingFor,
    ];
    // Fields that will be displayed on top in the group that it belongs to.
    List<int> keepOnTopDataFields = [
      xProfileFieldWhatYouNeedToKnow,
    ];
    // Fields for which we need to use the rendered value instead of the
    // unserialized value because the API formats them differently.
    List<int> useRenderedValueDataFields = [
      xProfileFieldBirthdate,
    ];
    // Fields that contain free text.
    List<int> freeTextDataFields = [
      xProfileFieldWhatYouNeedToKnow,
      xProfileFieldWhatImLookingFor
    ];

    // Extract profile photos to be added later.
    final profilePhotos = (member.photos != null)
        ? (member.id == currentUser.id)
            ? member.photos!
                .where((photo) => photo.type == MemberPhotoType.gallery)
                .toList()
            : member.photos!
                .where((photo) =>
                    photo.type == MemberPhotoType.gallery &&
                    photo.status == MemberPhotoModerationStatusType.approved)
                .toList()
        : [];
    profilePhotos.sort((a, b) => a.sequence.compareTo(b.sequence));
    int profilePhotoIndex = 0;

    // Add member avatar.
    final memberAvatar = (member.photos != null)
        ? (member.id == currentUser.id)
            ? member.photos!
                .where((photo) => photo.type == MemberPhotoType.avatar)
                .firstOrNull
            : member.photos!
                .where((photo) =>
                    photo.type == MemberPhotoType.avatar &&
                    photo.status == MemberPhotoModerationStatusType.approved)
                .firstOrNull
        : null;
    profileDataWidgets.add(_buildMemberAvatarWidget(context, memberAvatar));

    // Add profile data.
    for (final group in member.xProfile!.groups) {
      List<ProfileDataField> groupFieldData = [];
      List<Widget> quickInfoWidgets = [];
      List<Widget> keepOnTopWidgets = [];
      double groupCompletionPercentage =
          member.profileGroupCompletionPercentage[group.id] ?? 0;

      for (final field in group.fields) {
        if (ignoreDataFields.contains(field.id)) {
          continue;
        }

        late final String fieldValue;
        late final List<String> fieldValues;

        // For fields that the API renders differently for display (such as birthdate)
        if (useRenderedValueDataFields.contains(field.id)) {
          final renderedValue = field.value?.rendered;
          fieldValue = renderedValue == null
              ? ''
              : renderedValue.parseHTML().replaceAll("\n", "");
          fieldValues = [];
        } else {
          fieldValue = field.value?.unserialized
                  ?.join(', ')
                  .removeEscapeCharacters()
                  .parseHTML() ??
              '';
          field.value?.unserialized?.forEach((value) {
            value.removeEscapeCharacters().parseHTML();
          });
          fieldValues = field.value?.unserialized ?? [];
        }

        // No data for this field, so only add if viewing the current user's profile.
        if (fieldValues.isEmpty && member.id != currentUser.id) {
          continue;
        }

        groupFieldData.add(
          ProfileDataField(
            id: field.id,
            name: field.name,
            value: fieldValue,
            values: fieldValues,
          ),
        );
      }

      // Add group only if there is data is this group,
      // or if it is the current user's profile.
      if (groupFieldData.isNotEmpty || (member.id == currentUser.id)) {
        List<Widget> profileGroupDataWidgets = [];

        // Add group title.
        profileGroupDataWidgets.add(
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  (member.id == currentUser.id)
                      ? FloatingActionButton.small(
                          heroTag: null,
                          elevation: 3.0,
                          shape: const CircleBorder(),
                          onPressed: () {
                            if (editProfileGroup != null) {
                              editProfileGroup!(context, group.id);
                            }
                          },
                          child: const Icon(
                            Icons.edit_rounded,
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              // Add some space between the group header and data,
              // but only if there is data in this group.
              groupFieldData.isNotEmpty
                  ? const SizedBox(
                      height: 8.0,
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        );

        // Add group data.
        for (final data in groupFieldData) {
          if (data.value.isNotEmpty) {
            // If this field needs to be displayed as a quick info item then add it
            // to the quick info widget, otherwise add it as a normal field.
            if (quickInfoDataFields.contains(data.id)) {
              var icon = getXProfileFieldDataIcon(
                data.id,
                data.value,
              );
              var prefix = getXProfileFieldDataPrefix(
                data.id,
                data.value,
              );
              if (data.id == xProfileFieldConnection) {
                for (final value in data.values) {
                  quickInfoWidgets.add(
                    buildQuickInfoWidget(
                      context: context,
                      text: value,
                      iconData: icon,
                      prefix: prefix,
                    ),
                  );
                }
              } else if (data.id == xProfileFieldLocation) {
                quickInfoWidgets.add(
                  buildQuickInfoWidget(
                    context: context,
                    text: locationDisplayFormatter(data.value),
                    iconData: icon,
                    prefix: prefix,
                  ),
                );
              } else {
                quickInfoWidgets.add(
                  buildQuickInfoWidget(
                    context: context,
                    text: data.value,
                    iconData: icon,
                    prefix: prefix,
                  ),
                );
              }
            } else if (keepOnTopDataFields.contains(data.id)) {
              if (freeTextDataFields.contains(data.id)) {
                if (data.value.containsContactDetails().isNotEmpty) {
                  keepOnTopWidgets.add(
                    _buildContactInformationInProfileGroupNotificationWidget(
                        context, group.id),
                  );
                }
              }
              keepOnTopWidgets.add(
                Text(
                  data.value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            } else {
              List<Widget> dataWidget = [];
              if (freeTextDataFields.contains(data.id)) {
                if (data.value.containsContactDetails().isNotEmpty) {
                  dataWidget.add(
                    _buildContactInformationInProfileGroupNotificationWidget(
                        context, group.id),
                  );
                }
              }
              dataWidget.add(
                Text(
                  data.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
              dataWidget.add(
                Text(
                  data.value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );

              if (matchInsight) {
                if (member.matchedFields != null) {
                  if (member.matchedFields!.contains(data.id)) {
                    profileGroupDataWidgets
                        .add(_buildMatchedFieldWidget(context, dataWidget));
                  } else {
                    profileGroupDataWidgets.addAll(dataWidget);
                  }
                }
              } else {
                profileGroupDataWidgets.addAll(dataWidget);
              }

              profileGroupDataWidgets.add(
                const SizedBox(height: 8.0),
              );
            }
          }
        }

        if (keepOnTopWidgets.isNotEmpty) {
          profileGroupDataWidgets.insert(
            1,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: setHeightBetweenWidgets(keepOnTopWidgets,
                  height: 8.0, footer: true),
            ),
          );
        }

        if (quickInfoWidgets.isNotEmpty) {
          profileGroupDataWidgets.insert(
            1,
            Column(
              children: [
                Wrap(children: quickInfoWidgets),
                const SizedBox(
                  height: 8.0,
                ),
              ],
            ),
          );
        }

        // Add group title and data to a column.
        var profileGroupDataColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: profileGroupDataWidgets,
        );

        // Add to a container, with borders.
        var groupFieldDataContainer = Container(
          clipBehavior: Clip.antiAlias,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 5.0,
                spreadRadius: 1.0,
                offset: const Offset(1.0, 1.0),
              )
            ],
          ),
          child: Column(
            children: [
              (member.id == currentUser.id)
                  ? LinearProgressIndicator(
                      minHeight: 8.0,
                      value: groupCompletionPercentage,
                      color: getProfileCompletionPercentageColour(
                          groupCompletionPercentage),
                    )
                  : const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: profileGroupDataColumn,
              ),
            ],
          ),
        );

        // Add to the return list.
        profileDataWidgets.add(const SizedBox(height: 8.0));
        profileDataWidgets.add(groupFieldDataContainer);

        // Add profile photo in position.
        if (profilePhotoIndex < profilePhotos.length) {
          profileDataWidgets.add(const SizedBox(height: 8.0));
          profileDataWidgets.add(_buildMemberPhotoWidget(
              context, profilePhotos[profilePhotoIndex]));
          profilePhotoIndex = profilePhotoIndex + 1;
        }
      }
    }

    // Add remaining profile photos.
    for (int i = profilePhotoIndex; i < profilePhotos.length; i++) {
      profileDataWidgets.add(const SizedBox(height: 8.0));
      profileDataWidgets
          .add(_buildMemberPhotoWidget(context, profilePhotos[i]));
    }

    var profileDataWidgetsScrollView = SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: profileDataWidgets,
        ),
      ),
    );

    return profileDataWidgetsScrollView;
  }

  Widget _buildMatchedFieldWidget(
      BuildContext context, List<Widget> dataWidget) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4.0),
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border.all(
              color: getMatchPercentageColour(member.matchWeight, matchInsight),
              width: 1.6,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dataWidget,
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: getMatchPercentageColour(
                        member.matchWeight, matchInsight),
                    borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                  ),
                  child: const Text(
                    'Match',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberAvatarWidget(
      BuildContext context, MemberPhoto? memberAvatar) {
    final mediaSize = MediaQuery.of(context).size;
    final memberAvatarUrl = memberAvatar?.urls.full ?? member.avatar!.full!;
    return GestureDetector(
      onTap: () async {
        if (memberHasDefaultAvatar(memberAvatarUrl)) {
          return;
        }
        _viewProfilePicture(context, memberAvatarUrl);
        profilePictureTapped?.call();
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            child: ShaderMask(
              shaderCallback: (Rect rect) {
                return LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: const [Colors.transparent, Colors.black],
                  stops: memberHasDefaultAvatar(memberAvatarUrl)
                      ? [0.1, 1.0]
                      : [0.5, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.darken,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5.0,
                      spreadRadius: 1.0,
                      offset: const Offset(1.0, 1.0),
                    )
                  ],
                  image: DecorationImage(
                    image: memberHasDefaultAvatar(memberAvatarUrl)
                        ? getAvatarPlaceholderImage(member.name)
                        : CachedNetworkImageProvider(memberAvatarUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const SizedBox(
                  height: 400.0,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0.0,
            bottom: 0.0,
            width: mediaSize.width - 16.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: setHeightBetweenWidgets(
                  height: 2.0,
                  [
                    _buildNameWidget(),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 2.0,
                      spacing: 4.0,
                      children: [
                        hasFeatureMemberOnlineIndicator
                            ? buildActiveStatusWidget(
                                member,
                                kBaseOnlineColour,
                                kBaseRecentlyOnlineColour,
                                activeText: 'Active',
                                size: 16.0,
                              )
                            : _buildActiveStatusPremiumRequiredWidget(
                                context, premiumTapped),
                        _buildVerificationStatusWidget(context),
                        if (memberAvatar != null)
                          _buildBuildMemberPhotoModerationStatusWidget(
                              context, memberAvatar),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 5.0,
            top: 10.0,
            child: (member.id == currentUser.id)
                ? memberHasDefaultAvatar(memberAvatarUrl)
                    ? const SizedBox.shrink()
                    : FloatingActionButton.small(
                        heroTag: null,
                        elevation: 3.0,
                        shape: const CircleBorder(),
                        onPressed: () {
                          if (editProfilePictures != null) {
                            editProfilePictures!(context);
                          }
                        },
                        child: const Icon(
                          Icons.edit_rounded,
                        ),
                      )
                : Container(
                    height: 48.0,
                    width: 48.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    alignment: Alignment.center,
                    child: FloatingActionButton(
                      heroTag: null,
                      elevation: 3.0,
                      shape: const CircleBorder(),
                      onPressed: toggleMatchInsight,
                      child: CircularPercentIndicator(
                        radius: 22.0,
                        lineWidth: 4.0,
                        backgroundColor: Colors.transparent,
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: getMatchPercentageColour(
                            member.matchWeight, matchInsight),
                        animation: true,
                        animationDuration: 800,
                        percent: (member.matchWeight / 100).toDouble(),
                        center: Text(
                          '${member.matchWeight}%',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            right: 5.0,
            bottom: 10.0,
            child: memberHasDefaultAvatar(memberAvatarUrl)
                ? const SizedBox.shrink()
                : FloatingActionButton.small(
                    heroTag: null,
                    elevation: 3.0,
                    shape: const CircleBorder(),
                    onPressed: () async {
                      _viewProfilePicture(context, memberAvatarUrl);
                      profilePictureTapped?.call();
                    },
                    child: Icon(
                      Platform.isIOS
                          ? CupertinoIcons.arrow_up_left_arrow_down_right
                          : Icons.open_in_full_rounded,
                    ),
                  ),
          ),
          Positioned(
            top: 0.0,
            left: 5.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildMemberProfileTypeWidget(context),
            ),
          ),
          (member.id == currentUser.id &&
                  memberHasDefaultAvatar(memberAvatarUrl))
              ? Container(
                  clipBehavior: Clip.antiAlias,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        topRight: Radius.circular(8.0)),
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5.0,
                        spreadRadius: 1.0,
                        offset: const Offset(1.0, 1.0),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const LinearProgressIndicator(
                        minHeight: 8.0,
                        value: 0.0,
                        color: kBaseColour,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: (member.photoVerificationStatus == null ||
                                member.photoVerificationStatus ==
                                    PhotoVerificationStatusType.approved)
                            ? Row(
                                children: setWidthBetweenWidgets(
                                  width: 8.0,
                                  [
                                    const SizedBox(
                                      height: 32.0,
                                      width: 32.0,
                                      child: Image(
                                        image: AssetImage(
                                          'assets/images/camera.png',
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const Flexible(
                                      child: Text(
                                        'Adding a photo is recommended to help your profile stand out.',
                                      ),
                                    ),
                                    FloatingActionButton.small(
                                      heroTag: null,
                                      elevation: 3.0,
                                      shape: const CircleBorder(),
                                      onPressed: () {
                                        if (editProfilePictures != null) {
                                          editProfilePictures!(context);
                                        }
                                      },
                                      child: const Icon(
                                        Icons.edit_rounded,
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : Row(
                                children: setWidthBetweenWidgets(
                                  width: 8.0,
                                  [
                                    const Flexible(
                                      child: Text(
                                        "Your account needs to be verified before you can upload a photo.",
                                      ),
                                    ),
                                    (member.photoVerificationStatus ==
                                                PhotoVerificationStatusType
                                                    .unverified ||
                                            member.photoVerificationStatus ==
                                                PhotoVerificationStatusType
                                                    .rejected)
                                        ? TextButton(
                                            onPressed: () {
                                              if (verify != null) {
                                                verify!(context);
                                              }
                                            },
                                            child: const Text('Verify Account'),
                                          )
                                        : const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildNameWidget() {
    return Row(
      children: [
        Flexible(
          child: Text(
            member.name!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            '${member.age.toInt()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24.0,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _viewProfilePicture(
      BuildContext context, String imageUrl) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PictureViewerView(
          title: member.name,
          imageUrl: imageUrl,
        ),
      ),
    );
  }

  Widget _buildActiveStatusPremiumRequiredWidget(
      BuildContext context, PremiumTappedCallback? premiumTapped) {
    return GestureDetector(
      onTap: () async {
        Navigator.of(context).pushNamed(subscriptionsViewRoute);
        premiumTapped?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            color: kBasePremiumBackgroundColour,
            borderRadius: BorderRadius.circular(8.0)),
        child: const Text(
          'See online status with Premium',
          style: TextStyle(
              color: kBasePremiumForegroundTextColour, fontSize: 12.0),
        ),
      ),
    );
  }

  Widget _buildVerificationStatusWidget(BuildContext context) {
    return member.photoVerificationStatus != null
        ? (member.id == currentUser.id)
            ? GestureDetector(
                onTap: () async {
                  if (member.photoVerificationStatus ==
                      PhotoVerificationStatusType.approved) {
                    await showWidgetInformationDialog(
                      context: context,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: setHeightBetweenWidgets(
                          height: 16.0,
                          header: true,
                          [
                            Text(
                              'You are a verified user.',
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const Icon(
                              Icons.verified_user_rounded,
                              color: kBaseVerifiedIndicatorColour,
                              size: 64.0,
                            ),
                            Text(
                              'Thank you for verifying your account.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      buttonText: 'Close',
                    );
                  } else if (member.photoVerificationStatus ==
                      PhotoVerificationStatusType.pending) {
                    await showSuccessDialog(
                      context,
                      title: "Verification Pending",
                      "Thank you for submitting a verification photo. We are currently reviewing your request, please check again later.",
                    );
                  } else {
                    if (verify != null) {
                      verify!(context);
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      color: getPhotoVerificationStatusColour(
                        member.photoVerificationStatus!,
                        kBasePendingVerificationIndicatorColour,
                        kBaseVerifiedIndicatorColour,
                        kBaseVerificationRejectedIndicatorColour,
                        kBaseColour,
                      ),
                      borderRadius: BorderRadius.circular(8.0)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: setWidthBetweenWidgets(
                      width: 4.0,
                      [
                        Icon(
                          getPhotoVerificationStatusIcon(
                              member.photoVerificationStatus!),
                          color: Colors.white,
                          size: 16.0,
                        ),
                        Text(
                          getPhotoVerificationStatusDescription(
                              member.photoVerificationStatus!),
                          style: const TextStyle(
                              fontSize: 12.0, color: Colors.white),
                        )
                      ],
                    ),
                  ),
                ),
              )
            : (member.photoVerificationStatus ==
                    PhotoVerificationStatusType.approved)
                ? GestureDetector(
                    onTap: () {
                      showWidgetInformationDialog(
                        context: context,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: setHeightBetweenWidgets(
                            height: 16.0,
                            header: true,
                            [
                              Text(
                                '${member.name} is a verified user.',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                              const Icon(
                                Icons.verified_user_rounded,
                                color: kBaseVerifiedIndicatorColour,
                                size: 64.0,
                              ),
                              Text(
                                'Verified users have authenticated their account by submitting a verification photo.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        buttonText: 'Close',
                      );
                      verificationTapped?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          color: kBaseVerifiedIndicatorColour,
                          borderRadius: BorderRadius.circular(8.0)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: setWidthBetweenWidgets(
                          width: 4.0,
                          [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 16.0,
                              color: Colors.white,
                            ),
                            const Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink()
        : const SizedBox.shrink();
  }

  Widget _buildContactInformationInProfileGroupNotificationWidget(
      BuildContext context, int groupId) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
      ),
      child: Row(
        children: setWidthBetweenWidgets(
          width: 8.0,
          [
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.exclamationmark_triangle_fill
                  : Icons.warning_rounded,
              size: 32.0,
            ),
            Expanded(
              child: (member.id == currentUser.id)
                  ? const Text(
                      'Are you sharing your contact details below? Sharing unsolicited contact information may result in account suspension.',
                    )
                  : Text(
                      '${member.name} may be sharing unsolicited contact information below.',
                    ),
            ),
            (member.id == currentUser.id)
                ? TextButton(
                    onPressed: () {
                      if (editProfileGroup != null) {
                        editProfileGroup!(context, groupId);
                      }
                    },
                    child: const Text('Edit'),
                  )
                : TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportMemberView(
                            member: member,
                            category: reportCategoryProfileContent,
                            description:
                                '${member.name} may be sharing unsolicited contact information.',
                          ),
                        ),
                      );
                      reportMemberTapped?.call();
                    },
                    child: (member.id == currentUser.id)
                        ? const Text('Edit')
                        : const Text('Report'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberPhotoWidget(
      BuildContext context, MemberPhoto memberPhoto) {
    final mediaSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () async {
        _viewProfilePicture(context, memberPhoto.urls.full!);
        profilePictureTapped?.call();
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 5.0,
                    spreadRadius: 1.0,
                    offset: const Offset(1.0, 1.0),
                  )
                ],
                image: DecorationImage(
                  image: CachedNetworkImageProvider(memberPhoto.urls.full!),
                  fit: BoxFit.cover,
                ),
              ),
              child: const SizedBox(
                height: 400.0,
                width: double.infinity,
              ),
            ),
          ),
          (member.id == currentUser.id)
              ? Positioned(
                  right: 5.0,
                  top: 10.0,
                  child: FloatingActionButton.small(
                    heroTag: null,
                    elevation: 3.0,
                    shape: const CircleBorder(),
                    backgroundColor: Colors.black,
                    onPressed: () {
                      if (editProfilePictures != null) {
                        editProfilePictures!(context);
                      }
                    },
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          Positioned(
            left: 0.0,
            bottom: 0.0,
            width: mediaSize.width - 16.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 2.0,
                spacing: 4.0,
                children: [
                  _buildBuildMemberPhotoModerationStatusWidget(
                    context,
                    memberPhoto,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 5.0,
            bottom: 10.0,
            child: FloatingActionButton.small(
              heroTag: null,
              elevation: 3.0,
              shape: const CircleBorder(),
              onPressed: () async {
                _viewProfilePicture(context, memberPhoto.urls.full!);
                profilePictureTapped?.call();
              },
              backgroundColor: Colors.black,
              child: Icon(
                Platform.isIOS
                    ? CupertinoIcons.arrow_up_left_arrow_down_right
                    : Icons.open_in_full_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildMemberPhotoModerationStatusWidget(
      BuildContext context, MemberPhoto memberPhoto) {
    return (member.id == currentUser.id)
        ? GestureDetector(
            onTap: () async {
              await showSuccessDialog(
                  context,
                  title: getMemberPhotoModerationStatusDescription(
                      memberPhoto.status),
                  getMemberPhotoModerationStatusText(memberPhoto.status));
            },
            child: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  color: getMemberPhotoModerationStatusColour(
                    memberPhoto.status,
                    kBaseVerifiedIndicatorColour,
                    kBasePendingVerificationIndicatorColour,
                  ),
                  borderRadius: BorderRadius.circular(8.0)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: setWidthBetweenWidgets(
                  width: 4.0,
                  [
                    Icon(
                      getMemberPhotoModerationStatusIcon(memberPhoto.status),
                      color: Colors.white,
                      size: 16.0,
                    ),
                    Text(
                      getMemberPhotoModerationStatusDescription(
                          memberPhoto.status),
                      style:
                          const TextStyle(fontSize: 12.0, color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildMemberProfileTypeWidget(BuildContext context) {
    final isDemoUser = demoUsersMap[serverUrl]?.contains(member.id) ?? false;
    final isTeamMemberUser =
        teamMemberUsersMap[serverUrl]?.contains(member.id) ?? false;

    if (!isDemoUser && !isTeamMemberUser) return SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        showWidgetInformationDialog(
          context: context,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: setHeightBetweenWidgets(
              height: 16.0,
              header: true,
              [
                Text(
                  isDemoUser
                      ? '${member.name} is a demo user.'
                      : '${member.name} is an Arvo team member.',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 72.0,
                  child: Image(
                    image: AssetImage(
                      logoOcreGradientText,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                Text(
                  isDemoUser
                      ? 'Demo user profiles are provided for sample purposes. You can contact a demo user, but they will not reply.'
                      : 'You can contact Arvo team members if you need help, or have any questions or suggestions.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          buttonText: 'Close',
        );
        verificationTapped?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            color: isDemoUser
                ? kBaseArvoDemoProfileTagBackgroundColour
                : kBaseArvoTeamMemberProfileTagBackgroundColour,
            borderRadius: BorderRadius.circular(8.0)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: setWidthBetweenWidgets(
            width: 4.0,
            [
              const SizedBox(
                height: 16.0,
                child: Image(
                  image: AssetImage(
                    logoOcreGradientText,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              Text(
                isDemoUser ? 'Demo User' : 'Team Member',
                style: TextStyle(
                  fontSize: 12.0,
                  color: isDemoUser
                      ? kBaseArvoDemoProfileTagForegroundColour
                      : kBaseArvoTeamMemberProfileTagForegroundColour,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class ProfileDataField {
  final int id;
  final String name;
  final String value;
  final List<String> values;

  const ProfileDataField({
    required this.id,
    required this.name,
    required this.value,
    required this.values,
  });
}
