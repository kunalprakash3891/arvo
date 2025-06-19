class DatabaseAlreadyOpenException implements Exception {}

class UnableToGetDocumentsDirectoryException implements Exception {}

class UnableToGetApplicationSupportDirectoryException implements Exception {}

class DatabaseIsNotOpenException implements Exception {}

// server
class ServerAlreadyExistsException implements Exception {}

class CouldNotFindServerException implements Exception {}

class CouldNotUpdateServerException implements Exception {}

class CouldNotDeleteServerException implements Exception {}

// system_setting
class SystemSettingAlreadyExistsException implements Exception {}

class CouldNotFindSystemSettingException implements Exception {}

class CouldNotUpdateSystemSettingException implements Exception {}

class CouldNotDeleteSystemSettingException implements Exception {}

// user_setting
class UserSettingAlreadyExistsException implements Exception {}

class CouldNotFindUserSettingException implements Exception {}

class CouldNotUpdateUserSettingException implements Exception {}

class CouldNotDeleteUserSettingException implements Exception {}
