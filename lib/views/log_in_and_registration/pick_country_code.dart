import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

void pickCountryCode({
  required BuildContext context,
  List<String>? exclusions,
  List<String>? favourites,
  required void Function(Country) onSelect,
}) =>
    showCountryPicker(
      context: context,
      exclude: exclusions,
      favorite: favourites,
      //Optional. Shows phone code before the country name.
      showPhoneCode: true,
      onSelect: onSelect,
      // Optional. Sheet moves when keyboard opens.
      moveAlongWithKeyboard: false,
      // Optional. Sets the theme for the country list picker.
      countryListTheme: CountryListThemeData(
        // Optional. Sets the border radius for the bottomsheet.
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
        // Optional. Styles the search field.
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
