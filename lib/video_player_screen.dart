import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';


class VideoPlayerScreen extends StatefulWidget {

  final String videoFile;

  const VideoPlayerScreen({super.key,required this.videoFile});

  @override
  VideoPlayerScreenState createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoFile))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
    _controller.addListener(() {

      if(_controller.value.isCompleted){
        setState(() {});
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Video',style: TextStyle(color: Colors.white)),backgroundColor: Colors.black,foregroundColor: Colors.white,),
      body: Column(
        children: [
          Expanded(child: _controller.value.isInitialized
              ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
              : Container(),),
          const SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                IconButton(
                    icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow,color: Colors.white,),
                    onPressed: (){
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    }
                ),
                Expanded(child: VideoProgressIndicator(_controller, allowScrubbing: true,colors: const VideoProgressColors(playedColor: Colors.white,backgroundColor: Color(0xff2E2E2E),bufferedColor: Colors.transparent),)),
                const SizedBox(width: 16,)
              ],
            ),
          ),
          const SizedBox(height: 10,),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}