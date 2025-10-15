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
// TODO: Update the default avatar on the website. Note: Release app first before updating on website, ensure app check for both old and new.
//const updatedDefaultAvatarURL = "?";
const defaultAvatarURL = "/wp-content/uploads/2024/02/arvo-avatar.png";
const faqsURL = "/faq/";
const lostPasswordURL = "/wp-login.php?action=lostpassword";

const userIdKunal = 4;

// System Users Map
Map<String, List<int>> systemUsersMap = {
  arvoURL: [
    2, // 4rv0da7ing
  ],
  arvoTestURL: [
    2, // 4rv0da7ing
  ],
};

// Arvo Team Member Map
Map<String, List<int>> teamMemberUsersMap = {
  // TODO: Hide team member users.
  arvoURL: [
    4, // Kunal
    9, // Susan
  ],
  arvoTestURL: [
    4, // Kunal
    9, // Susan
  ],
};

// Demo Users Map
Map<String, List<int>> demoUsersMap = {
  arvoURL: [
    8, // App Demo
    7, // Hamish
    10, // Jolene
    11, // Monti
    12, // Kerry
    13, // Stephen
    14, // Celeste
    15, // Ryan
  ],
  arvoTestURL: [
    8, // App Demo
    7, // Hamish
    10, // Jolene
    11, // Monti
    12, // Kerry
    13, // Stephen
    14, // Celeste
    15, // Ryan
  ],
};

// Restricted Messaging Users Map
Map<String, List<int>> restrictedMessagingUsersMap = {
  arvoURL: [
    8, // App Demo
  ],
  arvoTestURL: [
    8, // App Demo
  ],
};

// Contributors Map
Map<String, List<int>> contributorsMap = {
  arvoURL: [],
  arvoTestURL: [],
};
