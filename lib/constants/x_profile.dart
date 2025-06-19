// xProfile field types.
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/theme/palette.dart';

const String fieldTypeTextBox = "textbox";
const String fieldTypeSelectBox = "selectbox";
const String fieldTypeCheckBox = "checkbox";
const String fieldTypeTextArea = "textarea";
const String fieldTypeMultiSelectBox = "multiselectbox";
const String fieldTypeDateBox = "datebox";

// xProfile groups and fields.
const int xProfileGroupAboutMe = 1;
const int xProfileGroupBackground = 2;
const int xProfileGroupInterests = 3;
const int xProfileGroupPerfectMatchQuiz = 4;

// Required fields.
const int xProfileFieldName = 1;
const int xProfileFieldGender = 2932;
const int xProfileFieldLocation = 5143;
const int xProfileFieldBirthdate = 2954;
const int xProfileFieldPassion = 2955;
const int xProfileFieldStatus = 2975;
const int xProfileFieldLookingFor = 2978;
const int xProfileFieldConnection = 2984;
const int xProfileFieldSexualOrientation = 2939;
const int xProfileFieldEthnicity = 3034;
const int xProfileFieldTermsAcceptance = 2996;
const int xProfileFieldOftenSmoke = 3148;
const int xProfileFieldOftenAlcohol = 3158;
const int xProfileFieldWantKids = 3153;
const int xProfileFieldPets = 3372;
const int xProfileFieldHobbies = 3177;
const int xProfileFieldFavouriteMovies = 3228;
const int xProfileFieldFavouriteMusic = 3244;
const int xProfileFieldFavouriteCuisine = 3263;
const int xProfileFieldFavouriteSweet = 3279;
const int xProfileFieldFavouriteDrink = 3293;
const int xProfileFieldFavouriteSport = 3312;
const int xProfileFieldFavouriteBooks = 3337;
const int xProfileFieldFavouriteGames = 3356;
const int xProfileFieldMainLanguage = 2997;
const int xProfileFieldFutureMarriage = 3404;
const int xProfileFieldPerfectWeekend = 3424;
const int xProfileFieldAppetite = 3433;
const int xProfileFieldWhoPaysBill = 3442;
const int xProfileFieldOftenCleaning = 3448;
const int xProfileFieldImportanceFriends = 3454;
const int xProfileFieldImportanceFamily = 3459;
const int xProfileFieldLiveWithFuture = 3464;
const int xProfileFieldImportantValue = 3408;
const int xProfileFieldImportantPersonalityTraits = 3415;
const int xProfileFieldWorkEthic = 3469;
const int xProfileFieldStayHomeOrGoOut = 3438;
const int xProfileFieldStaySpendOrSave = 3474;
const int xProfileFieldWhatDoesFootyMean = 3478;
const int xProfileFieldFeelAboutCamping = 3488;
const int xProfileFieldDoYouGamble = 3494;
const int xProfileFieldOffendedByLanguage = 3498;
const int xProfileFieldPotatoCakeFritterScallop = 3505;
const int xProfileFieldClassicSong = 3510;
const int xProfileFieldAstrologicalSign = 3164;
const int xProfileFieldReligion = 3046;
const int xProfileFieldWhatYouNeedToKnow = 2994;
const int xProfileFieldWhatImLookingFor = 2995;
const int xProfileFieldOccupation = 3101;

// xProfile field names.
const String xProfileFieldGenderName = "Gender";
const String xProfileFieldConnectionName = "Connection";
const String xProfileFieldLocationName = "Location";
const String xProfileFieldPassionName = "Passion";
const String xProfileFieldEthnicityName = "Ethnicity";
const String xProfileFieldBirthdateName = "Birthday / Age";

