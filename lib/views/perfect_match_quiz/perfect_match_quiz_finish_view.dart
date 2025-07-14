import 'dart:io';

import 'package:arvo/views/shared/avatar_placeholder.dart';
import 'package:arvo/views/shared/x_profile_concat_location_utilities.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/services/caching/member_directory_service.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:arvo/views/animation/fade_animation.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:nifty_three_bp_app_base/views/widgets/member_grid_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:app_base/generics/get_arguments.dart';

class PerfectMatchQuizFinishView extends StatefulWidget {
  const PerfectMatchQuizFinishView({super.key});

  @override
  State<PerfectMatchQuizFinishView> createState() =>
      _PerfectMatchQuizFinishViewState();
}

class _PerfectMatchQuizFinishViewState
    extends State<PerfectMatchQuizFinishView> {
  late final ConnectionService _connectionService;
  late final MemberDirectoryService _memberDirectoryService;
  late final FeatureService _featureService;
  late final ValueNotifier<bool> _topMatchesLoaded;
  List<Member>? _topMatches;
  Function? _quizEndedCallback;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _memberDirectoryService = MemberDirectoryService.arvo();
    _featureService = FeatureService.arvo();
    _topMatchesLoaded = ValueNotifier(false);
  }

  @override
  void dispose() {
    _topMatchesLoaded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optional function that will be executed when quiz ends.
    _quizEndedCallback = _quizEndedCallback ?? context.getArgument<Function>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop();
        _quizEndedCallback?.call();
      },
      child: Scaffold(
        backgroundColor: kBaseCoastalTeal,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
                _quizEndedCallback?.call();
              }
            },
            icon: Icon(Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back),
          ),
        ),
        body: FutureBuilder(
          // Note: CircularProgressIndicator is not needed here because
          // top match results are updated by a value notifier.
          future: _getTopMatches(),
          builder: (context, snapshot) {
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 32.0,
                    right: 32.0,
                    bottom: 32.0,
                  ),
                  child: FadeAnimation(
                    1.0,
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: setHeightBetweenWidgets(
                          [
                            SizedBox(
                              height: 120.0,
                              child: Lottie.asset(
                                'assets/animations/done_animation.json',
                                repeat: false,
                              ),
                            ),
                            Text(
                              localisedPraise,
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const Text(
                              "Your profile has been updated with your answers. You can look forward to improved percentage match ratings.",
                              textAlign: TextAlign.center,
                            ),
                            _buildFinishWidget(),
                          ],
                          height: 16.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFinishWidget() {
    return ValueListenableBuilder(
      valueListenable: _topMatchesLoaded,
      builder: (context, value, child) {
        if (!value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return Column(
            children: [
              _topMatches == null || _topMatches!.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Text(
                          'Members you might like',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        _buildTopMatchesCarousel(),
                      ],
                    ),
              ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).pop();
                    _quizEndedCallback?.call();
                  }
                },
                child: const Text(
                  'Finish',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildTopMatchesCarousel() {
    return CarouselSlider(
      items: _topMatches!
          .map(
            (item) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: buildMemberGridWidget(
                context: context,
                member: item,
                lastItem: false,
                width: 128.0,
                backgroundColour:
                    Theme.of(context).colorScheme.secondaryContainer,
                showStatus: _featureService.featureMemberOnlineIndicator,
                onlineColour: kBaseOnlineColour,
                recentlyOnlineColour: kBaseRecentlyOnlineColour,
                viewProfileRoute: viewProfileRoute,
                memberSwipeViewRoute: memberSwipeViewRoute,
                matchWeightColour: getMatchPercentageColour(
                  item.matchWeight,
                  _featureService.featureMatchInsight,
                ),
                verifiedMemberIndicatorColour: kBaseVerifiedIndicatorColour,
                locationTextDisplayFormatter: shortLocationDisplayFormatter,
                avatarAsText: memberHasDefaultAvatar(item.avatar?.full),
                avatarAsTextTextColour: getMatchPercentageColour(
                  item.matchWeight,
                  _featureService.featureMatchInsight,
                ),
                avatarAsTextImageProvider:
                    getAvatarPlaceholderImage(item.name!),
              ),
            ),
          )
          .toList(),
      options: CarouselOptions(
        enlargeCenterPage: true,
        enlargeStrategy: CenterPageEnlargeStrategy.zoom,
        viewportFraction: 0.5,
        height: 288.0,
      ),
    );
  }

  Future<void> _getTopMatches() async {
    if (_topMatchesLoaded.value) {
      return;
    }
    try {
      // Refresh the current user.
      await _connectionService.refreshCurrentUser();
      // Load top matches.
      _topMatches = await _memberDirectoryService.getRandomTopMatchedMembers(5);
    } on Exception catch (_) {
      _topMatches = null;
    }
    if (mounted) _topMatchesLoaded.value = true;
  }
}
