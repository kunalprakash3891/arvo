import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/services/features/feature_provider.dart';
import 'package:nifty_three_bp_app_base/enums/member_directory_category.dart';
import 'package:arvo/services/caching/member_directory_provider.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/member_favourite.dart';
import 'package:arvo/services/connection/member_filters.dart';
import 'package:nifty_three_bp_app_base/api/members_get_request.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_options_item.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class ArvoMemberDirectoryProvider implements MemberDirectoryProvider {
  final int _membersPerPage = 25;
  final int _favouriteMembersPerPage = 25;
  final int _favouritedByMembersPerPage = 25;
  final int _newestMembersPerPage = 25;
  final int _maximumNewFavouritesPerInterval = 15;

  int _currentMembersPage = 1;
  bool _isLastMembersPage = false;

  final Map<int, List<Member>> _membersDirectory = {};
  MemberFilters _memberFilters = MemberFilters();

  bool _isFavouriteMembersLastPage = false;
  final Map<int, List<Member>> _favouriteMembersDirectory = {};

  bool _isFavouritedByMembersLastPage = false;
  final Map<int, List<Member>> _favouritedByMembersDirectory = {};

  final Map<int, List<Member>> _newestMembersDirectory = {};

  // create as singleton
  static final _shared = ArvoMemberDirectoryProvider._sharedInstance();
  ArvoMemberDirectoryProvider._sharedInstance();
  factory ArvoMemberDirectoryProvider() => _shared;

  late ConnectionProvider _connectionProvider;
  late LocalStorageProvider _localStorageProvider;
  late FeatureProvider _featureProvider;
  late DatabaseSystemSetting _databaseSystemSetting;
  // Needs to be assigned outside initialise() because a user has to be logged in.
  late Member? _currentUser;

  Member _getCurrentUserOrThrow() {
    if (_currentUser != null) {
      return _currentUser!;
    } else {
      throw GenericUserAccessException(message: 'Invalid user.');
    }
  }

  @override
  Future<void> initalise(
      ConnectionProvider connectionProvider,
      LocalStorageProvider localStorageProvider,
      FeatureProvider featureProvider) async {
    _connectionProvider = connectionProvider;
    _localStorageProvider = localStorageProvider;
    _featureProvider = featureProvider;
    _featureProvider.registerFunctionForUpdate(
        const Uuid().v1(), loadSystemParameters);
  }

  @override
  Future<void> loadSystemParameters() async {
    _databaseSystemSetting = await _localStorageProvider.getSystemSetting();
    _currentUser = _connectionProvider.currentUser;

    _getCurrentUserOrThrow();

    populateMemberSearchFilters(_memberFilters,
        databaseUserSetting:
            await _localStorageProvider.getUserSetting(_currentUser!.id));
  }

  @override
  void populateMemberSearchFilters(MemberFilters memberFilters,
      {DatabaseUserSetting? databaseUserSetting}) {
    _getCurrentUserOrThrow();

    _loadMultiSelectionField(
      memberFilters.connectionTypes,
      savedFilterItem: databaseUserSetting != null
          ? parseSavedFilterItem(
              databaseUserSetting.memberSearchConnectionTypes)
          : null,
    );
    _loadMultiSelectionField(
      memberFilters.genders,
      savedFilterItem: databaseUserSetting != null
          ? parseSavedFilterItem(databaseUserSetting.memberSearchGenders)
          : null,
    );
    _loadMultiSelectionField(
      memberFilters.sexualOrientations,
      savedFilterItem: databaseUserSetting != null
          ? parseSavedFilterItem(
              databaseUserSetting.memberSearchSexualOrientations)
          : null,
    );
    _loadMultiSelectionField(
      memberFilters.locations,
      savedFilterItem: databaseUserSetting != null
          ? parseSavedFilterItem(databaseUserSetting.memberSearchLocations)
          : null,
    );
    _loadMultiSelectionField(
      memberFilters.passions,
      savedFilterItem: databaseUserSetting != null
          ? parseSavedFilterItem(databaseUserSetting.memberSearchPassions)
          : null,
    );
    _loadMultiSelectionField(
      memberFilters.ethnicities,
      savedFilterItem: databaseUserSetting != null
          ? parseSavedFilterItem(databaseUserSetting.memberSearchEthnicities)
          : null,
    );

    memberFilters.ageRange.selectedRange = databaseUserSetting != null
        ? RangeValues(
            databaseUserSetting.memberSearchAgeFrom.toDouble(),
            databaseUserSetting.memberSearchAgeTo.toDouble(),
          )
        : const RangeValues(minimumSearchAge, maximumSearchAge);

    memberFilters.selectedProfilePhotoType = databaseUserSetting != null
        ? memberFilters.profilePhotoTypes.selectionItems
                .where((selectionItem) =>
                    selectionItem.value ==
                    databaseUserSetting.memberSearchPhotoType)
                .firstOrNull ??
            memberFilters.profilePhotoTypes.selectionItems.first
        : memberFilters.profilePhotoTypes.selectionItems.first;

    memberFilters.searchKey =
        databaseUserSetting != null ? databaseUserSetting.memberSearchKey : '';

    memberFilters.selectedSortByType = databaseUserSetting != null
        ? memberFilters.sortByTypes.selectionItems
                .where((selectionItem) =>
                    selectionItem.value ==
                    databaseUserSetting.memberSearchOrderType)
                .firstOrNull ??
            memberFilters.sortByTypes.selectionItems.first
        : memberFilters.sortByTypes.selectionItems.first;
  }

  XProfileFieldOptionsItem? parseSavedFilterItem(String savedFilterItem) {
    try {
      return XProfileFieldOptionsItem.fromJson(
        jsonDecode(savedFilterItem),
      );
    } on Exception catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveMemberSearchFilters() async {
    // NOTE: XProfile IDs for multi-select fields differ between the live and
    // clone sites, so these may appear as empty when switching between sites
    // since the filters saved to the database would have been from the
    // prior site.
    final databaseUserSetting =
        await _localStorageProvider.getUserSetting(_currentUser!.id);

    databaseUserSetting.memberSearchConnectionTypes =
        jsonEncode(_memberFilters.connectionTypes.toJson());
    databaseUserSetting.memberSearchGenders =
        jsonEncode(_memberFilters.genders.toJson());
    databaseUserSetting.memberSearchSexualOrientations =
        jsonEncode(_memberFilters.sexualOrientations.toJson());
    databaseUserSetting.memberSearchLocations =
        jsonEncode(_memberFilters.locations.toJson());
    databaseUserSetting.memberSearchPassions =
        jsonEncode(_memberFilters.passions.toJson());
    databaseUserSetting.memberSearchEthnicities =
        jsonEncode(_memberFilters.ethnicities.toJson());

    databaseUserSetting.memberSearchAgeFrom =
        _memberFilters.ageRange.selectedRange.start.toInt();
    databaseUserSetting.memberSearchAgeTo =
        _memberFilters.ageRange.selectedRange.end.toInt();
    databaseUserSetting.memberSearchPhotoType =
        _memberFilters.selectedProfilePhotoType.value;
    databaseUserSetting.memberSearchKey = _memberFilters.searchKey;
    databaseUserSetting.memberSearchOrderType =
        _memberFilters.selectedSortByType.value;

    await _localStorageProvider.updateUserSetting(databaseUserSetting);
  }

  @override
  Future<void> clearMemberSearchFilters() async {
    _memberFilters = MemberFilters();
    await saveMemberSearchFilters();
    populateMemberSearchFilters(_memberFilters,
        databaseUserSetting:
            await _localStorageProvider.getUserSetting(_currentUser!.id));
  }

  int _activeMemberFiltersCount() {
    int count = 0;

    if (_memberFilters.connectionTypes.selectionItems
        .where((selectionItem) => selectionItem.isSelected)
        .isNotEmpty) {
      count++;
    }

    if (_memberFilters.genders.selectionItems
        .where((selectionItem) => selectionItem.isSelected)
        .isNotEmpty) {
      count++;
    }

    if (_memberFilters.sexualOrientations.selectionItems
        .where((selectionItem) => selectionItem.isSelected)
        .isNotEmpty) {
      count++;
    }

    if (_memberFilters.locations.selectionItems
        .where((selectionItem) => selectionItem.isSelected)
        .isNotEmpty) {
      count++;
    }

    if (_memberFilters.passions.selectionItems
        .where((selectionItem) => selectionItem.isSelected)
        .isNotEmpty) {
      count++;
    }

    if (_memberFilters.ethnicities.selectionItems
        .where((selectionItem) => selectionItem.isSelected)
        .isNotEmpty) {
      count++;
    }

    if (memberFilters.ageRange.selectedRange.start != minimumSearchAge ||
        _memberFilters.ageRange.selectedRange.end != maximumSearchAge) {
      count++;
    }

    if (_memberFilters.selectedProfilePhotoType.value != photoTypeAll) {
      count++;
    }

    if (_memberFilters.searchKey.isNotEmpty) {
      count++;
    }

    if (_memberFilters.selectedSortByType.value != sortByTypeActive) {
      count++;
    }

    return count;
  }

  // Note: Certain users, such as contributors, may have xProfile field data
  // which is filtered out by the XProfileArgs, so they are never actually
  // part of the data returned (for e.g. ages below 18, or 0).
  List<Member> _applySystemFilters(List<Member> members) {
    // Filter out system users.
    final systemUsers = systemUsersMap[_connectionProvider.serverUrl];
    if (systemUsers != null) {
      members.removeWhere((member) => systemUsers.contains(member.id));
    }
    // Filter out logged in user.
    members.removeWhere((member) => member.id == _currentUser!.id);

    if (!_databaseSystemSetting.showContributors) {
      // Filter out contributors.
      final contributors = contributorsMap[_connectionProvider.serverUrl];
      if (contributors != null) {
        members.removeWhere((member) => contributors.contains(member.id));
      }
    }
    if (!_databaseSystemSetting.showDemoUsers) {
      // Filter out demo users.
      final demoUsers = demoUsersMap[_connectionProvider.serverUrl];
      if (demoUsers != null) {
        members.removeWhere((member) => demoUsers.contains(member.id));
      }
    }
    return members;
  }

  List<Member> _applyUserFilters(List<Member> members) {
    // Apply photo filter.
    switch (_memberFilters.selectedProfilePhotoType.value) {
      case photoTypeHasPhoto:
        members.removeWhere((member) =>
            basename(member.avatar!.full!) == basename(defaultAvatarURL));
      case photoTypeHasNoPhoto:
        members.removeWhere((member) =>
            basename(member.avatar!.full!) != basename(defaultAvatarURL));
    }

    return members;
  }

  bool memberMeetsXProfileFilterCriteria(XProfileFieldOptionsItem filterItem,
      MemberFieldGroup group, int xProfileFieldId) {
    final selectionItems = filterItem.selectionItems
        .where((selectionItem) => selectionItem.isSelected == true);

    if (selectionItems.isNotEmpty) {
      final field = group.fields
          .where((field) => field.id == xProfileFieldId)
          .firstOrNull;

      if (field != null) {
        for (final selectionItem in selectionItems) {
          if (field.value!.unserialized!
              .contains(selectionItem.contextTypeDescription)) {
            return true;
          }
        }

        return false;
      }
    }
    return true;
  }

  @override
  Future<List<Member>> getMembers(int page) async {
    _getCurrentUserOrThrow();

    // No need to fetch if we already have this page.
    if (_membersDirectory[page] != null) {
      return _membersDirectory[page]!;
    }

    List<Member> membersPage = [];

    // NOTE: membersPerPage is used here, and not _membersPerPage
    // membersPerPage get provides the value based on if a photo filter is being used.
    while (membersPage.length < membersPerPage && !_isLastMembersPage) {
      var membersGetRequest = MembersGetRequest(
        page: _currentMembersPage,
        perPage: membersPerPage,
        searchKey: _memberFilters.searchKey,
        type: sortByMap[_memberFilters.selectedSortByType.value],
        args: _generateXProfileArguments(),
      );
      final results = await _connectionProvider.getMembers(membersGetRequest);
      final resultsPageLength = results.length;
      _applySystemFilters(results);
      _applyUserFilters(results);
      membersPage.addAll(results);
      if (resultsPageLength < membersPerPage) {
        _isLastMembersPage = true;
      } else {
        _currentMembersPage++;
      }
    }

    _membersDirectory[page] = membersPage;
    return membersPage;
  }

  XProfileArguments? _generateXProfileArguments() {
    final List<XProfileArgument> arguments = [];

    final argumentConnections = _generateXProfileArgument(
        _memberFilters.connectionTypes,
        isMultiSelectionField: true);
    if (argumentConnections != null) {
      arguments.add(argumentConnections);
    }

    // Note: The filters are saved against the xProfileFieldLookingFor field which is
    // different to the xProfileFieldGender field that is needed for the argument.
    final argumentGenders = _generateXProfileArgument(
      _memberFilters.genders,
      alternateXProfileFieldId: xProfileFieldGender,
    );
    if (argumentGenders != null) {
      arguments.add(argumentGenders);
    }

    final argumentSexualOrientations =
        _generateXProfileArgument(_memberFilters.sexualOrientations);
    if (argumentSexualOrientations != null) {
      arguments.add(argumentSexualOrientations);
    }

    final argumentLocations =
        _generateXProfileArgument(_memberFilters.locations);
    if (argumentLocations != null) {
      arguments.add(argumentLocations);
    }

    final argumentPassions = _generateXProfileArgument(
      _memberFilters.passions,
      isMultiSelectionField: true,
    );
    if (argumentPassions != null) {
      arguments.add(argumentPassions);
    }

    final argumentEthnicities = _generateXProfileArgument(
      _memberFilters.ethnicities,
      isMultiSelectionField: true,
    );
    if (argumentEthnicities != null) {
      arguments.add(argumentEthnicities);
    }

    arguments.add(_generateXProfileAgeArgument(
      _memberFilters.ageRange.selectedRange.start,
      _memberFilters.ageRange.selectedRange.end,
    ));

    return arguments.isEmpty ? null : XProfileArguments(args: arguments);
  }

  XProfileArgument? _generateXProfileArgument(
      XProfileFieldOptionsItem optionsItem,
      {int? alternateXProfileFieldId,
      bool isMultiSelectionField = false}) {
    final selectedItems = optionsItem.selectionItems
        .where((selectionItem) => selectionItem.isSelected);

    if (selectedItems.isNotEmpty) {
      final List<String> values = [];
      for (final selectedLocation in selectedItems) {
        values.add(selectedLocation.contextTypeDescription);
      }
      return XProfileArgument(
          field: alternateXProfileFieldId ?? optionsItem.xProfileFieldId,
          values: values,
          compare: isMultiSelectionField ? 'RLIKE' : 'IN');
    }

    return null;
  }

  XProfileArgument _generateXProfileAgeArgument(
      double startAge, double endAge) {
    const String dateFormat = 'yyyy-MM-dd 00:00:00';

    final now = DateTime.now();

    // + 1 to endAge to capture the span of the whole year
    // Needed in case both the start and end age is the same.
    final startDate = DateFormat(dateFormat).format(DateTime(
      now.year - (endAge.toInt() + 1),
      now.month,
      now.day,
    ));
    final endDate = DateFormat(dateFormat).format(DateTime(
      now.year - (startAge.toInt()),
      now.month,
      now.day,
    ));

    return XProfileArgument(
      field: xProfileFieldBirthdate,
      values: [startDate, endDate],
      compare: 'BETWEEN',
    );
  }

  @override
  void clearMembersDirectory() {
    _membersDirectory.clear();
    _currentMembersPage = 1;
    _isLastMembersPage = false;
  }

  void _loadMultiSelectionField(XProfileFieldOptionsItem filterItem,
      {XProfileFieldOptionsItem? savedFilterItem}) {
    filterItem.selectionItems.clear();

    if (_connectionProvider.xProfileFields != null) {
      for (final xProfileField in _connectionProvider.xProfileFields!) {
        if (xProfileField.id == filterItem.xProfileFieldId) {
          for (final xProfileFieldOption in xProfileField.options!) {
            var selectionItem = XProfileFieldOptionSelectionItem(
              contextTypeId: xProfileFieldOption.id,
              contextTypeDescription: xProfileFieldOption.name,
            );
            if (savedFilterItem != null) {
              var savedSelectionItem = savedFilterItem.selectionItems
                  .where((selectionItem) =>
                      selectionItem.contextTypeId == xProfileFieldOption.id)
                  .firstOrNull;
              if (savedSelectionItem != null) {
                selectionItem.isSelected = savedSelectionItem.isSelected;
              }
            }
            filterItem.selectionItems.add(selectionItem);
          }
          break;
        }
      }
    }
  }

  @override
  Map<int, List<Member>> get membersDirectory => _membersDirectory;

  @override
  List<Member> get members => _membersDirectory.isEmpty
      ? []
      : _membersDirectory.values.reduce((sum, element) => sum + element);

  @override
  Future<List<Member>> getFavouriteMembers(int page) async {
    _getCurrentUserOrThrow();

    // No need to fetch if we already have this page.
    if (_favouriteMembersDirectory[page] != null) {
      return _favouriteMembersDirectory[page]!;
    }

    List<Member> favourites = [];
    var favouriteMembersGetRequest = MemberFavouritesGetRequest(
        page: page, perPage: _favouriteMembersPerPage);
    var results = await _connectionProvider
        .getFavouriteMembers(favouriteMembersGetRequest);
    for (final result in results) {
      if (result.member == null) continue;
      if (favouriteMembers
          .where((member) => member.id == result.member!.id)
          .isEmpty) {
        favourites.add(result.member!);
      }
    }
    if (results.length < _favouriteMembersPerPage) {
      _isFavouriteMembersLastPage = true;
    }
    _applySystemFilters(favourites);
    _favouriteMembersDirectory[page] = favourites;
    return favourites;
  }

  @override
  void clearFavouriteMembersDirectory() {
    _favouriteMembersDirectory.clear();
    _isFavouriteMembersLastPage = false;
  }

  @override
  Map<int, List<Member>> get favouriteMembersDirectory =>
      _favouriteMembersDirectory;

  @override
  List<Member> get favouriteMembers => _favouriteMembersDirectory.isEmpty
      ? []
      : _favouriteMembersDirectory.values
          .reduce((sum, element) => sum + element);

  @override
  Future<List<Member>> getFavouritedByMembers(int page) async {
    _getCurrentUserOrThrow();
    // Test again when fix has been applied.
    // No need to fetch if we already have this page.
    if (_favouritedByMembersDirectory[page] != null) {
      return _favouritedByMembersDirectory[page]!;
    }

    List<Member> favourites = [];
    var favouritedByMembersGetRequest = MemberFavouritesGetRequest(
        page: page, perPage: _favouritedByMembersPerPage);
    var results = await _connectionProvider
        .getFavouritedByMembers(favouritedByMembersGetRequest);
    for (final result in results) {
      if (favouritedByMembers
          .where((member) => member.id == result.member.id)
          .isEmpty) {
        favourites.add(result.member);
      }
    }
    if (results.length < _favouritedByMembersPerPage) {
      _isFavouritedByMembersLastPage = true;
    }
    _applySystemFilters(favourites);
    _favouritedByMembersDirectory[page] = favourites;
    return favourites;
  }

  @override
  void clearFavouritedByMembersDirectory() {
    _favouritedByMembersDirectory.clear();
    _isFavouritedByMembersLastPage = false;
  }

  @override
  Map<int, List<Member>> get favouritedByMembersDirectory =>
      _favouritedByMembersDirectory;

  @override
  List<Member> get favouritedByMembers => _favouritedByMembersDirectory.isEmpty
      ? []
      : _favouritedByMembersDirectory.values
          .reduce((sum, element) => sum + element);

  @override
  Future<List<Member>> getNewestMembers(int page) async {
    _getCurrentUserOrThrow();

    // No need to fetch if we already have this page.
    if (_newestMembersDirectory[page] != null) {
      return _newestMembersDirectory[page]!;
    }

    List<Member> newestMembers = [];
    var membersGetRequest = MembersGetRequest(
      page: page,
      perPage: _newestMembersPerPage,
      args: _generateXProfileArguments(),
    );
    var results = await _connectionProvider.getMembers(membersGetRequest);
    _applySystemFilters(results);
    _applyUserFilters(results);
    for (final result in results) {
      if (newestMembers.where((member) => member.id == result.id).isEmpty) {
        newestMembers.add(result);
      }
    }
    _newestMembersDirectory[page] = newestMembers;
    return newestMembers;
  }

  @override
  void clearNewestMembersDirectory() {
    _newestMembersDirectory.clear();
  }

  @override
  Map<int, List<Member>> get newestMembersDirectory => _newestMembersDirectory;

  @override
  List<Member> get newestMembers => _newestMembersDirectory.isEmpty
      ? []
      : _newestMembersDirectory.values.reduce((sum, element) => sum + element);

  // Reduce members per page if filtering on photo type for faster results.
  @override
  int get membersPerPage =>
      _memberFilters.selectedProfilePhotoType.value == photoTypeAll
          ? _membersPerPage
          : 10;

  @override
  int get favouriteMembersPerPage => _favouriteMembersPerPage;

  @override
  int get favouritedByMembersPerPage => _favouritedByMembersPerPage;

  @override
  int get newestMembersPerPage => _newestMembersPerPage;

  @override
  MemberFilters get memberFilters => _memberFilters;

  @override
  int get activeMemberFiltersCount => _activeMemberFiltersCount();

  @override
  bool get isFavouriteMembersLastPage => _isFavouriteMembersLastPage;

  @override
  bool get isFavouritedByMembersLastPage => _isFavouritedByMembersLastPage;

  @override
  bool get isMembersLastPage => _isLastMembersPage;

  @override
  void updateMemberStatus(Member member) {
    // Set the isFavourite, isBlocked and isSuspended properties of the same member
    // instance if they exist in the data for any of the categories.
    _setMemberStatus(
      [
        MemberDirectoryCategory.members,
        MemberDirectoryCategory.myFavourites,
        MemberDirectoryCategory.favouritedMe,
        MemberDirectoryCategory.newest,
      ],
      member,
    );
  }

  void _setMemberStatus(
      List<MemberDirectoryCategory> categories, Member member) {
    for (final category in categories) {
      switch (category) {
        case MemberDirectoryCategory.members:
          {
            _updateDirectoryMembers(members, member);
            if (updateMembers != null) updateMembers!([member]);
          }
        case MemberDirectoryCategory.myFavourites:
          {
            _updateDirectoryMembers(favouriteMembers, member,
                addIfNotExists: true);
            if (updateMyFavourites != null) updateMyFavourites!([member]);
          }
        case MemberDirectoryCategory.favouritedMe:
          {
            _updateDirectoryMembers(favouritedByMembers, member);
            if (updateFavouritedMe != null) updateFavouritedMe!([member]);
          }
        case MemberDirectoryCategory.newest:
          {
            _updateDirectoryMembers(newestMembers, member);
            if (updateNewest != null) updateNewest!([member]);
          }
      }
    }
  }

  void _updateDirectoryMembers(List<Member> members, Member updatedMember,
      {bool addIfNotExists = false}) {
    final member = members
        .where((existingMember) => existingMember.id == updatedMember.id)
        .firstOrNull;

    if (member != null) {
      if (updatedMember.isBlocked != null) {
        member.isBlocked = updatedMember.isBlocked;
      }

      if (updatedMember.isSuspended != null) {
        member.isSuspended = updatedMember.isSuspended;
      }

      if (updatedMember.isFavourite != null) {
        member.isFavourite = updatedMember.isFavourite;
      }
    } else {
      if (addIfNotExists) members.add(updatedMember);
    }
  }

  @override
  void Function(List<Member> members)? get updateMembers => _updateMembers;

  void Function(List<Member> members)? _updateMembers;

  @override
  set updateMembers(void Function(List<Member> members)? value) {
    if (value != null) {
      _updateMembers = value;
    }
  }

  @override
  void Function(List<Member> members)? get updateMyFavourites =>
      _updateMyFavourites;

  void Function(List<Member> members)? _updateMyFavourites;

  @override
  set updateMyFavourites(void Function(List<Member> members)? value) {
    if (value != null) {
      _updateMyFavourites = value;
    }
  }

  @override
  void Function(List<Member> members)? get updateFavouritedMe =>
      _updateFavouritedMe;

  void Function(List<Member> members)? _updateFavouritedMe;

  @override
  set updateFavouritedMe(void Function(List<Member> members)? value) {
    if (value != null) {
      _updateFavouritedMe = value;
    }
  }

  @override
  void Function(List<Member> members)? get updateNewest => _updateNewest;

  void Function(List<Member> members)? _updateNewest;

  @override
  set updateNewest(void Function(List<Member> members)? value) {
    if (value != null) {
      _updateNewest = value;
    }
  }

  @override
  Future<List<Member>> getRandomTopMatchedMembers(int count) async {
    _getCurrentUserOrThrow();

    List<Member> membersPage = [];
    int currentMembersPage = 1;
    bool isLastMembersPage = false;

    // NOTE: membersPerPage is used here, and not _membersPerPage
    // membersPerPage get provides the value based on if a photo filter is being used.
    while (membersPage.length < count && !isLastMembersPage) {
      var membersGetRequest = MembersGetRequest(
        page: currentMembersPage,
        perPage: membersPerPage,
        type: sortByMap[sortByTypeRandom],
        args: _generateXProfileArguments(),
      );
      var results = await _connectionProvider.getMembers(membersGetRequest);
      final resultsPageLength = results.length;
      _applySystemFilters(results);
      _applyUserFilters(results);
      results.sort((a, b) => b.matchWeight.compareTo(a.matchWeight));
      if (results.length > count) {
        results = results.sublist(0, count);
      }
      membersPage.addAll(results);
      if (resultsPageLength < membersPerPage) {
        isLastMembersPage = true;
      } else {
        currentMembersPage++;
      }
    }

    return membersPage;
  }

  @override
  Future<bool> checkUserCanAddFavourite() async {
    var databaseUserSetting =
        await _localStorageProvider.getUserSetting(_currentUser!.id);
    var lastFavouriteAddedTimestamp = DateTime.fromMillisecondsSinceEpoch(
        databaseUserSetting.lastFavouriteAddedTimestamp);
    var timeDiff =
        DateTime.now().difference(lastFavouriteAddedTimestamp).inSeconds;
    if (timeDiff > 60) {
      databaseUserSetting.newFavouritesAddedCount = 0;
      await _localStorageProvider.updateUserSetting(databaseUserSetting);
      return true;
    }
    return !(databaseUserSetting.newFavouritesAddedCount ==
            _maximumNewFavouritesPerInterval &&
        timeDiff < 60);
  }

  @override
  Future<void> updateFavouriteAddedTimestamp() async {
    var databaseUserSetting =
        await _localStorageProvider.getUserSetting(_currentUser!.id);
    databaseUserSetting.newFavouritesAddedCount =
        databaseUserSetting.newFavouritesAddedCount + 1;
    if (databaseUserSetting.newFavouritesAddedCount == 1) {
      databaseUserSetting.lastFavouriteAddedTimestamp =
          DateTime.now().millisecondsSinceEpoch;
    }
    await _localStorageProvider.updateUserSetting(databaseUserSetting);
  }
}
