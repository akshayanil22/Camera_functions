import 'dart:io';

import 'package:flutter/material.dart';

class ImageViewScreen extends StatelessWidget {

  final String image;

  const ImageViewScreen({super.key,required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Photo",style: TextStyle(color: Colors.white)),backgroundColor: Colors.black,foregroundColor: Colors.white,),
      body: Center(child: Image.file(File(image),fit: BoxFit.contain,),),
    );
  }
}
