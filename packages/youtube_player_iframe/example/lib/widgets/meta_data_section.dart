// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

///
class MetaDataSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return YoutubeValueBuilder(
      buildWhen: (o, n) => o.metaData != n.metaData,
      builder: (context, value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Text('Title', value.metaData.title),
            const SizedBox(height: 10),
            _Text('Channel', value.metaData.author),
            const SizedBox(height: 10),
            _Text(
              'Playback Quality',
              value.playbackQuality ?? '',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Text('Video Id', value.metaData.videoId),
                const Spacer(),
                const _Text(
                  'Speed',
                  '',
                ),
                YoutubeValueBuilder(
                  builder: (context, value) {
                    return DropdownButton(
                      value: value.playbackRate,
                      isDense: true,
                      underline: const SizedBox(),
                      items: PlaybackRate.all
                          .map(
                            (rate) => DropdownMenuItem(
                              child: Text(
                                '${rate}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              value: rate,
                            ),
                          )
                          .toList(),
                      onChanged: (double? newValue) {
                        if (newValue != null) {
                          context.ytController.setPlaybackRate(newValue);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Text extends StatelessWidget {
  final String title;
  final String value;

  const _Text(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$title : ',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
