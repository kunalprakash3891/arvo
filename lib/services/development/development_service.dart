import 'package:arvo/services/development/development_provider.dart';
import 'package:arvo/services/development/arvo_development_provider.dart';

class DevelopmentService implements DevelopmentProvider {
  final DevelopmentProvider provider;
  DevelopmentService(this.provider);

  factory DevelopmentService.arvo() =>
      DevelopmentService(ArvoDevelopmentProvider());

  @override
  bool get isDevelopment => provider.isDevelopment ?? false;

  @override
  set isDevelopment(bool? value) => provider.isDevelopment = value;
}
