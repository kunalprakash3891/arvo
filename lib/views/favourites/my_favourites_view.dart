import 'package:flutter/material.dart';
import 'package:nifty_three_bp_app_base/enums/member_directory_category.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/caching/member_directory_service.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/views/shared/members_grid_view.dart';
import 'package:app_base/widgets/back_to_top_widget.dart';
import 'package:uuid/uuid.dart';

class MyFavouritesView extends StatefulWidget {
  const MyFavouritesView({super.key});

  @override
  State<MyFavouritesView> createState() => _MyFavouritesViewState();
}

class _MyFavouritesViewState extends State<MyFavouritesView> {
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
    _memberDirectoryService.updateMyFavourites = (members) {
      if (mounted) {
        setState(() {
          _updateMembers(updatedMembers: members);
        });
      }
    };
    _memberDirectoryService.clearFavouriteMembersDirectory();
    _featureService = FeatureService.arvo();
    _uuid = const Uuid().v1();
    _featureService.registerFunctionForUpdate(_uuid, () {
      if (mounted) {
        setState(() {});
      }
    });
    _members = [];
    _scrollController = ScrollController();
    _backToTopButtonVisible = ValueNotifier(false);
    _getMembers();
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
      body: MembersGridView(
        members: _members,
        swipeCategory: MemberDirectoryCategory.myFavourites,
        onRefresh: _onRefresh,
        getMembers: _getMembers,
        isLoading: _isLoading,
        isLastPage: _isLastPage,
        hasError: _hasError,
        error: _error,
        scrollController: _scrollController,
        emptyResultsText: "You haven't added any favourites yet.",
        onMemberProfileReturn: () {
          if (mounted) {
            setState(() {
              _updateMembers();
            });
          }
        },
        showStatus: _featureService.featureMemberOnlineIndicator,
        showColourCodedMatchPercentage: _featureService.featureMatchInsight,
      ),
    );
  }

  Future<void> _onRefresh() async {
    _memberDirectoryService.clearFavouriteMembersDirectory();
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
          await _memberDirectoryService.getFavouriteMembers(_currentPage);
      if (mounted) {
        setState(
          () {
            _isLastPage = members.length <
                _memberDirectoryService.favouriteMembersPerPage;
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
          if (member.isFavourite != null && !member.isFavourite!) {
            _members.remove(member);
            continue;
          }

          if (updatedMember.isBlocked != null && updatedMember.isBlocked!) {
            _members.remove(member);
          }

          if (updatedMember.isSuspended != null && updatedMember.isSuspended!) {
            _members.remove(member);
          }
        } else {
          _members.add(updatedMember);
        }
      }
    } else {
      for (int i = _members.length - 1; i >= 0; i--) {
        final member = _members[i];
        if (member.isFavourite != null && !member.isFavourite!) {
          _members.removeAt(i);
          continue;
        }

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
