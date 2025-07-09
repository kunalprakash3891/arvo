import 'package:app_base/extensions/string_extensions.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field_description.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_options_item.dart';

XProfileFieldLocations? generateLocationXProfileFields(
    XProfileField? xProfileField) {
  if (xProfileField == null) return null;

  Locations? locations = extractXProfileFieldLocations(xProfileField);

  if (locations == null) return null;

  // Generate Country selectbox
  var xProfileFieldLocations = XProfileFieldLocations(
    xProfileField: xProfileField,
    countries: XProfileField(
        id: DateTime.now()
            .microsecondsSinceEpoch, // Generate a (time-based) unique id,
        groupId: xProfileField.groupId,
        parentId: 0,
        type: 'selectbox',
        name: 'Country',
        description: xProfileField.description,
        isRequired: true,
        fieldOrder: 0,
        optionOrder: 0,
        orderby: 'orderby',
        isDefaultOption: false,
        options: []),
    statesAndRegions: [],
    citiesAndTowns: [],
  );

  for (final country in locations.countries) {
    // Add a selection option for this country
    xProfileFieldLocations.countries.options!.add(
      XProfileField(
          id: country.id,
          groupId: xProfileField.groupId,
          parentId: 0,
          type: 'option',
          name: country.name,
          description: XProfileFieldDescription(
              raw: country.name, rendered: country.name),
          isRequired: true,
          fieldOrder: 0,
          optionOrder: 0,
          orderby: 'orderby',
          isDefaultOption: false),
    );

    // Generate a State/Region selectbox for this country and populate with options
    final statesAndRegions = locations.statesAndRegions
        .where((stateRegion) => stateRegion.parentId == country.id);

    if (statesAndRegions.isEmpty) continue;

    final xProfileFieldStateAndRegion = XProfileField(
        id: DateTime.now()
            .microsecondsSinceEpoch, // Generate a (time-based) unique id
        groupId: xProfileField.groupId,
        parentId: country.id,
        type: 'selectbox',
        name: 'State/Region',
        description: const XProfileFieldDescription(),
        isRequired: true,
        fieldOrder: 0,
        optionOrder: 0,
        orderby: 'orderby',
        isDefaultOption: false,
        options: []);
    for (final stateRegion in statesAndRegions) {
      xProfileFieldStateAndRegion.options!.add(
        XProfileField(
            id: stateRegion.id,
            groupId: xProfileField.groupId,
            parentId: xProfileFieldStateAndRegion.id,
            type: 'option',
            name: stateRegion.name,
            description: XProfileFieldDescription(
                raw: stateRegion.name, rendered: stateRegion.name),
            isRequired: true,
            fieldOrder: 0,
            optionOrder: 0,
            orderby: 'orderby',
            isDefaultOption: false),
      );

      // Generate a Town/City selectbox for this state/region and populate with options
      final citiesAndTowns = locations.citiesAndTowns
          .where((cityTown) => cityTown.parentId == stateRegion.id);

      if (citiesAndTowns.isEmpty) continue;

      final xProfileFieldCityAndTown = XProfileField(
          id: DateTime.now()
              .microsecondsSinceEpoch, // Generate a (time-based) unique id
          groupId: xProfileField.groupId,
          parentId: stateRegion.id,
          type: 'selectbox',
          name: 'City/Town',
          description: const XProfileFieldDescription(),
          isRequired: true,
          fieldOrder: 0,
          optionOrder: 0,
          orderby: 'orderby',
          isDefaultOption: false,
          options: []);

      for (final cityTown in citiesAndTowns) {
        xProfileFieldCityAndTown.options!.add(
          XProfileField(
              id: cityTown.id,
              groupId: xProfileField.groupId,
              parentId: xProfileFieldCityAndTown.id,
              type: 'option',
              name: cityTown.name,
              description: XProfileFieldDescription(
                  raw: cityTown.name, rendered: cityTown.name),
              isRequired: true,
              fieldOrder: 0,
              optionOrder: 0,
              orderby: 'orderby',
              isDefaultOption: false),
        );
      }
      xProfileFieldLocations.citiesAndTowns.add(xProfileFieldCityAndTown);
    }
    xProfileFieldLocations.statesAndRegions.add(xProfileFieldStateAndRegion);
  }

  return xProfileFieldLocations;
}

class XProfileFieldLocations {
  XProfileField xProfileField;
  XProfileField countries;
  List<XProfileField> statesAndRegions;
  List<XProfileField> citiesAndTowns;

  XProfileFieldLocations({
    required this.xProfileField,
    required this.countries,
    required this.statesAndRegions,
    required this.citiesAndTowns,
  });
}

