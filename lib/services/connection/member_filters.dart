import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:nifty_three_bp_app_base/constants/member_filter.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_options_item.dart';

const double minimumSearchAge = 18;
const double maximumSearchAge = 99;

const int photoTypeAll = 0;
const int photoTypeHasPhoto = 1;
const int photoTypeHasNoPhoto = 2;

const int sortByTypeActive = 0;
const int sortByTypeNewest = 1;
const int sortByTypeAlphabetical = 2;
const int sortByTypeRandom = 3;

Map<int, String> sortByMap = {
  sortByTypeActive: "active",
  sortByTypeNewest: "newest",
  sortByTypeAlphabetical: "alphabetical",
  sortByTypeRandom: "random",
};

class MemberFilters {
  XProfileFieldOptionsItem connectionTypes = XProfileFieldOptionsItem(
    xProfileFieldId: xProfileFieldConnection,
    displayTitle: filterDisplayTitleConnection,
    selectionItems: [],
  );
  XProfileFieldOptionsItem genders = XProfileFieldOptionsItem(
    xProfileFieldId: xProfileFieldLookingFor,
    displayTitle: filterDisplayTitleGender,
    selectionItems: [],
  );
  XProfileFieldOptionsItem sexualOrientations = XProfileFieldOptionsItem(
    xProfileFieldId: xProfileFieldSexualOrientation,
    displayTitle: filterDisplayTitleSexualOrientation,
    selectionItems: [],
  );
  XProfileFieldOptionsItem locations = XProfileFieldOptionsItem(
    xProfileFieldId: xProfileFieldLocation,
    displayTitle: filterDisplayTitleLocation,
    selectionItems: [],
  );
  XProfileFieldOptionsItem passions = XProfileFieldOptionsItem(
    xProfileFieldId: xProfileFieldPassion,
    displayTitle: filterDisplayTitlePassion,
    selectionItems: [],
  );
  XProfileFieldOptionsItem ethnicities = XProfileFieldOptionsItem(
    xProfileFieldId: xProfileFieldEthnicity,
    displayTitle: filterDisplayTitleBackground,
    selectionItems: [],
  );
  late RangeFilterItem ageRange;
  late FilterItem profilePhotoTypes;
  late String searchKey;
  late SelectionItem selectedProfilePhotoType;
  late FilterItem sortByTypes;
  late SelectionItem selectedSortByType;

  MemberFilters() {
    ageRange = RangeFilterItem(
      displayTitle: filterDisplayTitleAge,
      min: minimumSearchAge,
      max: maximumSearchAge,
      selectedRange: const RangeValues(
        minimumSearchAge,
        maximumSearchAge,
      ),
    );
    profilePhotoTypes = FilterItem(
      displayTitle: filterDisplayTitleProfilePhoto,
      selectionItems: [
        SelectionItem(value: photoTypeAll, description: 'All'),
        SelectionItem(value: photoTypeHasPhoto, description: 'Has a photo'),
        SelectionItem(
            value: photoTypeHasNoPhoto, description: "Doesn't have a photo")
      ],
    );
    selectedProfilePhotoType = profilePhotoTypes.selectionItems.first;
    searchKey = '';
    sortByTypes = FilterItem(
      displayTitle: filterDisplayTitleSortBy,
      selectionItems: [
        SelectionItem(value: sortByTypeActive, description: 'Active'),
        SelectionItem(value: sortByTypeNewest, description: 'Newest'),
      ],
    );
    selectedSortByType = sortByTypes.selectionItems.first;
  }

  @override
  bool operator ==(covariant MemberFilters other) =>
      other.connectionTypes == connectionTypes &&
      other.genders == genders &&
      other.sexualOrientations == sexualOrientations &&
      other.locations == locations &&
      other.passions == passions &&
      other.ethnicities == ethnicities &&
      other.ageRange == ageRange &&
      other.profilePhotoTypes == profilePhotoTypes &&
      other.searchKey == searchKey &&
      other.selectedProfilePhotoType == selectedProfilePhotoType &&
      other.sortByTypes == sortByTypes &&
      other.selectedSortByType == selectedSortByType;

  @override
  int get hashCode => selectedSortByType.hashCode;
}

class FilterItem {
  String displayTitle;
  List<SelectionItem> selectionItems;

  FilterItem({
    required this.displayTitle,
    required this.selectionItems,
  });

  Function listEquality = const ListEquality().equals;

  @override
  bool operator ==(covariant FilterItem other) =>
      other.displayTitle == displayTitle &&
      listEquality(other.selectionItems, selectionItems);

  @override
  int get hashCode => displayTitle.hashCode;
}

class SelectionItem {
  int value;
  String? description;

  SelectionItem({
    required this.value,
    this.description,
  });

  @override
  bool operator ==(covariant SelectionItem other) =>
      other.value == value && other.description == description;

  @override
  int get hashCode => value.hashCode;
}

class RangeFilterItem {
  String displayTitle;
  double min;
  double max;
  RangeValues selectedRange;

  RangeFilterItem({
    required this.displayTitle,
    required this.min,
    required this.max,
    required this.selectedRange,
  });

  @override
  bool operator ==(covariant RangeFilterItem other) =>
      other.displayTitle == displayTitle &&
      other.min == min &&
      other.max == max &&
      other.selectedRange == selectedRange;

  @override
  int get hashCode => displayTitle.hashCode;
}
