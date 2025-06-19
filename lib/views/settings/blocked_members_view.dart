import 'package:flutter/material.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/member_blocked.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/views/shared/members_grid_view.dart';
import 'package:app_base/widgets/back_to_top_widget.dart';
import 'package:uuid/uuid.dart';

class BlockedMembersView extends StatefulWidget {
  const BlockedMembersView({super.key});

  @override
  State<BlockedMembersView> createState() => _BlockedMembersViewState();
}

class _BlockedMembersViewState extends State<BlockedMembersView> {
  late final ConnectionService _connectionService;
  late final FeatureService _featureService;
  late final List<Member> _blockedMembers;
  final int _membersPerPage = 25;
  int _currentPage = 1;
  bool _isLastPage = false;
  late bool _isLoading;
  late bool _hasError;
  Object? _error;
  late final ScrollController _scrollController;
  late final ValueNotifier<bool> _backToTopButtonVisible;
  late String _uuid;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _featureService = FeatureService.arvo();
    _uuid = const Uuid().v1();
    _featureService.registerFunctionForUpdate(_uuid, () {
      if (mounted) {
        setState(() {});
      }
    });
    _blockedMembers = [];
    _scrollController = ScrollController();
    _backToTopButtonVisible = ValueNotifier(false);
    _getBlockedMembers();
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
        _getBlockedMembers();
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
      appBar: AppBar(
        title: const Text('Manage Blocked Members'),
      ),
      body: MembersGridView(
        members: _blockedMembers,
        onRefresh: _onRefresh,
        getMembers: _getBlockedMembers,
        isLoading: _isLoading,
        isLastPage: _isLastPage,
        hasError: _hasError,
        error: _error,
        scrollController: _scrollController,
        emptyResultsText: "You haven't blocked anyone yet.",
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
    _blockedMembers.clear();
    _currentPage = 1;
    await _getBlockedMembers();
  }

  Future<void> _getBlockedMembers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
          _error = null;
        });
      }
      List<Member> blockedMembers = [];
      int addedResultCount = 0;
      final blockedMembersGetRequest = BlockedMembersGetRequest(
          page: _currentPage, perPage: _membersPerPage);
      var results =
          await _connectionService.getBlockedMembers(blockedMembersGetRequest);
      for (final result in results) {
        try {
          var blockedMember =
              await _connectionService.getMember(result.blockedUserId);
          blockedMember.isBlocked = true;
          blockedMembers.add(blockedMember);
        } on Exception catch (_) {
          // Couldn't retrieve the member, carry onto the next.
        }
        addedResultCount++;
      }
      if (mounted) {
        setState(
          () {
            _isLastPage = addedResultCount < _membersPerPage;
            _isLoading = false;
            _currentPage++;
            _blockedMembers.addAll(blockedMembers);
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

  void _updateMembers() {
    for (int i = _blockedMembers.length - 1; i >= 0; i--) {
      final member = _blockedMembers[i];

      if (member.isBlocked != null && !member.isBlocked!) {
        _blockedMembers.removeAt(i);
      }

      if (member.isSuspended != null && member.isSuspended!) {
        _blockedMembers.removeAt(i);
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
