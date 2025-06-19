import 'package:arvo/services/caching/arvo_member_directory_provider.dart';
import 'package:arvo/services/caching/member_directory_provider.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/features/feature_provider.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/connection/member_filters.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';

class MemberDirectoryService implements MemberDirectoryProvider {
  final MemberDirectoryProvider provider;
  MemberDirectoryService(this.provider);

  factory MemberDirectoryService.arvo() =>
      MemberDirectoryService(ArvoMemberDirectoryProvider());

  @override
  Future<void> initalise(
          ConnectionProvider connectionProvider,
          LocalStorageProvider localStorageProvider,
          FeatureProvider featureProvider) =>
      provider.initalise(
          connectionProvider, localStorageProvider, featureProvider);

  @override
  Future<void> loadSystemParameters() => provider.loadSystemParameters();

  @override
  void populateMemberSearchFilters(MemberFilters memberFilters,
          {DatabaseUserSetting? databaseUserSetting}) =>
      provider.populateMemberSearchFilters(memberFilters,
          databaseUserSetting: databaseUserSetting);

  @override
  Future<void> saveMemberSearchFilters() => provider.saveMemberSearchFilters();

  @override
  Future<void> clearMemberSearchFilters() =>
      provider.clearMemberSearchFilters();

  @override
  Future<List<Member>> getMembers(int page) => provider.getMembers(page);

  @override
  void clearMembersDirectory() => provider.clearMembersDirectory();

  @override
  Map<int, List<Member>> get membersDirectory => provider.membersDirectory;

  @override
  List<Member> get members => provider.members;

  @override
  bool get isMembersLastPage => provider.isMembersLastPage;

  @override
  Future<List<Member>> getFavouriteMembers(int page) =>
      provider.getFavouriteMembers(page);

  @override
  void clearFavouriteMembersDirectory() =>
      provider.clearFavouriteMembersDirectory();

  @override
  Map<int, List<Member>> get favouriteMembersDirectory =>
      provider.favouriteMembersDirectory;

  @override
  List<Member> get favouriteMembers => provider.favouriteMembers;

  @override
  bool get isFavouriteMembersLastPage => provider.isFavouriteMembersLastPage;

  @override
  Future<List<Member>> getFavouritedByMembers(int page) =>
      provider.getFavouritedByMembers(page);

  @override
  void clearFavouritedByMembersDirectory() =>
      provider.clearFavouritedByMembersDirectory();

  @override
  Map<int, List<Member>> get favouritedByMembersDirectory =>
      provider.favouritedByMembersDirectory;

  @override
  List<Member> get favouritedByMembers => provider.favouritedByMembers;

  @override
  bool get isFavouritedByMembersLastPage =>
      provider.isFavouritedByMembersLastPage;

  @override
  Future<List<Member>> getNewestMembers(int page) =>
      provider.getNewestMembers(page);

  @override
  void clearNewestMembersDirectory() => provider.clearNewestMembersDirectory();

  @override
  Map<int, List<Member>> get newestMembersDirectory =>
      provider.newestMembersDirectory;

  @override
  List<Member> get newestMembers => provider.newestMembers;

  @override
  int get membersPerPage => provider.membersPerPage;

  @override
  int get favouriteMembersPerPage => provider.favouriteMembersPerPage;

  @override
  int get favouritedByMembersPerPage => provider.favouritedByMembersPerPage;

  @override
  int get newestMembersPerPage => provider.newestMembersPerPage;

  @override
  MemberFilters get memberFilters => provider.memberFilters;

  @override
  int get activeMemberFiltersCount => provider.activeMemberFiltersCount;

  @override
  void updateMemberStatus(Member member) => provider.updateMemberStatus(member);

//  @override
//  void reloadViews(MemberDirectoryCategory? category) =>
//      provider.reloadViews(category);

  @override
  void Function(List<Member> members)? get updateMembers =>
      provider.updateMembers;

  @override
  set updateMembers(void Function(List<Member> members)? value) =>
      provider.updateMembers = value;

  @override
  void Function(List<Member> members)? get updateMyFavourites =>
      provider.updateMyFavourites;

  @override
  set updateMyFavourites(void Function(List<Member> members)? value) =>
      provider.updateMyFavourites = value;

  @override
  void Function(List<Member> members)? get updateFavouritedMe =>
      provider.updateFavouritedMe;

  @override
  set updateFavouritedMe(void Function(List<Member> members)? value) =>
      provider.updateFavouritedMe = value;

  @override
  void Function(List<Member> members)? get updateNewest =>
      provider.updateNewest;

  @override
  set updateNewest(void Function(List<Member> members)? value) =>
      provider.updateNewest = value;

  @override
  Future<List<Member>> getRandomTopMatchedMembers(int count) =>
      provider.getRandomTopMatchedMembers(count);

  @override
  Future<bool> checkUserCanAddFavourite() =>
      provider.checkUserCanAddFavourite();

  @override
  Future<void> updateFavouriteAddedTimestamp() =>
      provider.updateFavouriteAddedTimestamp();
}
