import 'package:flutter/material.dart';
import 'package:arvo/enums/tip_type.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';

abstract class TipProvider {
  Future<void> initalise(ConnectionProvider connectionProvider,
      LocalStorageProvider localStorageProvider);
  Future<void> loadSystemParameters();
  Future<void> showTipOverlay(BuildContext context, TipType tipType);
  Future<void> dismissTip(TipType tipType);
}
