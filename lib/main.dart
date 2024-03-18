import 'package:flutter/material.dart';
import 'package:take_picture/take_picture.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return  TakePictureScreen(onImages: (images){},);
                },));
              },
            ),
            IconButton(
              icon: const Icon(Icons.video_camera_back_rounded),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return  TakePictureScreen(isVideo: true,onImages: (images){},);
                },));
              },
            ),
          ],
        ),
      ),
    );
  }
}

