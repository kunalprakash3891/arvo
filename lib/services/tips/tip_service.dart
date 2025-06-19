import 'package:flutter/material.dart';
import 'package:arvo/enums/tip_type.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/tips/arvo_tip_provider.dart';
import 'package:arvo/services/tips/tip_provider.dart';

class TipService implements TipProvider {
  final TipProvider provider;
  TipService(this.provider);

  factory TipService.arvo() => TipService(ArvoTipProvider());

  @override
  Future<void> initalise(ConnectionProvider connectionProvider,
          LocalStorageProvider localStorageProvider) =>
      provider.initalise(connectionProvider, localStorageProvider);

  @override
  Future<void> loadSystemParameters() => provider.loadSystemParameters();

  @override
  Future<void> showTipOverlay(BuildContext context, TipType tipType) =>
      provider.showTipOverlay(context, tipType);

  @override
  Future<void> dismissTip(TipType tipType) => provider.dismissTip(tipType);
}
