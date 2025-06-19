import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/features/feature_provider.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/connection/member_filters.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';

abstract class MemberDirectoryProvider {
  MemberFilters get memberFilters;
  int get activeMemberFiltersCount;

  Map<int, List<Member>> get membersDirectory;
  List<Member> get members;
  int get membersPerPage;
  bool get isMembersLastPage;

  Map<int, List<Member>> get favouriteMembersDirectory;
  List<Member> get favouriteMembers;
  int get favouriteMembersPerPage;
  bool get isFavouriteMembersLastPage;

  Map<int, List<Member>> get favouritedByMembersDirectory;
  List<Member> get favouritedByMembers;
  int get favouritedByMembersPerPage;
  bool get isFavouritedByMembersLastPage;

  Map<int, List<Member>> get newestMembersDirectory;
  int get newestMembersPerPage;
  List<Member> get newestMembers;

  Future<void> initalise(
      ConnectionProvider connectionProvider,
      LocalStorageProvider localStorageProvider,
      FeatureProvider featureProvider);

  Future<void> loadSystemParameters();

  void populateMemberSearchFilters(MemberFilters memberFilters,
      {DatabaseUserSetting? databaseUserSetting});

  Future<void> saveMemberSearchFilters();

  Future<void> clearMemberSearchFilters();

  Future<List<Member>> getMembers(int page);

  void clearMembersDirectory();

  Future<List<Member>> getFavouriteMembers(int page);

  void clearFavouriteMembersDirectory();

  Future<List<Member>> getFavouritedByMembers(int page);

  void clearFavouritedByMembersDirectory();

  Future<List<Member>> getNewestMembers(int page);

  void clearNewestMembersDirectory();

  void updateMemberStatus(Member member);

  // void reloadViews(MemberDirectoryCategory? category);

  void Function(List<Member> members)? get updateMembers;
  set updateMembers(void Function(List<Member> members)? value);

  void Function(List<Member> members)? get updateMyFavourites;
  set updateMyFavourites(void Function(List<Member> members)? value);

  void Function(List<Member> members)? get updateFavouritedMe;
  set updateFavouritedMe(void Function(List<Member> members)? value);

  void Function(List<Member> members)? get updateNewest;
  set updateNewest(void Function(List<Member> members)? value);

  Future<List<Member>> getRandomTopMatchedMembers(int count);

  Future<bool> checkUserCanAddFavourite();

  Future<void> updateFavouriteAddedTimestamp();
}
