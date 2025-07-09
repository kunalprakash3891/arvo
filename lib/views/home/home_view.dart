import 'package:arvo/views/shared/x_profile_concat_location_utilities.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:arvo/constants/localised_assets.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/views/shared/navigate_to_edit_profile_pictures.dart';
import 'package:nifty_three_bp_app_base/enums/member_directory_category.dart';
import 'package:nifty_three_bp_app_base/enums/menu_action.dart';
import 'package:nifty_three_bp_app_base/enums/photo_verification_status_type.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/ads/ad_service.dart';
import 'package:arvo/services/bloc/auth_bloc.dart';
import 'package:arvo/services/bloc/auth_event.dart';
import 'package:arvo/services/caching/member_directory_service.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/post.dart';
import 'package:nifty_three_bp_app_base/api/posts_get_request.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/services/features/subscription_products.dart';
import 'package:arvo/services/features/subscription_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:nifty_three_bp_app_base/views/arguments/member_swipe_args.dart';
import 'package:nifty_three_bp_app_base/views/widgets/member_grid_widget.dart';
import 'package:nifty_three_bp_app_base/views/widgets/posts_grid_widget.dart';
import 'package:app_base/dialogs/logout_dialog.dart';
import 'package:app_base/widgets/animated_counter_widget.dart';
import 'package:app_base/widgets/back_to_top_widget.dart';
import 'package:path/path.dart' show basename;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:uuid/uuid.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final ConnectionService _connectionService;
  late final MemberDirectoryService _memberDirectoryService;
  late final FeatureService _featureService;
  late final SubscriptionService _subscriptionService;
  late final AdService _adService;
  late Member _currentUser;
  final List<Member> _newestMembers = [];
  bool _isLoadingCurrentUser = false;
  bool _isLoadingNewestMembers = false;
  bool _hasNewestMembersLoadingError = false;
  final List<Post> _posts = [];
  bool _isLoadingPosts = false;
  bool _hasPostsLoadingError = false;
  late String _uuid;
  Object? _newestMembersError;
  Object? _postsError;
  late final ScrollController _scrollController;
  late final ValueNotifier<bool> _backToTopButtonVisible;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _currentUser = _connectionService.currentUser!;
    _memberDirectoryService = MemberDirectoryService.arvo();
    _featureService = FeatureService.arvo();
    _subscriptionService = SubscriptionService.arvo();
    _adService = AdService.arvo();
    _uuid = const Uuid().v1();
    _featureService.registerFunctionForUpdate(_uuid, () {
      if (mounted) {
        setState(() {});
      }
    });
    _scrollController = ScrollController();
    _backToTopButtonVisible = ValueNotifier(false);
    _getNewestMembers();
    _getPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _backToTopButtonVisible.dispose();
    _featureService.unregisterFunction(_uuid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      // Back to top botton will show on scroll offset.
      if (mounted) {
        _backToTopButtonVisible.value = _scrollController.offset > 10.0;
      }
    });

    // SafeArea is required when not using an AppBar and should only be used inside the body.
    return ThemedStatusBar(
      child: Scaffold(
        floatingActionButton: buildBackToTopFloatingButtonWidget(
          _backToTopButtonVisible,
          _scrollController,
        ),
        body: SafeArea(
          child: RefreshIndicator(
            // NOTE: The () async {} format below is needed to hide the
            // refresh indicator.
            onRefresh: () async {
              _onRefresh();
            },
            //notificationPredicate: _is ? (_) => true : (_) => false,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildSliverAppBarWidget(),
                /* SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Column(
                        children: setHeightBetweenWidgets(
                          [
                            _buildProfileStatusWidget(),
                            _buildProfilePictureWidget(),
                            _buildNewestMembersWidget(),
                            _buildPerfectMatchQuizWidget(),
                            _buildPostsWidget(),
                          ],
                          height: 8.0,
                        ),
                      ),
                    ],
                  ),
                )*/
                // NOTE: SliverChildBuilderDelegate offers better performance compared
                // to above SliverChildListDelegate.
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Column(
                        children: setHeightBetweenWidgets(
                          [
                            _buildProfileStatusWidget(),
                            _buildVerifyAccountWidget(),
                            _buildProfilePictureWidget(),
                            _buildNewestMembersWidget(),
                            _buildPerfectMatchQuizWidget(),
                            _buildPostsWidget(),
                          ],
                          height: 8.0,
                        ),
                      );
                    },
                    childCount: 1,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBarWidget() {
    return SliverAppBar(
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsetsDirectional.only(
          start: 0.0,
          bottom: 16.0,
        ),
        title: Text(
          '$greeting ${_currentUser.name!}',
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(fontFamily: 'Overpass'),
        ),
        background: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24.0),
              _buildProfileWidget(),
            ],
          ),
        ),
      ),
      pinned: true,
      expandedHeight: 208.0,
      leading: IconButton(
        icon: Image.asset(
          alternateLogo,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed(subscriptionsViewRoute);
        },
      ),
      actions: [
        _buildPopUpMenuWidget(),
      ],
    );
  }

  Widget _buildProfileWidget() {
    return GestureDetector(
      onTap: () async {
        _awaitReturnFromMemberProfileView();
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          CircularPercentIndicator(
            radius: 60.0,
            lineWidth: 5.0,
            backgroundColor: Colors.transparent,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: getProfileCompletionPercentageColour(
                _currentUser.profileCompletionPercentage),
            animation: true,
            animationDuration: 1000,
            percent: _currentUser.profileCompletionPercentage,
            center: Container(
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                    image:
                        CachedNetworkImageProvider(_currentUser.avatar!.full!),
                    fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned(
            left: 72.0,
            bottom: -8.0,
            child: FloatingActionButton.small(
              heroTag: null,
              elevation: 3.0,
              shape: const CircleBorder(),
              backgroundColor: Colors.black,
              onPressed: () async {
                _awaitReturnFromMemberProfileView();
              },
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatusWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      // NOTE: Use IntrinsicHeight to set matching heights for widgets in a row.
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: setWidthBetweenWidgets(
            width: 8.0,
            [
              Expanded(
                child: _buildProfileCompletionWidget(),
              ),
              Expanded(
                child: _buildSubscriptionWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCompletionWidget() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
      ),
      child: Column(
        children: setHeightBetweenWidgets(
          height: 4.0,
          [
            Text(
              'Profile Strength',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50.0),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: getProfileCompletionPercentageColour(
                          _currentUser.profileCompletionPercentage),
                      width: 1.0,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(32.0),
                ),
              ),
              onPressed: () async {
                _awaitReturnFromMemberProfileView();
              },
              child: AnimatedCount(
                count: (_currentUser.profileCompletionPercentage * 100).toInt(),
                curve: Curves.linear,
                duration: const Duration(milliseconds: 1000),
                suffix: '%',
                style: Theme.of(context).textTheme.displaySmall!.copyWith(
                      color: getProfileCompletionPercentageColour(
                          _currentUser.profileCompletionPercentage),
                    ),
              ),
            ),
            _currentUser.profileCompletionPercentage == 1.0
                // NOTE: The following widget is based on if the user has a subscription,
                // this to make sure the profile completion and subscription child widgets are
                // aligned.
                ? _subscriptionService.purchases.isNotEmpty
                    ? const SizedBox.shrink()
                    : Text(
                        'Well done, your profile is complete. Keep it updated.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      )
                : Text(
                    'Improve strength by completing your profile.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionWidget() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildSubscriptionTypeBackgroundImage(),
          _buildSubscriptionInformationWidget(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInformationWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: setHeightBetweenWidgets(
          height: 4.0,
          [
            Text(
              'Membership',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _buildSubscriptionDescriptionWidget(),
            _subscriptionService.purchases.isNotEmpty
                ? _currentUser.profileCompletionPercentage == 1.0
                    // NOTE: The following widget is based on if the user has a subscription,
                    // this to make sure the profile completion and subscription child widgets are
                    // aligned.
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                            color: kBasePremiumBackgroundColour,
                            borderRadius: BorderRadius.circular(8.0)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: setWidthBetweenWidgets(
                            [
                              const SizedBox(
                                height: 16.0,
                                width: 16.0,
                                child: Image(
                                  image: AssetImage(
                                    alternateLogo,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Text(
                                'Premium',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color:
                                            kBasePremiumForegroundTextColour),
                              ),
                            ],
                            width: 8.0,
                          ),
                        ),
                      )
                : Text(
                    localisedTextNotPremium,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTypeBackgroundImage() {
    if (_subscriptionService.hasGold) {
      return Positioned(
        right: -48.0,
        child: Image.asset(
          _subscriptionService.productFeatures!
              .where((productFeature) =>
                  productFeature.productId == kGoldSubscriptionId)
              .first
              .image!,
          height: 96.0,
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation(0.5),
        ),
      );
    } else if (_subscriptionService.hasSilver) {
      return Positioned(
        right: -48.0,
        child: Image.asset(
          _subscriptionService.productFeatures!
              .where((productFeature) =>
                  productFeature.productId == kSilverSubscriptionId)
              .first
              .image!,
          height: 96.0,
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation(0.5),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildSubscriptionDescriptionWidget() {
    if (_subscriptionService.hasGold) {
      return _buildPremiumSubscriptionDescriptionNavigationWidget('Gold');
    } else if (_subscriptionService.hasSilver) {
      return _buildPremiumSubscriptionDescriptionNavigationWidget('Silver');
    } else {
      return FilledButton(
        onPressed: () {
          Navigator.of(context).pushNamed(subscriptionsViewRoute);
        },
        style: FilledButton.styleFrom(
          backgroundColor: kBasePremiumBackgroundColour,
        ),
        child: const Text(
          'Upgrade',
          style: TextStyle(color: kBasePremiumForegroundTextColour),
        ),
      );
    }
  }

  Widget _buildPremiumSubscriptionDescriptionNavigationWidget(String text) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pushNamed(subscriptionsViewRoute);
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50.0),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: kBaseColour,
            width: 1,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(32.0),
        ),
        backgroundColor: Colors.transparent,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }

  Widget _buildPopUpMenuWidget() {
    return PopupMenuButton<MenuAction>(
      onSelected: (value) async {
        switch (value) {
          case MenuAction.logOut:
            final shouldLogOut = await showLogOutDialog(context);
            if (shouldLogOut) {
              if (mounted) {
                context.read<AuthBloc>().add(
                      const AuthEventLogOut(),
                    );
              }
            }
            break;
          case MenuAction.settings:
            if (mounted) {
              _adService.showAd(context);
              await Navigator.of(context).pushNamed(settingsRoute);
            }
            break;
          case MenuAction.faqs:
            if (mounted) {
              _adService.showAd(context);
              await Navigator.of(context).pushNamed(faqsViewRoute);
            }
            break;
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem<MenuAction>(
            value: MenuAction.settings,
            child: Text('Settings'),
          ),
          const PopupMenuItem<MenuAction>(
            value: MenuAction.faqs,
            child: Text('FAQs'),
          ),
          const PopupMenuItem<MenuAction>(
            value: MenuAction.logOut,
            child: Text('Log Out'),
          ),
        ];
      },
    );
  }

  Widget _buildProfilePictureWidget() {
    if (_currentUser.photoVerificationStatus != null &&
        _currentUser.photoVerificationStatus !=
            PhotoVerificationStatusType.approved) {
      return const SizedBox.shrink();
    }

    bool userHasDefaultPhoto =
        basename(_currentUser.avatar!.full!) == basename(defaultAvatarURL);
    return userHasDefaultPhoto
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(
                    selfie,
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5.0,
                    spreadRadius: 1.0,
                    offset: const Offset(1.0, 1.0),
                  )
                ],
              ),
              child: Column(
                children: setHeightBetweenWidgets(
                  [
                    Text(
                      'Profiles with photos get more views.',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    FilledButton(
                      onPressed: () async {
                        // NOTE: When using Navigator calls, use await if
                        // there are is additional code that needs to run before/after
                        // the Navigator operation, otherwise you can leave out the await.
                        await navigateToEditProfilePicturesView(
                            context, _connectionService);
                      },
                      child: const Text(
                        'Upload Photos',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  height: 16.0,
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildVerifyAccountWidget() {
    if (_currentUser.photoVerificationStatus ==
        PhotoVerificationStatusType.approved) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        clipBehavior: Clip.hardEdge,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage(
              friends,
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5.0,
              spreadRadius: 1.0,
              offset: const Offset(1.0, 1.0),
            )
          ],
        ),
        child: Column(
          children: setHeightBetweenWidgets(
            [
              Text(
                "Verified accounts attract more profile views.",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              FilledButton(
                onPressed: () {
                  // NOTE: When using Navigator calls, use await if
                  // there are is additional code that needs to run before/after
                  // the Navigator operation, otherwise you can leave out the await.
                  Navigator.of(context).pushNamed(
                    photoVerificationViewRoute,
                  );
                },
                child: const Text(
                  'Verify My Account',
                  style: TextStyle(
                    //TODO: Remove the following color line for all buttons like this. Default looks better than white!
                    // color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            height: 16.0,
          ),
        ),
      ),
    );
  }

  Widget _buildPerfectMatchQuizWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        clipBehavior: Clip.hardEdge,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage(
              'assets/images/confetti.png',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          ),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5.0,
              spreadRadius: 1.0,
              offset: const Offset(1.0, 1.0),
            )
          ],
        ),
        child: Column(
          children: setHeightBetweenWidgets(
            [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Improve your matches by taking the quiz.',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(
                    height: 72.0,
                    width: 72.0,
                    child: Image(
                      image: AssetImage(
                        'assets/images/question_answer.png',
                      ),
                      fit: BoxFit.contain,
                    ),
                  )
                ],
              ),
              FilledButton(
                onPressed: () async {
                  _awaitReturnFromPerfectMatchQuiz();
                },
                child: const Text(
                  'Perfect Match Quiz',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            height: 16.0,
          ),
        ),
      ),
    );
  }

  Widget _buildNewestMembersWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: setHeightBetweenWidgets(
        [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Text(
              'Newest Members',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          SizedBox(
            height: 288.0,
            child: Stack(
              children: [
                MasonryGridView.count(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  crossAxisSpacing: 8.0,
                  crossAxisCount: 1,
                  mainAxisSpacing: 8.0,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _newestMembers.length,
                  itemBuilder: (context, index) {
                    if (index == _newestMembers.length) {
                      if (_hasNewestMembersLoadingError) {
                        return Center(
                          child: _errorNotificationWidget(
                            error: _newestMembersError,
                            size: 16.0,
                            retryFunction: _getNewestMembers,
                          ),
                        );
                      } else {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    }
                    return buildMemberGridWidget(
                      context: context,
                      memberSwipeArgs: MemberSwipeArgs(
                        _newestMembers[index],
                        MemberDirectoryCategory.newest,
                      ),
                      member: _newestMembers[index],
                      lastItem: false,
                      width: 160.0,
                      showStatus: _featureService.featureMemberOnlineIndicator,
                      onlineColour: kBaseOnlineColour,
                      recentlyOnlineColour: kBaseRecentlyOnlineColour,
                      viewProfileRoute: viewProfileRoute,
                      memberSwipeViewRoute: memberSwipeViewRoute,
                      matchWeightColour: getMatchPercentageColour(
                        _newestMembers[index].matchWeight,
                        _featureService.featureMatchInsight,
                      ),
                      verifiedMemberIndicatorColour:
                          kBaseVerifiedIndicatorColour,
                      locationTextDisplayFormatter:
                          shortLocationDisplayFormatter,
                    );
                  },
                ),
                _isLoadingNewestMembers
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _newestMembers.isEmpty
                        ? Center(
                            child: _noResultsWidget(
                              text: 'No new members to show...yet.',
                              size: 16.0,
                              retryFunction: _getNewestMembers,
                            ),
                          )
                        : const SizedBox.shrink()
              ],
            ),
          ),
        ],
        height: 8.0,
      ),
    );
  }

  Future<void> _getCurrentUser() async {
    if (_isLoadingCurrentUser) return;

    _isLoadingCurrentUser = true;
    await _connectionService.refreshCurrentUser();
    if (mounted) {
      setState(() {
        _isLoadingCurrentUser = false;
        _currentUser = _connectionService.currentUser!;
      });
    }
  }

  Future<void> _getNewestMembers() async {
    if (_isLoadingNewestMembers) return;

    try {
      _newestMembers.clear();
      _memberDirectoryService.clearNewestMembersDirectory();
      if (mounted) {
        setState(() {
          _isLoadingNewestMembers = true;
          _hasNewestMembersLoadingError = false;
          _newestMembersError = null;
        });
      }
      var newestMembers = await _memberDirectoryService.getNewestMembers(1);
      if (mounted) {
        setState(
          () {
            _isLoadingNewestMembers = false;
            _newestMembers.addAll(newestMembers);
          },
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(
          () {
            _isLoadingNewestMembers = false;
            _hasNewestMembersLoadingError = true;
            _newestMembersError = e;
          },
        );
      }
    }
  }

  Widget _buildPostsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: setHeightBetweenWidgets(
        [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Text(
              'News',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          SizedBox(
            height: 296.0,
            child: Stack(
              children: [
                MasonryGridView.count(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  crossAxisSpacing: 8.0,
                  crossAxisCount: 1,
                  mainAxisSpacing: 8.0,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    if (index == _posts.length) {
                      if (_hasPostsLoadingError) {
                        return Center(
                          child: _errorNotificationWidget(
                            error: _postsError,
                            size: 16.0,
                            retryFunction: _getPosts,
                          ),
                        );
                      } else {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    }
                    return buildPostsGridWidget(
                      context: context,
                      viewPostRoute: viewPostRoute,
                      post: _posts[index],
                      lastItem: false,
                      placeholderLogo: logo,
                      height: 272.0,
                      width: 272.0,
                    );
                  },
                ),
                _isLoadingPosts
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _posts.isEmpty
                        ? Center(
                            child: _noResultsWidget(
                              text: 'No news to show.',
                              size: 16.0,
                              retryFunction: _getPosts,
                            ),
                          )
                        : const SizedBox.shrink()
              ],
            ),
          ),
        ],
        height: 8.0,
      ),
    );
  }

  Future<void> _getPosts() async {
    if (_isLoadingPosts) return;

    try {
      _posts.clear();
      if (mounted) {
        setState(() {
          _isLoadingPosts = true;
          _hasPostsLoadingError = false;
          _postsError = null;
        });
      }
      var postsGetRequest = const PostsGetRequest(page: 1, perPage: 10);
      var results = await ConnectionService.arvo().getPosts(postsGetRequest);
      for (final result in results) {
        try {
          var featuredMediaURL =
              await ConnectionService.arvo().getPostMedia(result.featuredMedia);
          result.featuredMediaURL = featuredMediaURL.guid.rendered;
        } on Exception catch (_) {
          result.featuredMediaURL = null;
        }
      }
      if (mounted) {
        setState(
          () {
            _isLoadingPosts = false;
            _posts.addAll(results);
          },
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(
          () {
            _isLoadingPosts = false;
            _hasPostsLoadingError = true;
            _postsError = e;
          },
        );
      }
    }
  }

  Widget _noResultsWidget({
    required String text,
    required double size,
    required void Function() retryFunction,
  }) {
    return SizedBox(
      height: 180.0,
      width: 200.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: setHeightBetweenWidgets(
            [
              Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              OutlinedButton(
                onPressed: retryFunction,
                child: const Text(
                  'Refresh',
                ),
              ),
            ],
            height: 16.0,
          ),
        ),
      ),
    );
  }

  Widget _errorNotificationWidget({
    Object? error,
    required double size,
    required void Function() retryFunction,
  }) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: setHeightBetweenWidgets(
          [
            Text(
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
              onPressed: retryFunction,
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

  Future<void> _onRefresh() async {
    try {
      // NOTE: No need to await here because each function
      // has it's own flag to check if it is executing.
      _getCurrentUser(); // Don't await.
      _getNewestMembers(); // Don't await.
      _getPosts(); // Don't await.
    } on Exception catch (e) {
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  void _awaitReturnFromMemberProfileView() async {
    // Navigate to view and wait for it to return.
    await Navigator.of(context).pushNamed(
      viewProfileRoute,
      arguments: _currentUser,
    );
    // Update this page on return.
    // Assign to _currentUser.
    if (mounted) {
      setState(
        () {
          _currentUser = _connectionService.currentUser!;
        },
      );
    }
  }

  void _awaitReturnFromPerfectMatchQuiz() async {
    // Navigate to view with a function argument which will be executed
    // on pop.
    await Navigator.of(context).pushNamed(perfectMatchQuizStartRoute,
        arguments: () async {
      if (mounted) {
        setState(
          () {
            _currentUser = _connectionService.currentUser!;
          },
        );
      }
      await _getNewestMembers();
    });
  }
}
