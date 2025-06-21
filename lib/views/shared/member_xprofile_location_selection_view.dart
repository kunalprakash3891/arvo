import 'dart:io';

import 'package:app_base/generics/get_arguments.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/views/shared/x_profile_concat_location_utilities.dart';
import 'package:arvo/views/shared/x_profile_data_input_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field.dart';
import 'package:nifty_three_bp_app_base/extensions/string.dart';

class MemberXProfileLocationSelectionView extends StatefulWidget {
  const MemberXProfileLocationSelectionView({
    super.key,
  });

  @override
  State<MemberXProfileLocationSelectionView> createState() =>
      _MemberXProfileLocationSelectionViewState();
}

// TODO: Test with registration process to make sure changing the selected location various times works properly.
class _MemberXProfileLocationSelectionViewState
    extends State<MemberXProfileLocationSelectionView> {
  LocationOptions? _locationOptions;
  XProfileFieldLocations? _xProfileFieldLocations;
  XProfileField? _selectedCountry;
  XProfileField? _selectedStateRegion;
  XProfileField? _selectedCityTown;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_xProfileFieldLocations == null) {
      _locationOptions = context.getArgument<LocationOptions>();

      if (_locationOptions == null) {
        throw Exception('Invalid location selection data.');
      }

      _xProfileFieldLocations = generateLocationXProfileFields(
          _locationOptions!.xProfileFieldLocation);

      if (_xProfileFieldLocations == null) {
        throw Exception('Invalid location data.');
      }

      _populateSelectedXProfileOptions();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_locationOptions!.xProfileFieldLocation.name),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'Done',
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: setHeightBetweenWidgets(
                height: 16.0,
                [
                  _buildLocationInformationWidget(),
                  _buildLocationWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationWidget() {
    if (_xProfileFieldLocations == null) return const SizedBox.shrink();

    final xProfileField = _xProfileFieldLocations!.xProfileField;

    final additionalInformation =
        xProfileFieldAdditionalInformationMap[xProfileField.id];

    final hasDescription = xProfileField.description.rendered != null &&
        xProfileField.description.rendered!.isNotEmpty;

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
        children: [
          if (hasDescription)
            Text(
              xProfileField.description.rendered!.parseHTML(),
            ),
          if (hasDescription) const SizedBox(height: 8.0),
          if (additionalInformation != null) Text(additionalInformation),
          if (additionalInformation != null) const SizedBox(height: 8.0),
          _buildCountryWidget(),
          _buildStateRegionWidget(),
          _buildCityTownWidget(),
        ],
      ),
    );
  }

  Widget _buildCountryWidget() {
    return generateDropDownButtomFormField(
      context,
      _xProfileFieldLocations!.countries,
      _selectedCountry,
      (newValue) {
        if (newValue != null) {
          if (mounted) {
            setState(
              () {
                _selectedCountry = newValue;
                _selectedStateRegion = null;
                _selectedCityTown = null;
                _setSelectedXProfileLocationOption();
              },
            );
          }
        }
      },
      showLabelText: true,
    );
  }

  Widget _buildStateRegionWidget() {
    if (_selectedCountry == null) return const SizedBox.shrink();

    final stateRegionXProfileField = _xProfileFieldLocations!.statesAndRegions
        .where(
            (stateAndRegion) => stateAndRegion.parentId == _selectedCountry!.id)
        .firstOrNull;

    if (stateRegionXProfileField == null) return const SizedBox.shrink();

    if (_selectedStateRegion == null &&
        stateRegionXProfileField.options != null &&
        stateRegionXProfileField.options!.isNotEmpty) {
      final selectedStateRegion = stateRegionXProfileField.options!.first;
      _selectedStateRegion = selectedStateRegion;
      _setSelectedXProfileLocationOption();
    }

    return Column(
      children: [
        const SizedBox(height: 16.0),
        generateDropDownButtomFormField(
          context,
          stateRegionXProfileField,
          _selectedStateRegion,
          (newValue) {
            if (newValue != null) {
              if (mounted) {
                setState(
                  () {
                    _selectedStateRegion = newValue;
                    _selectedCityTown = null;
                    _setSelectedXProfileLocationOption();
                  },
                );
              }
            }
          },
          showLabelText: true,
        ),
      ],
    );
  }

  Widget _buildCityTownWidget() {
    if (_selectedStateRegion == null) return const SizedBox.shrink();

    final cityTownXProfileField = _xProfileFieldLocations!.citiesAndTowns
        .where(
            (cityAndTown) => cityAndTown.parentId == _selectedStateRegion!.id)
        .firstOrNull;

    if (cityTownXProfileField == null) return const SizedBox.shrink();

    if (_selectedCityTown == null &&
        cityTownXProfileField.options != null &&
        cityTownXProfileField.options!.isNotEmpty) {
      final selectedCityTown = cityTownXProfileField.options!.first;
      _selectedCityTown = selectedCityTown;
      _setSelectedXProfileLocationOption();
    }

    return Column(
      children: [
        const SizedBox(height: 16.0),
        generateDropDownButtomFormField(
          context,
          cityTownXProfileField,
          _selectedCityTown,
          (newValue) {
            if (newValue != null) {
              if (mounted) {
                setState(
                  () {
                    _selectedCityTown = newValue;
                    _setSelectedXProfileLocationOption();
                  },
                );
              }
            }
          },
          showLabelText: true,
        ),
      ],
    );
  }

  void _setSelectedXProfileLocationOption() {
    // Try to find and set the XProfile location option based on the selections.
    if (_selectedCountry?.name == null) return;

    _locationOptions!.xProfileFieldSelectedLocation = _locationOptions!
        .xProfileFieldLocation.options!
        .where((option) => option.name == _selectedCountry!.name)
        .firstOrNull;

    if (_selectedStateRegion?.name == null) return;

    _locationOptions!.xProfileFieldSelectedLocation = _locationOptions!
        .xProfileFieldLocation.options!
        .where((option) =>
            option.name ==
            '${_selectedCountry!.name} | ${_selectedStateRegion!.name}')
        .firstOrNull;

    if (_selectedCityTown?.name == null) return;

    _locationOptions!.xProfileFieldSelectedLocation = _locationOptions!
        .xProfileFieldLocation.options!
        .where((option) =>
            option.name ==
            '${_selectedCountry!.name} | ${_selectedStateRegion!.name} | ${_selectedCityTown!.name}')
        .firstOrNull;
  }

  void _populateSelectedXProfileOptions() {
    if (_locationOptions!.xProfileFieldSelectedLocation != null) {
      List<String> locationNames =
          _locationOptions!.xProfileFieldSelectedLocation!.name.split(' | ');

      if (locationNames.isNotEmpty) {
        final countryName = locationNames.first;
        _selectedCountry = _xProfileFieldLocations!.countries.options!
            .where((option) => option.name == countryName)
            .firstOrNull;

        if (locationNames.asMap()[1] != null) {
          final regionStateName = locationNames[1];
          _selectedStateRegion = _xProfileFieldLocations!.statesAndRegions
              .where(
                  (regionState) => regionState.parentId == _selectedCountry!.id)
              .first
              .options
              ?.where((option) => option.name == regionStateName)
              .firstOrNull;
        }

        if (locationNames.asMap()[2] != null) {
          final cityTownName = locationNames[2];
          _selectedCityTown = _xProfileFieldLocations!.citiesAndTowns
              .where(
                  (cityTown) => cityTown.parentId == _selectedStateRegion!.id)
              .first
              .options
              ?.where((option) => option.name == cityTownName)
              .firstOrNull;
        }
      }
    }
  }

  Widget _buildLocationInformationWidget() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.secondaryContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
      ),
      child: Row(
        children: setWidthBetweenWidgets(
          width: 8.0,
          [
            Icon(
              Platform.isIOS ? CupertinoIcons.info : Icons.info_rounded,
              size: 32.0,
            ),
            Expanded(
              child: Text(
                localisedTextLocationTracking,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationOptions {
  XProfileField xProfileFieldLocation;
  XProfileField? xProfileFieldSelectedLocation;

  LocationOptions({
    required this.xProfileFieldLocation,
    required this.xProfileFieldSelectedLocation,
  });
}
