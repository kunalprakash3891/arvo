import 'package:age_calculator/age_calculator.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:nifty_three_bp_app_base/extensions/string.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:app_base/extensions/string_extensions.dart';

void populateMemberProfileCompletionPercentage(Member member) {
  int totalMemberProfileFieldsCount = 0;
  int memberProfileFieldsCompletedCount = 0;
  double totalPointsPhoto = 0.1;

  if (member.xProfile == null) return;

  member.profileGroupCompletionPercentage = {};

  for (final group in member.xProfile!.groups) {
    int totalMemberProfileGroupFieldsCount = 0;
    int memberProfileGroupFieldsCompletedCount = 0;

    for (final field in group.fields) {
      totalMemberProfileFieldsCount++;
      totalMemberProfileGroupFieldsCount++;

      if (field.value == null) continue;

      if (field.value!.unserialized!.isNotEmpty) {
        memberProfileFieldsCompletedCount++;
        memberProfileGroupFieldsCompletedCount++;
      }
    }
    member.profileGroupCompletionPercentage[group.id] =
        memberProfileGroupFieldsCompletedCount /
            totalMemberProfileGroupFieldsCount;
  }

  var memberPercentagePhoto =
      memberHasDefaultAvatar(member.avatar?.thumb) ? 0 : totalPointsPhoto;

  var completedPercentage =
      ((memberProfileFieldsCompletedCount / totalMemberProfileFieldsCount) -
              totalPointsPhoto) +
          memberPercentagePhoto;

  // Check that the percentage is greater than equal to 0, otherwise set it to 0.
  member.profileCompletionPercentage =
      completedPercentage >= 0 ? completedPercentage : 0;
}

void populateMemberAgeGenderLocation(Member member) {
  if (member.xProfile == null) return;

  var aboutMeMemberFieldGroup = member.xProfile?.groups
      .where((group) => group.id == xProfileGroupAboutMe)
      .first;

  if (aboutMeMemberFieldGroup == null) return;

  var birthdateField = aboutMeMemberFieldGroup.fields
      .where((memberFields) => memberFields.id == xProfileFieldBirthdate)
      .first;

  if (birthdateField.value != null &&
      birthdateField.value!.raw != null &&
      birthdateField.value!.raw!.isNotEmpty) {
    var birthdate = DateTime.parse(birthdateField.value!.raw!);
    member.age = AgeCalculator.age(birthdate).years;
  }

  var genderField = aboutMeMemberFieldGroup.fields
      .where((memberFields) => memberFields.id == xProfileFieldGender)
      .first;

  if (genderField.value != null &&
      genderField.value!.raw != null &&
      genderField.value!.raw!.isNotEmpty) {
    member.gender = genderField.value!.raw!;
  }

  var locationField = aboutMeMemberFieldGroup.fields
      .where((memberFields) => memberFields.id == xProfileFieldLocation)
      .first;

  if (locationField.value != null &&
      locationField.value!.unserialized != null &&
      locationField.value!.unserialized!.isNotEmpty) {
    member.location = locationField.value!.unserialized!.first
        .removeEscapeCharacters()
        .parseHTML();
  }
}

void populateMatchPercentage(Member currentUser, Member member) {
  int matchResult = 0;
  List<int> matchedFields = [];

  try {
    for (final group in member.xProfile!.groups) {
      for (final field in group.fields) {
        var fieldValue = matchMap[field.id];
        if (fieldValue != null) {
          for (final myGroup in currentUser.xProfile!.groups) {
            for (final myField in myGroup.fields) {
              if (myField.id == field.id) {
                if (myField.value!.raw != null &&
                    myField.value!.raw!.isNotEmpty &&
                    field.value!.raw != null &&
                    field.value!.raw!.isNotEmpty) {
                  // If there is a direct match, add to result, otherwise iterate through unserialized list to find matches.
                  if (myField.value!.raw == field.value!.raw) {
                    matchResult += fieldValue;
                    matchedFields.add(myField.id);
                  } else {
                    for (final myItem in myField.value!.unserialized!) {
                      bool found = false;
                      for (final fieldItem in field.value!.unserialized!) {
                        if (myItem == fieldItem) {
                          matchResult += fieldValue;
                          matchedFields.add(myField.id);
                          found = true;
                          break;
                        }
                      }
                      if (found) {
                        break;
                      }
                    }
                  }
                }
                break;
              }
            }
          }
        }
      }
    }
  } on Exception catch (_) {
    matchResult = 0;
  }

  member.matchWeight = matchResult;
  member.matchedFields = matchedFields;
}

void populateLastActivity(Member member) {
  if (member.lastActivity == null) return;

  // Add 'Z' to denote time is in GMT/UTC
  member.lastActivityTimestamp =
      DateTime.parse('${member.lastActivity!.dateGmt}Z').toLocal();
}