// Field match weightings.
const int xProfileFieldConnectionMatchWeight = 5;
const int xProfileFieldPassionMatchWeight = 5;
const int xProfileFieldStatusMatchWeight = 3;
const int xProfileFieldWantKidsMatchWeight = 6;
const int xProfileFieldMainLanguageMatchWeight = 3;
const int xProfileFieldEthnicityMatchWeight = 0;
const int xProfileFieldOftenAlcoholMatchWeight = 5;
const int xProfileFieldOftenSmokeMatchWeight = 5;
const int xProfileFieldPetsMatchWeight = 1;
const int xProfileFieldLocationMatchWeight = 3;
const int xProfileFieldFavouriteMoviesMatchWeight = 3;
const int xProfileFieldFavouriteMusicMatchWeight = 3;
const int xProfileFieldFavouriteCuisineMatchWeight = 3;
const int xProfileFieldFavouriteSweetMatchWeight = 1;
const int xProfileFieldFavouriteDrinkMatchWeight = 2;
const int xProfileFieldFavouriteSportMatchWeight = 2;
const int xProfileFieldFavouriteBooksMatchWeight = 2;
const int xProfileFieldFavouriteGamesMatchWeight = 2;
const int xProfileFieldHobbiesMatchWeight = 4;
const int xProfileFieldFutureMarriageMatchWeight = 3;
const int xProfileFieldPerfectWeekendMatchWeight = 3;
const int xProfileFieldAppetiteMatchWeight = 2;
const int xProfileFieldWhoPaysBillMatchWeight = 3;
const int xProfileFieldOftenCleaningMatchWeight = 2;
const int xProfileFieldImportanceFriendsMatchWeight = 2;
const int xProfileFieldImportanceFamilyMatchWeight = 3;
const int xProfileFieldLiveWithFutureMatchWeight = 2;
const int xProfileFieldImportantValueMatchWeight = 3;
const int xProfileFieldImportantPersonalityTraitsMatchWeight = 3;
const int xProfileFieldWorkEthicMatchWeight = 2;
const int xProfileFieldStayHomeOrGoOutMatchWeight = 2;
const int xProfileFieldStaySpendOrSaveMatchWeight = 2;
const int xProfileFieldWhatDoesFootyMeanMatchWeight = 1;
const int xProfileFieldFeelAboutCampingMatchWeight = 1;
const int xProfileFieldDoYouGambleMatchWeight = 2;
const int xProfileFieldOffendedByLanguageMatchWeight = 2;
const int xProfileFieldPotatoCakeFritterScallopMatchWeight = 1;
const int xProfileFieldClassicSongMatchWeight = 1;
const int xProfileFieldAstrologicalSignMatchWeight = 0;
const int xProfileFieldReligionMatchWeight = 2;

// Field match map.
Map<int, int> matchMap = {
  xProfileFieldConnection: xProfileFieldConnectionMatchWeight,
  xProfileFieldPassion: xProfileFieldPassionMatchWeight,
  xProfileFieldStatus: xProfileFieldStatusMatchWeight,
  xProfileFieldWantKids: xProfileFieldWantKidsMatchWeight,
  xProfileFieldMainLanguage: xProfileFieldMainLanguageMatchWeight,
  xProfileFieldEthnicity: xProfileFieldEthnicityMatchWeight,
  xProfileFieldOftenAlcohol: xProfileFieldOftenAlcoholMatchWeight,
  xProfileFieldOftenSmoke: xProfileFieldOftenSmokeMatchWeight,
  xProfileFieldPets: xProfileFieldPetsMatchWeight,
  xProfileFieldLocation: xProfileFieldLocationMatchWeight,
  xProfileFieldFavouriteMovies: xProfileFieldFavouriteMoviesMatchWeight,
  xProfileFieldFavouriteMusic: xProfileFieldFavouriteMusicMatchWeight,
  xProfileFieldFavouriteCuisine: xProfileFieldFavouriteCuisineMatchWeight,
  xProfileFieldFavouriteSweet: xProfileFieldFavouriteSweetMatchWeight,
  xProfileFieldFavouriteDrink: xProfileFieldFavouriteDrinkMatchWeight,
  xProfileFieldFavouriteSport: xProfileFieldFavouriteSportMatchWeight,
  xProfileFieldFavouriteBooks: xProfileFieldFavouriteBooksMatchWeight,
  xProfileFieldFavouriteGames: xProfileFieldFavouriteGamesMatchWeight,
  xProfileFieldHobbies: xProfileFieldHobbiesMatchWeight,
  xProfileFieldFutureMarriage: xProfileFieldFutureMarriageMatchWeight,
  xProfileFieldPerfectWeekend: xProfileFieldPerfectWeekendMatchWeight,
  xProfileFieldAppetite: xProfileFieldAppetiteMatchWeight,
  xProfileFieldWhoPaysBill: xProfileFieldWhoPaysBillMatchWeight,
  xProfileFieldOftenCleaning: xProfileFieldOftenCleaningMatchWeight,
  xProfileFieldImportanceFriends: xProfileFieldImportanceFriendsMatchWeight,
  xProfileFieldImportanceFamily: xProfileFieldImportanceFamilyMatchWeight,
  xProfileFieldLiveWithFuture: xProfileFieldLiveWithFutureMatchWeight,
  xProfileFieldImportantValue: xProfileFieldImportantValueMatchWeight,
  xProfileFieldImportantPersonalityTraits:
      xProfileFieldImportantPersonalityTraitsMatchWeight,
  xProfileFieldWorkEthic: xProfileFieldWorkEthicMatchWeight,
  xProfileFieldStayHomeOrGoOut: xProfileFieldStayHomeOrGoOutMatchWeight,
  xProfileFieldStaySpendOrSave: xProfileFieldStaySpendOrSaveMatchWeight,
  xProfileFieldWhatDoesFootyMean: xProfileFieldWhatDoesFootyMeanMatchWeight,
  xProfileFieldFeelAboutCamping: xProfileFieldFeelAboutCampingMatchWeight,
  xProfileFieldDoYouGamble: xProfileFieldDoYouGambleMatchWeight,
  xProfileFieldOffendedByLanguage: xProfileFieldOffendedByLanguageMatchWeight,
  xProfileFieldPotatoCakeFritterScallop:
      xProfileFieldPotatoCakeFritterScallopMatchWeight,
  xProfileFieldClassicSong: xProfileFieldClassicSongMatchWeight,
  xProfileFieldAstrologicalSign: xProfileFieldAstrologicalSignMatchWeight,
  xProfileFieldReligion: xProfileFieldReligionMatchWeight
};

