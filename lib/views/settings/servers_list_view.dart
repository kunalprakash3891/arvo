import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:app_base/dialogs/delete_dialog.dart';
import 'package:app_base/dialogs/error_dialog.dart';

// This servers view should not have any connection with the storage service
// (should not leak services everywhere).

typedef ServerCallback = void Function(DatabaseServer server);

class ServersListView extends StatelessWidget {
  final Iterable<DatabaseServer> servers;
  final DatabaseServer currentDatabaseServer;
  final ServerCallback onDeleteServer;
  final ServerCallback onTap;
  const ServersListView({
    super.key,
    required this.servers,
    required this.currentDatabaseServer,
    required this.onDeleteServer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: servers.length,
      itemBuilder: (context, index) {
        final server = servers.elementAt(index);
        return ListTile(
          onTap: () async {
            if (server.url == arvoURL) {
              await showErrorDialog(
                context,
                text: 'This server cannot be modified.',
              );
              return;
            } else if (server.url == currentDatabaseServer.url) {
              await showErrorDialog(
                context,
                text:
                    'You have selected this as your current server, so it cannot be modified. Please switch to another server first.',
              );
              return;
            }
            onTap(server);
          },
          title: Text(
            server.url,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(Platform.isIOS
                ? CupertinoIcons.delete_solid
                : Icons.delete_rounded),
            onPressed: () async {
              if (server.url == arvoURL) {
                await showErrorDialog(
                  context,
                  text: 'This server cannot be deleted.',
                );
                return;
              } else if (server.url == currentDatabaseServer.url) {
                await showErrorDialog(
                  context,
                  text:
                      'You have selected this as your current server, so it cannot be deleted. Please switch to another server first.',
                );
                return;
              }
              if (context.mounted) {
                final shouldDelete = await showDeleteDialog(context: context);
                if (shouldDelete) {
                  onDeleteServer(server);
                }
              }
            },
          ),
        );
      },
    );
  }
}
