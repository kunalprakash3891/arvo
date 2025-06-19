import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/routes.dart';
import 'package:nifty_three_bp_app_base/enums/member_directory_category.dart';
import 'package:arvo/enums/tip_type.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/caching/member_directory_service.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/services/tips/tip_service.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/shared/members_grid_view.dart';
import 'package:uuid/uuid.dart';

typedef MemberCallback = void Function(Member member);

class MemberSearchView extends StatefulWidget {
  const MemberSearchView({super.key});

  @override
  State<MemberSearchView> createState() => _MemberSearchViewState();
}

class _MemberSearchViewState extends State<MemberSearchView> {
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
    _memberDirectoryService.updateMembers = (members) {
      if (mounted) {
        setState(() {
          _updateMembers(updatedMembers: members);
        });
      }
    };
    _memberDirectoryService.clearMembersDirectory();
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
    // addPostFrameCallback runs after the page has been built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Show tip.
      TipService.arvo().showTipOverlay(context, TipType.tipFiltersApplied);
    });
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

    return ThemedStatusBar(
      child: Scaffold(
        floatingActionButton: _buildFloatingButtonsWidget(),
        body: SafeArea(
          child: MembersGridView(
            members: _members,
            swipeCategory: MemberDirectoryCategory.members,
            onRefresh: _onRefresh,
            getMembers: _getMembers,
            editFilters: () {
              Navigator.of(context)
                  .pushNamed(memberFiltersViewRoute, arguments: _onRefresh);
            },
            isLastPage: _memberDirectoryService.isMembersLastPage,
            isLoading: _isLoading,
            hasError: _hasError,
            error: _error,
            scrollController: _scrollController,
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
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    _memberDirectoryService.clearMembersDirectory();
    _members.clear();
    _backToTopButtonVisible.value = false;
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
      var members = await _memberDirectoryService.getMembers(_currentPage);
      if (mounted) {
        setState(
          () {
            _isLastPage =
                members.length < _memberDirectoryService.membersPerPage;
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
  }

  Widget _buildFloatingButtonsWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: setHeightBetweenWidgets(
        [
          ValueListenableBuilder(
            valueListenable: _backToTopButtonVisible,
            builder: (context, value, child) {
              if (!value) {
                return const SizedBox.shrink();
              } else {
                return FloatingActionButton.small(
                  heroTag: null,
                  shape: const CircleBorder(),
                  onPressed: () {
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.fastOutSlowIn,
                    );
                  },
                  child: Icon(
                    Platform.isIOS
                        ? CupertinoIcons.arrow_up
                        : Icons.arrow_upward_rounded,
                    size: 24.0,
                  ),
                );
              }
            },
          ),
          Stack(
            children: [
              FloatingActionButton(
                heroTag: null,
                shape: const CircleBorder(),
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(memberFiltersViewRoute, arguments: _onRefresh);
                },
                child: Icon(
                  Platform.isIOS
                      ? CupertinoIcons.slider_horizontal_3
                      : Icons.tune_rounded,
                  size: 32.0,
                ),
              ),
              _memberDirectoryService.activeMemberFiltersCount == 0
                  ? const SizedBox.shrink()
                  : Positioned(
                      right: 0.0,
                      bottom: 0.0,
                      child: Container(
                        padding: const EdgeInsets.all(1.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16.0,
                          minHeight: 16.0,
                        ),
                        child: Text(
                          '${_memberDirectoryService.activeMemberFiltersCount}',
                          style: TextStyle(
                            // .onSecondary indicates a colour that is visible against
                            // the .secondary colour.
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 10.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ],
          ),
        ],
        height: 8.0,
      ),
    );
  }
}
