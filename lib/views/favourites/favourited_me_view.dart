import 'package:arvo/theme/palette.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/constants/routes.dart';
import 'package:nifty_three_bp_app_base/enums/member_directory_category.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/caching/member_directory_service.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/shared/members_grid_view.dart';
import 'package:app_base/widgets/back_to_top_widget.dart';
import 'package:uuid/uuid.dart';

class FavouritedMeView extends StatefulWidget {
  const FavouritedMeView({super.key});

  @override
  State<FavouritedMeView> createState() => _FavouritedMeViewState();
}

class _FavouritedMeViewState extends State<FavouritedMeView> {
  late final MemberDirectoryService _memberDirectoryService;
  late final FeatureService _featureService;
  late final List<Member> _members;
  bool _isLastPage = false;
  int _currentPage = 1;
  late bool _isLoading;
  late bool _hasError;
  Object? _error;
  late final ScrollController _scrollController;
  late final ValueNotifier<bool> _backToTopButtonVisible;
  late String _uuid;

  @override
  void initState() {
    super.initState();
    _memberDirectoryService = MemberDirectoryService.arvo();
    _memberDirectoryService.clearFavouritedByMembersDirectory();
    _memberDirectoryService.updateFavouritedMe = (members) {
      if (mounted) {
        setState(() {
          _updateMembers(updatedMembers: members);
        });
      }
    };
    _featureService = FeatureService.arvo();
    _uuid = const Uuid().v1();
    _featureService.registerFunctionForUpdate(_uuid, () {
      // NOTE: Execute only if feature is available, otherwise setState.
      // /favouritedby endpoint is used to determine Premium users.
      if (_featureService.featureFavouritedMe) {
        _getMembers();
      } else {
        if (mounted) {
          setState(() {});
        }
      }
    });
    _members = [];
    _scrollController = ScrollController();
    _backToTopButtonVisible = ValueNotifier(false);
    // Execute only if feature is available.
    if (_featureService.featureFavouritedMe) _getMembers();
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
      //Back to top botton will show on scroll offset.
      if (mounted) {
        _backToTopButtonVisible.value = _scrollController.offset > 10.0;
      }

      if (_isLoading || _isLastPage) return;
      // nextPageTrigger will have a value equivalent to 80% of the list size.
      var nextPageTrigger = 0.8 * _scrollController.position.maxScrollExtent;

      // _scrollController fetches the next paginated data when the current postion of the user on the screen has surpassed
      if (_scrollController.position.pixels > nextPageTrigger) {
        _getMembers();
      }
    });

    return Scaffold(
      floatingActionButton: buildBackToTopFloatingButtonWidget(
        _backToTopButtonVisible,
        _scrollController,
        scrollToTopCompletedCallback: () {
          // Set back to top button visibility in case items size has changed.
          if (mounted) {
            if (_scrollController.hasClients) {
              _backToTopButtonVisible.value = _scrollController.offset > 10.0;
            }
          }
        },
      ),
      body: _featureService.featureFavouritedMe
          ? _buildMembersGridViewWidget()
          : _buildSubscriptionRequiredPlaceHolder(),
    );
  }

  Widget _buildMembersGridViewWidget() {
    return MembersGridView(
      members: _members,
      swipeCategory: MemberDirectoryCategory.favouritedMe,
      onRefresh: _onRefresh,
      getMembers: _getMembers,
      isLoading: _isLoading,
      isLastPage: _isLastPage,
      hasError: _hasError,
      error: _error,
      scrollController: _scrollController,
      emptyResultsText:
          "You haven't been added as a favourite yet. Don't despair, your match is out there!",
      onMemberProfileReturn: () {
        if (mounted) {
          setState(() {
            _updateMembers();
          });
        }
      },
      showStatus: _featureService.featureMemberOnlineIndicator,
      showColourCodedMatchPercentage: _featureService.featureMatchInsight,
    );
  }

  Widget _buildSubscriptionRequiredPlaceHolder() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: setHeightBetweenWidgets(
              [
                const Text(
                  "Connect quicker.",
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  localisedFavouritedMeUpgradePromotionText,
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(subscriptionsViewRoute);
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: kBasePremiumBackgroundColour),
                  child: const Text(
                    'Get Premium',
                    style: TextStyle(
                      color: kBasePremiumForegroundTextColour,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              height: 32.0,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    _memberDirectoryService.clearFavouritedByMembersDirectory();
    _members.clear();
    _currentPage = 1;
    await _getMembers();
  }

  Future<void> _getMembers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
          _error = null;
        });
      }
      var members =
          await _memberDirectoryService.getFavouritedByMembers(_currentPage);
      if (mounted) {
        setState(
          () {
            _isLastPage = members.length <
                _memberDirectoryService.favouritedByMembersPerPage;
            _isLoading = false;
            _currentPage++;
            _members.addAll(members);
          },
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(
          () {
            _isLoading = false;
            _hasError = true;
            _error = e;
          },
        );
      }
      // Process GenericUserAccessException in case a forced log out is required.
      if (_error is GenericUserAccessException && mounted) {
        await processException(
            context: context, exception: _error as GenericUserAccessException);
      }
    }
  }

  // Update members using a list, if list is not provided then update all members.
  void _updateMembers({List<Member>? updatedMembers}) {
    if (updatedMembers != null) {
      for (final updatedMember in updatedMembers) {
        final member = _members
            .where((existingMember) => existingMember.id == updatedMember.id)
            .firstOrNull;

        if (member != null) {
          if (updatedMember.isBlocked != null && updatedMember.isBlocked!) {
            _members.remove(member);
          }

          if (updatedMember.isSuspended != null && updatedMember.isSuspended!) {
            _members.remove(member);
          }

          if (updatedMember.isFavourite != null) {
            member.isFavourite = updatedMember.isFavourite;
          }
        }
      }
    } else {
      for (int i = _members.length - 1; i >= 0; i--) {
        final member = _members[i];

        if (member.isBlocked != null && member.isBlocked!) {
          _members.removeAt(i);
        }

        if (member.isSuspended != null && member.isSuspended!) {
          _members.removeAt(i);
        }
      }
    }
    // Set back to top button visibility in case items size has changed.
    if (mounted) {
      if (_scrollController.hasClients) {
        _backToTopButtonVisible.value = _scrollController.offset > 10.0;
      }
    }
  }
}
