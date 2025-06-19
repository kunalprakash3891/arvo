import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_service.dart';
import 'package:arvo/views/settings/servers_list_view.dart';
import 'package:app_base/generics/get_arguments.dart';

class ServersView extends StatefulWidget {
  const ServersView({super.key});

  @override
  State<ServersView> createState() => _ServersViewState();
}

class _ServersViewState extends State<ServersView> {
  late final LocalStorageService _localStorageService;
  DatabaseServer? _currentDatabaseServer;

  @override
  void initState() {
    super.initState();
    _localStorageService = LocalStorageService.arvo();
  }

  @override
  Widget build(BuildContext context) {
    _currentDatabaseServer = context.getArgument<DatabaseServer>();

    if (_currentDatabaseServer == null) throw Exception('Invalid server.');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Servers'),
      ),
      body: StreamBuilder(
        stream: _localStorageService.allServers,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            case ConnectionState.active:
              if (snapshot.hasData) {
                final allServers = snapshot.data as Iterable<DatabaseServer>;
                return ServersListView(
                  servers: allServers,
                  currentDatabaseServer: _currentDatabaseServer!,
                  onDeleteServer: (server) async {
                    await _localStorageService.deleteServer(server.id);
                  },
                  onTap: (note) {
                    Navigator.of(context)
                        .pushNamed(createOrUpdateServerRoute, arguments: note);
                  },
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            default:
              return const Center(
                child: CircularProgressIndicator(),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.of(context).pushNamed(createOrUpdateServerRoute);
        },
        child: Icon(
          Platform.isIOS ? CupertinoIcons.add : Icons.add_rounded,
          size: 32.0,
        ),
      ),
    );
  }
}
