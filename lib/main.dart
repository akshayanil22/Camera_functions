import 'dart:async';
import 'package:flutter/material.dart';
import 'package:take_picture/take_picture.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      theme: ThemeData.light(),
      home: const HomeScreen())
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: (){
            print('pressed');
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return  TakePictureScreen(onImages: (images){
                print(images.length);
              },);
            },)).then((value) {
              print(value);
            });
          },
        ),
      ),
    );
  }
}

