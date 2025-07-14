// arvo URLs
const arvoURL = 'https://www.arvo.dating';
const arvoTestURL = 'https://wordpress-888295-3079813.cloudwaysapps.com';
const arvoDomain = 'arvo.dating';
const arvoTestDomain = 'wordpress-888295-3079813.cloudwaysapps.com';
const registerURL = "/register/";
const contactUsURL = "/contact/";
const termsAndConditionsURL = "/policies/terms-conditions/";
const privacyPolicyURL = "/policies/privacy-policy/";
const onlineSafetyTipsURL = "/online-safety-tips/";
// TODO: Set website to use rounded photo for user default avatar.
// TODO: Test by creating a new user
// TODO: Test default photo is assigned properly when deleting photos.
// TODO: This default avatar may need to be updated as it shows account as verified when it is not.
const defaultAvatarURL = "/wp-content/uploads/2024/02/arvo-avatar.png";
const faqsURL = "/faq/";
const lostPasswordURL = "/wp-login.php?action=lostpassword";
const profilePhotoTipsURL =
    "/news/picture-perfect-how-to-take-great-photos-for-your-dating-profile/";

const userIdKunal = 29;

// System Users Map
Map<String, List<int>> systemUsersMap = {
  arvoURL: [
    2, // 4rv0da7ing
  ],
  arvoTestURL: [],
};

// Demo Users Map
Map<String, List<int>> demoUsersMap = {
  arvoURL: [],
  arvoTestURL: [],
};

// Restricted Messaging Users Map
Map<String, List<int>> restrictedMessagingUsersMap = {
  arvoURL: [],
  arvoTestURL: [],
};

// Contributors Map
Map<String, List<int>> contributorsMap = {
  arvoURL: [],
  arvoTestURL: [],
};
