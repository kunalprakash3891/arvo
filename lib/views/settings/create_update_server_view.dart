import 'package:flutter/material.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_service.dart';
import 'package:app_base/generics/get_arguments.dart';

class CreateUpdateServerView extends StatefulWidget {
  const CreateUpdateServerView({super.key});

  @override
  State<CreateUpdateServerView> createState() => _CreateUpdateServerViewState();
}

class _CreateUpdateServerViewState extends State<CreateUpdateServerView> {
  DatabaseServer? _server;
  late final LocalStorageService _localStorageService;
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _localStorageService = LocalStorageService.arvo();
    _textEditingController = TextEditingController();
  }

  // Periodically save the server URL text as user is typing.
  void _textControllerListener() async {
    final server = _server;
    if (server == null) {
      return;
    }
    server.url = _textEditingController.text;
    await _localStorageService.updateServer(server);
  }

  void _setUpTextControllerListener() {
    _textEditingController.removeListener(_textControllerListener);
    _textEditingController.addListener(_textControllerListener);
  }

  Future<DatabaseServer> _createOrGetExistingServer(
      BuildContext context) async {
    final widgetServer = context.getArgument<DatabaseServer>();

    // If there is an existing server passed by the calling widget, load it and return.
    if (widgetServer != null) {
      _server = widgetServer;
      _textEditingController.text = widgetServer.url;
      return widgetServer;
    }

    final existingServer = _server;
    if (existingServer != null) {
      return existingServer;
    }

    final newServer = await _localStorageService.createServer('', '');
    _server = newServer;
    return newServer;
  }

  void _deleteServerIfTextIsEmpty() {
    final server = _server;
    if (_textEditingController.text.trim().isEmpty && server != null) {
      _localStorageService.deleteServer(server.id);
    }
  }

  void _saveServerIfTextNotEmpty() async {
    final server = _server;
    final text = _textEditingController.text;
    if (server != null && text.trim().isNotEmpty) {
      await _localStorageService.updateServer(server);
    }
  }

  @override
  void dispose() {
    _deleteServerIfTextIsEmpty();
    _saveServerIfTextNotEmpty();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Server'),
      ),
      body: FutureBuilder(
        future: _createOrGetExistingServer(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setUpTextControllerListener();
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _textEditingController,
                  keyboardType: TextInputType.multiline,
                  // Make the editor expand as lines are entered.
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                  ),
                ),
              );
            default:
              return const Center(
                child: CircularProgressIndicator(),
              );
          }
        },
      ),
    );
  }
}