Locations? extractXProfileFieldLocations(XProfileField? locationXProfileField) {
  if (locationXProfileField == null) return null;
  if (locationXProfileField.options == null) return null;

  Locations locations =
      Locations(countries: [], statesAndRegions: [], citiesAndTowns: []);
  final options = locationXProfileField.options!;

  for (final xProfileField in options) {
    // Split the name into the consituent locations.
    List<String> locationNames =
        xProfileField.name.split(xProfileLocationDisplayTitleSplitOnCharacter);

    if (locationNames.isEmpty) continue;

    final countryName = locationNames[0];
    Location? country = locations.countries
        .where((country) => country.name == countryName)
        .firstOrNull;
    if (country == null) {
      // Generate a (time-based) unique id.
      country = Location(
          id: DateTime.now().microsecondsSinceEpoch, name: countryName);
      locations.countries.add(country);
    }

    if (locationNames.length == 1) continue;

    final regionStateName = locationNames[1];
    Location? regionState = locations.statesAndRegions
        .where((regionState) =>
            regionState.name == regionStateName &&
            regionState.parentId == country!.id)
        .firstOrNull;
    if (regionState == null) {
      // Generate a (time-based) unique id.
      regionState = Location(
          id: DateTime.now().microsecondsSinceEpoch,
          parentId: country.id,
          name: regionStateName);
      locations.statesAndRegions.add(regionState);
    }

    if (locationNames.length == 2) continue;

    final cityTownName = locationNames[2];
    Location? cityTown = locations.citiesAndTowns
        .where((cityTown) =>
            cityTown.name == cityTownName &&
            cityTown.parentId == regionState!.id)
        .firstOrNull;
    if (cityTown == null) {
      // Generate a (time-based) unique id.
      cityTown ??= Location(
          id: DateTime.now().microsecondsSinceEpoch,
          parentId: regionState.id,
          name: cityTownName);
      locations.citiesAndTowns.add(cityTown);
    }
  }

  // Country sorting and formatting.
  // Sort the countries.
  for (int i = xProfileFieldCountrySortMap.keys.last;
      i >= xProfileFieldCountrySortMap.keys.first;
      i--) {
    final country = locations.countries
        .where((country) =>
            country.name.removeEscapeCharacters() ==
            xProfileFieldCountrySortMap[i])
        .firstOrNull;
    if (country != null) {
      locations.countries.remove(country);
      locations.countries.insert(0, country);
    }
  }

  return locations;
}

@immutable
class Location {
  final int id;
  final int? parentId;
  final String name;

  const Location({
    required this.id,
    this.parentId,
    required this.name,
  });
}

class Locations {
  List<Location> countries;
  List<Location> statesAndRegions;
  List<Location> citiesAndTowns;

  Locations({
    required this.countries,
    required this.statesAndRegions,
    required this.citiesAndTowns,
  });
}

String locationDisplayFormatter(String selectedItemDescription) {
  return selectedItemDescription
      .split(xProfileLocationDisplayTitleSplitOnCharacter)
      .reversed
      .join(xProfileLocationDisplayTitleJoinOnCharacter);
}

String shortLocationDisplayFormatter(String selectedItemDescription) {
  final locations = selectedItemDescription
      .split(xProfileLocationDisplayTitleSplitOnCharacter)
      .toList();

  // Replace long state names with short names
  for (int i = 0; i < locations.length; i++) {
    locations[i] = australianStatesShortNameMap[locations[i]] ?? locations[i];
  }

  // Remove country if Australia
  locations.removeWhere((location) => location == australia);

  return locations.reversed.join(xProfileLocationDisplayTitleJoinOnCharacter);
}

// NOTE: The following code iteratively generates locations with parent identifiers, but does not group them into countries/states/cities.
/*List<Location>? extractXProfileFieldLocations(
    XProfileField? locationXProfileField) {
  if (locationXProfileField == null) return null;
  if (locationXProfileField.options == null) return null;

  final List<Location> locations = [];

  final options = locationXProfileField.options!;

  for (final xProfileField in options) {
    // Split into the consituent locations.
    List<String> locationNames = xProfileField.name.split(xProfileLocationDisplayTitleSplitOnCharacter);

    for (final locationName in locationNames) {
      for (int i = locationName.length - 1; i >= 0; i--) {
        Location? parent;
        if (i > 0) {
          final parentName = locationName[i - 1];
          parent = locations
              .where((location) => location.name == parentName)
              .firstOrNull;
          if (parent == null) {
            parent = Location(
                id: DateTime.now().microsecondsSinceEpoch, name: parentName);
            locations.add(parent);
          }
        }
        locations.add(Location(
            id: DateTime.now().microsecondsSinceEpoch, name: locationName[i], parentId: parent?.id));
      }
    }
  }

  return locations;
}*/