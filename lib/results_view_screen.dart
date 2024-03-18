import 'dart:io';
import 'package:flutter/material.dart';
import 'package:take_picture/video_player_screen.dart';

import 'image_view_screen.dart';

class ResultsViewScreen extends StatefulWidget {
  final bool isVideo;
  final List<String> result;

  const ResultsViewScreen({super.key,required this.isVideo, required this.result});

  @override
  State<ResultsViewScreen> createState() => _ResultsViewScreenState();
}

class _ResultsViewScreenState extends State<ResultsViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isVideo?'Videos':'Photos')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.result.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0
        ),
        itemBuilder: (context, index) {
          // return Image.file(File(widget.result[index]));
          return GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => widget.isVideo?VideoPlayerScreen(videoFile: widget.result[index]):ImageViewScreen(image: widget.result[index],),));
            },
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffDDE5DA),
                    borderRadius: BorderRadius.circular(6),
                    image: DecorationImage(image: FileImage(File(widget.isVideo?(widget.result[index].split('.${widget.result[index].split(".").removeLast()}').join('.png')):widget.result[index])),fit: BoxFit.cover)
                  ),
                ),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(6),topRight: Radius.circular(6)),
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0),
                    ])
                  ),
                ),
                Align(
                    alignment: Alignment.topRight,
                    child:InkWell(
                        onTap: (){
                          try{
                            if(widget.isVideo){
                              File((widget.result[index].split('.${widget.result[index].split(".").removeLast()}').join('.png'))).deleteSync();
                            }
                            File(widget.result[index]).deleteSync();
                          }catch(e){
                            //
                          }
                          widget.result.removeAt(index);
                          setState(() {});
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.close,color: Colors.white,),
                        )))
              ],
            ),
          );
        },
      ),
    );
  }
}
