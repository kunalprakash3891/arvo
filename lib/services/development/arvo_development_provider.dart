import 'package:arvo/services/development/development_provider.dart';

class ArvoDevelopmentProvider implements DevelopmentProvider {
  // create as singleton
  static final _shared = ArvoDevelopmentProvider._sharedInstance();
  ArvoDevelopmentProvider._sharedInstance();
  factory ArvoDevelopmentProvider() => _shared;

  // NOTE: Set to false for production release.
  @override
  bool? isDevelopment = true;
}
