import 'dart:io';

import 'package:arvo/views/shared/avatar_placeholder.dart';
import 'package:arvo/views/shared/x_profile_concat_location_utilities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/views/animation/fade_animation.dart';
import 'package:nifty_three_bp_app_base/enums/member_directory_category.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:nifty_three_bp_app_base/views/arguments/member_swipe_args.dart';
import 'package:nifty_three_bp_app_base/views/widgets/member_grid_widget.dart';
import 'package:lottie/lottie.dart';

typedef RefreshMembersCallback = Future<void> Function();
typedef GetMembersCallback = void Function();
typedef FiltersCallback = void Function();

double errorWidgetHeight = 296.0;

class MembersGridView extends StatelessWidget {
  final Iterable<Member> members;
  final MemberDirectoryCategory? swipeCategory;
  final RefreshMembersCallback onRefresh;
  final GetMembersCallback getMembers;
  final FiltersCallback? editFilters;
  final MemberProfileCallback? onMemberProfileReturn;
  final bool isLoading;
  final bool isLastPage;
  final bool hasError;
  final ScrollController? scrollController;
  final String? emptyResultsText;
  final bool showStatus;
  final bool showColourCodedMatchPercentage;
  final Object? error;
  const MembersGridView({
    super.key,
    required this.members,
    this.swipeCategory,
    required this.onRefresh,
    required this.getMembers,
    required this.isLoading,
    required this.isLastPage,
    required this.hasError,
    this.scrollController,
    this.editFilters,
    this.emptyResultsText,
    this.onMemberProfileReturn,
    required this.showStatus,
    required this.showColourCodedMatchPercentage,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    if (members.isEmpty) {
      if (hasError) {
        return Center(
          child: _errorNotificationWidget(error: error, size: 24.0),
        );
      }
      if (!isLoading) {
        return SingleChildScrollView(
          child: FadeAnimation(
            0.8,
            Column(
              children: [
                SizedBox(
                  width: mediaSize.width,
                  child: Lottie.asset(
                      'assets/animations/trimmed_starfish_animation.json',
                      fit: BoxFit.fill),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: setHeightBetweenWidgets(
                      [
                        Text(
                          emptyResultsText ?? noResults,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        editFilters != null
                            ? FilledButton(
                                onPressed: editFilters,
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: setWidthBetweenWidgets(
                                    [
                                      Icon(
                                        Platform.isIOS
                                            ? CupertinoIcons.slider_horizontal_3
                                            : Icons.tune_rounded,
                                        color: Colors.white,
                                      ),
                                      const Text(
                                        'Filters',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    width: 8.0,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        OutlinedButton(
                          onPressed: onRefresh,
                          child: const Text(
                            'Refresh',
                          ),
                        ),
                      ],
                      height: 16.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: MasonryGridView.count(
            controller: scrollController,
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisSpacing: 8.0,
            crossAxisCount: 2,
            mainAxisSpacing: 8.0,
            padding: const EdgeInsets.all(8.0),
            itemCount: members.length + (isLastPage ? 0 : 1),
            itemBuilder: (context, index) {
              if (index == members.length) {
                if (hasError) {
                  return Center(
                    child: _errorNotificationWidget(error: error, size: 16.0),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }
              return buildMemberGridWidget(
                context: context,
                memberSwipeArgs: swipeCategory == null
                    ? null
                    : MemberSwipeArgs(
                        members.elementAt(index),
                        swipeCategory!,
                      ),
                member: members.elementAt(index),
                lastItem: index == members.length - 1 ? true : false,
                onMemberProfileReturn: onMemberProfileReturn,
                showStatus: showStatus,
                onlineColour: kBaseOnlineColour,
                recentlyOnlineColour: kBaseRecentlyOnlineColour,
                viewProfileRoute: viewProfileRoute,
                memberSwipeViewRoute: memberSwipeViewRoute,
                matchWeightColour: getMatchPercentageColour(
                  members.elementAt(index).matchWeight,
                  showColourCodedMatchPercentage,
                ),
                verifiedMemberIndicatorColour: kBaseVerifiedIndicatorColour,
                locationTextDisplayFormatter: shortLocationDisplayFormatter,
                avatarAsText: memberHasDefaultAvatar(
                    members.elementAt(index).avatar?.full),
                avatarAsTextTextColour: getMatchPercentageColour(
                    members.elementAt(index).matchWeight,
                    showColourCodedMatchPercentage),
                avatarAsTextImageProvider:
                    getAvatarPlaceholderImage(members.elementAt(index).name!),
              );
            },
          ),
        ),
        isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : const SizedBox.shrink()
      ],
    );
  }

  Widget _errorNotificationWidget({Object? error, required double size}) {
    return SizedBox(
      height: errorWidgetHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: setHeightBetweenWidgets(
          [
            Text(
              processExceptionTitle(error) ??
                  'An error occurred while fetching results.',
              style: TextStyle(fontSize: size, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            error == null
                ? const SizedBox.shrink()
                : Text(
                    processExceptionMessage(error),
                    textAlign: TextAlign.center,
                  ),
            TextButton(
              onPressed: () async {
                getMembers();
              },
              child: const Text(
                "Retry",
                style: TextStyle(fontSize: 24.0, color: kBaseColour),
              ),
            ),
          ],
          height: 8.0,
        ),
      ),
    );
  }
}
