// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

import '../utils/youtube_player_controller.dart';

/// A widget to display the full screen toggle button.
class FullScreenButton extends StatefulWidget {
  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;

  final VoidCallback? onPressed;

  /// Defines color of the button.
  final Color color;

  /// Creates [FullScreenButton] widget.
  FullScreenButton({
    this.controller,
    this.color = CupertinoColors.white,
    this.onPressed,
  });

  @override
  _FullScreenButtonState createState() => _FullScreenButtonState();
}

class _FullScreenButtonState extends State<FullScreenButton> {
  late YoutubePlayerController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = YoutubePlayerController.of(context);
    if (controller == null) {
      assert(
        widget.controller != null,
        '\n\nNo controller could be found in the provided context.\n\n'
        'Try passing the controller explicitly.',
      );
      _controller = widget.controller!;
    } else {
      _controller = controller;
    }
    _controller.removeListener(listener);
    _controller.addListener(listener);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minSize: 0,
      child: Icon(
        _controller.value.isFullScreen
            ? CupertinoIcons.fullscreen_exit
            : CupertinoIcons.fullscreen,
        color: widget.color,
      ),
      onPressed: () => _controller.toggleFullScreenMode(),
    );
  }
}
