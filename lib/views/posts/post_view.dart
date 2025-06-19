import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:nifty_three_bp_app_base/api/post.dart';
import 'package:app_base/generics/get_arguments.dart';
import 'package:app_base/widgets/back_to_top_widget.dart';
import 'package:share_plus/share_plus.dart';

class PostView extends StatefulWidget {
  const PostView({super.key});

  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  Post? _post;
  late final ScrollController _scrollController;
  late final ValueNotifier<bool> _backToTopButtonVisible;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _backToTopButtonVisible = ValueNotifier(false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _backToTopButtonVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _post = context.getArgument<Post>();

    if (_post == null) throw Exception('Invalid post.');

    _scrollController.addListener(() {
      //Back to top botton will show on scroll offset.
      if (mounted) {
        _backToTopButtonVisible.value = _scrollController.offset > 10.0;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_post!.title.rendered!),
        actions: [
          _post!.link == null || _post!.link!.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  onPressed: () async {
                    Share.share(_post!.link!);
                  },
                  icon: Icon(Platform.isIOS
                      ? CupertinoIcons.share
                      : Icons.share_rounded),
                ),
        ],
      ),
      floatingActionButton: buildBackToTopFloatingButtonWidget(
        _backToTopButtonVisible,
        _scrollController,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            top: 8.0,
            right: 8.0,
            bottom: 96.0,
          ),
          child: Column(
            children: [
              Center(
                child: _post!.featuredMedia == 0
                    ? const SizedBox.shrink()
                    : CachedNetworkImage(
                        imageUrl: _post!.featuredMediaURL!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Icon(Platform.isIOS
                                ? CupertinoIcons.xmark_rectangle_fill
                                : Icons.image_not_supported_rounded),
                          ),
                        ),
                      ),
              ),
              Html(data: _post!.content.rendered!, style: {
                // Style to remove underlined hyperlinks.
                'a': Style(
                  textDecoration: TextDecoration.none,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              }),
            ],
          ),
        ),
      ),
    );
  }
}
