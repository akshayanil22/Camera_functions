import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;


class TakePictureScreen extends StatefulWidget {
  final Function(List<String>) onImages;
   const TakePictureScreen({
    super.key,
   required this.onImages
  });

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> with WidgetsBindingObserver{
  CameraController? _controller;
  List<CameraDescription> camera = [];
  Future<void>? _initializeControllerFuture;
  Directory? appDocumentsDir;
  List<String> images = [];
  bool isRearCameraSelected = true;

  CameraDescription? selectedCamera;
  FlashMode? selectedFlashMode = FlashMode.auto;


  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllerFuture = initializeCamera();
  }

 Future<void> initializeCamera() async {

    try{
      appDocumentsDir = await getApplicationDocumentsDirectory();
    }catch(e){
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('did not get permission to access storage')));
      }
    }

    camera = await availableCameras();

    if(camera.isNotEmpty){
      _controller = CameraController(
        camera.first,
        ResolutionPreset.high,
      );

      selectedCamera = camera.first;
      await _controller?.initialize();

      await _controller?.setFlashMode(FlashMode.auto);

    }else{

      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No camera Found')));
      }
    }

    setState(() {});


  }



  @override
  void dispose() {
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if(state == AppLifecycleState.inactive || state == AppLifecycleState.paused){
      _controller?.dispose();
    }else if(state == AppLifecycleState.resumed){

      if(camera.isNotEmpty){
        _controller = CameraController(
          selectedCamera??camera.first,
          ResolutionPreset.high,
        );

        await _controller?.initialize();
        await _controller?.setFlashMode(selectedFlashMode??FlashMode.off);
        setState(() {});

      }else{
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No camera Found')));
        }
      }
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Photo')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          print("sahin");
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(children: [
              Expanded(child: Container(
                clipBehavior: Clip.hardEdge,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12)
                ),
                child: Stack(
                  children: [
                    CameraPreview(_controller!,
                    child: LayoutBuilder(
                        builder: (context,constraints) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              onViewFinderTap(details, constraints);
                            },
                          );
                        }
                    ),
                    ),
                    Positioned(
                        right: 12,
                        top: 12,
                        child: Row(
                          children: [
                            if(camera.length>1)
                            IconButton(onPressed: () async{
                              isRearCameraSelected?await _controller?.setDescription(camera[1]):await _controller?.setDescription(camera[0]);
                              selectedCamera = _controller?.description;
                              isRearCameraSelected = !isRearCameraSelected;
                            }, icon: SvgPicture.asset('assets/images/switch_cam.svg')),

                            ///Flash on and off Buttons
                            // IconButton(onPressed: ()async{
                            //   if(_controller?.value.flashMode==FlashMode.off){
                            //    await _controller?.setFlashMode(FlashMode.always);
                            //    selectedFlashMode = FlashMode.always;
                            //   }else if(_controller?.value.flashMode==FlashMode.always){
                            //    await _controller?.setFlashMode(FlashMode.off);
                            //    selectedFlashMode = FlashMode.off;
                            //   }
                            //   setState(() {});
                            // }, icon: SvgPicture.asset('assets/images/flash_${_controller?.value.flashMode==FlashMode.off?'off':'on'}.svg')),
                          ],
                        ))
                  ],
                ),
              )),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Badge(
                      label: Text(images.length.toString()),
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        width: 46,
                        height: 46,

                        decoration: BoxDecoration(color: const Color(0xffDDE5DA),borderRadius: BorderRadius.circular(12)),
                        child: images.isEmpty?null:Image.file(File(images.last),fit: BoxFit.cover,),
                      ),
                    ),
                  const SizedBox(width: 12,),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                        color: const Color(0xffB5F1BD),
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: IconButton(
                        icon: const Icon(Icons.camera),
                        onPressed: () async {
                          // Take the Picture in a try / catch block. If anything goes wrong,
                          // catch the error.
                          try {
                            // Ensure that the camera is initialized.
                           // await _initializeControllerFuture;

                            final image = await _controller!.takePicture();

                            if(appDocumentsDir !=null){
                              File file = File(path.join(appDocumentsDir!.path,path.basename(image.path)));
                              await file.create();
                              await file.writeAsBytes(await image.readAsBytes());
                              try{
                                File(image.path).deleteSync();
                              }catch(e){
                                //
                              }
                              setState(() {
                                images.add(file.path);
                              });
                            }else{
                              if(context.mounted){
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('did not get permission to access storage')));
                              }
                            }
                            if (!context.mounted) return;
                          } catch (e) {
                            // If an error occurs, log the error to the console.
                          }
                        }
                    ),
                  ),
                  const SizedBox(width: 12,),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: const Color(0xffDDE5DA),
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.file_upload_outlined),
                      onPressed: (){
                        if(images.isNotEmpty){
                          try{
                            widget.onImages(images);
                            Navigator.maybePop(context);
                          }catch(e){
                            //
                          }
                        }else{
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No images taken')));
                        }
                      },
                    ),
                  ),
                ],),
              const SizedBox(height: 16,)
            ],);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_controller == null) {
      return;
    }

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    _controller!.setExposurePoint(offset);
    _controller!.setFocusPoint(offset);
  }

}