// Character limit map.
Map<int, int> xProfileFieldCharacterLimitMap = {
  xProfileFieldWhatYouNeedToKnow: 1000,
  xProfileFieldWhatImLookingFor: 1000
};

// Additional information map.
Map<int, String> xProfileFieldAdditionalInformationMap = {};

// TODO: Update these below.
// "None" selection item field map.
// <xProfileFieldId, selectionItemXProfileFieldId>
const int xProfileFieldIDontHaveAnyHobbies = 3227;
const int xProfileFieldIDontLikeWatchingMovies = 3243;
const int xProfileFieldIDontLikeListeningToMusic = 3262;
const int xProfileFieldIDontHaveAFavouriteSweetTreat = 3292;
const int xProfileFieldIDontLikeSportsOrExercise = 3336;
const int xProfileFieldIDontLikeReading = 3355;
const int xProfileFieldIDontReallyLikeGames = 3371;
const int xProfileFieldNoPets = 3384;
Map<int, int> noneSelectionItemXProfileFieldMap = {
  xProfileFieldHobbies: xProfileFieldIDontHaveAnyHobbies,
  xProfileFieldFavouriteMovies: xProfileFieldIDontLikeWatchingMovies,
  xProfileFieldFavouriteMusic: xProfileFieldIDontLikeListeningToMusic,
  xProfileFieldFavouriteSweet: xProfileFieldIDontHaveAFavouriteSweetTreat,
  xProfileFieldFavouriteSport: xProfileFieldIDontLikeSportsOrExercise,
  xProfileFieldFavouriteBooks: xProfileFieldIDontLikeReading,
  xProfileFieldFavouriteGames: xProfileFieldIDontReallyLikeGames,
  xProfileFieldPets: xProfileFieldNoPets,
};

// Returns a predefined icon for specific XProfile fields.
IconData? getXProfileFieldDataIcon(
  int profileFieldDataId,
  String profileFieldParsedDataValue,
) {
  switch (profileFieldDataId) {
    case xProfileFieldGender:
      switch (profileFieldParsedDataValue.toLowerCase()) {
        case 'male':
          return Icons.male_rounded;
        case 'female':
          return Icons.female_rounded;
        case 'transgender':
          return Icons.transgender_rounded;
      }
    case xProfileFieldLocation:
      return Platform.isIOS ? CupertinoIcons.location_fill : Icons.location_pin;
    case xProfileFieldBirthdate:
      return Icons.cake_rounded;
    case xProfileFieldOftenSmoke:
      switch (profileFieldParsedDataValue.toLowerCase()) {
        case 'never':
          return Icons.smoke_free_rounded;
        default:
          return Icons.smoking_rooms_rounded;
      }
    case xProfileFieldOftenAlcohol:
      switch (profileFieldParsedDataValue.toLowerCase()) {
        case 'never':
          return Icons.no_drinks_rounded;
        default:
          return Icons.liquor_rounded;
      }
    case xProfileFieldOccupation:
      return Platform.isIOS
          ? CupertinoIcons.briefcase_fill
          : Icons.work_rounded;
  }
  return null;
}

// Returns a predefined text prefix for specific XProfile fields.
String? getXProfileFieldDataPrefix(
  int profileFieldDataId,
  String profileFieldParsedDataValue,
) {
  switch (profileFieldDataId) {
    case xProfileFieldLookingFor:
      return 'Looking for';
  }
  return null;
}

// TODO: Set these colours correctly (check dark mode visibility too)
Color getMatchPercentageColour(int matchWeight, bool colourCoded) {
  return colourCoded
      ? matchWeight >= 50
          ? kActionColor
          : matchWeight >= 25
              ? kBaseTriadicColour1 //TODO: This colour does not look nice in dark mode
              : kBaseColour
      : kBaseColour;
}

// TODO: Set these colours correctly (check dark mode visibility too)
Color getProfileCompletionPercentageColour(double percentage) {
  return percentage == 1
      ? kActionColor
      : percentage >= 0.5
          ? kBaseTriadicColour1 //TODO: This colour does not look nice in dark mode
          : kBaseColour;
}
