import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart';


class TakePictureScreen extends StatefulWidget {
  final Function(List<String>) onImages;
  final bool isVideo;
   const TakePictureScreen({
    super.key,
   required this.onImages,
     this.isVideo = false,
  });

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> with WidgetsBindingObserver{
  CameraController? _controller;
  List<CameraDescription> camera = [];
  Directory? appDocumentsDir;
  List<String> images = [];
  bool isRearCameraSelected = true;
  bool showOpenApp = false;

  CameraDescription? selectedCamera;
  FlashMode? selectedFlashMode = FlashMode.auto;


  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();
  }

 Future<void> initializeCamera() async {

    try{
      appDocumentsDir = await getApplicationDocumentsDirectory();
    }catch(e){
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('did not get permission to access storage')));
      }
    }

   try{


     camera = await availableCameras();

     if(camera.isNotEmpty){

       showOpenApp = false;
       _initializeCameraController(camera.first);

     }else{

       if(mounted){
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No camera Found')));
       }
     }


   }catch(e){
      //
   }
    setState(() {});


  }


  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
    );

    _controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          if(mounted){
            await customShowDialog(title: 'Camera').then((value) async {
              if(value!=null) {
                await openAppSettings();
              }

            });
          }
          showOpenApp =true;
          showInSnackBar('You have denied camera access.');
        case 'CameraAccessDeniedWithoutPrompt':
        // iOS only
          showInSnackBar('Please go to Settings app to enable camera access.');
        case 'CameraAccessRestricted':
        // iOS only
          showInSnackBar('Camera access is restricted.');
        case 'AudioAccessDenied':
          if(mounted){
            await customShowDialog(title: 'Microphone').then((value) async {
              if(value!=null) {
                await openAppSettings();
              }

            });
          }
          showOpenApp =true;
          showInSnackBar('You have denied audio access.');
        case 'AudioAccessDeniedWithoutPrompt':
        // iOS only
          showInSnackBar('Please go to Settings app to enable audio access.');
        case 'AudioAccessRestricted':
        // iOS only
          showInSnackBar('Audio access is restricted.');
        default:
          _showCameraException(e);
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<dynamic> customShowDialog({required String title}) {
    return showDialog(context: context, builder: (context) {
            return AlertDialog(
              icon: const Icon(Icons.settings),
              title: Text("Turn on $title permission"),
              content: Text('The $title permission is require while using the app.'),
              actions: [
                TextButton(onPressed: () async {
                  Navigator.pop(context);
                }, child: const Text("Cancel")),
                TextButton(onPressed: () async {
                  Navigator.pop(context,true);
                }, child: const Text("Settings"))
              ],
            );
          },);
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCameraException(CameraException e) {
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  @override
  void dispose() {
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController1 = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController1 == null || !cameraController1.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController1.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController1.description);

      if(camera.isNotEmpty){
        _initializeCameraController(selectedCamera??camera.first);
      }

    }
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController? oldController = _controller;
    if (oldController != null) {
      _controller = null;
      await oldController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(widget.isVideo?'Video':'Photo')),
      body: (_controller!=null && _controller!.value.isInitialized)?Column(children: [
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
                  child: images.isEmpty?null:Image.file(File(widget.isVideo?(images.last.split('.${images.last.split(".").removeLast()}').join('.png')):images.last),fit: BoxFit.cover,),
                ),
              ),
              const SizedBox(width: 12,),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: _controller!.value.isRecordingVideo?Colors.redAccent:const Color(0xffB5F1BD),
                    borderRadius: BorderRadius.circular(15)
                ),
                child: widget.isVideo?
                    IconButton(
                    icon: Icon(_controller!.value.isRecordingVideo?Icons.stop_circle_outlined:Icons.video_camera_back),
                    onPressed: () async {
                      try {

                        if(_controller!.value.isRecordingVideo){
                          final video = await _controller!.stopVideoRecording();
                          if(appDocumentsDir !=null){
                            File file = File(path.join(appDocumentsDir!.path,path.basename(video.path)));
                            await file.create();
                            await file.writeAsBytes(await video.readAsBytes());
                            try{
                              await VideoThumbnail.thumbnailFile(video: file.path);
                            }catch(e){
                              //
                            }
                            try{
                              File(video.path).deleteSync();
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
                        }else{
                          _controller?.startVideoRecording();
                        }
                        if (!context.mounted) return;
                      } catch (e) {
                        // If an error occurs, log the error to the console.
                      }
                    }
                )
                    :IconButton(
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
                child: _controller!.value.isRecordingVideo?
                IconButton(onPressed: (){
                  if(_controller!.value.isRecordingPaused){
                    _controller!.resumeVideoRecording();
                  }else{
                    _controller!.pauseVideoRecording();
                  }
                }, icon: Icon(_controller!.value.isRecordingPaused?Icons.fiber_manual_record:Icons.pause_circle_outline_rounded,color: _controller!.value.isRecordingPaused?Colors.red:Colors.black,))
                    :IconButton(
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No ${widget.isVideo?"video":"image"} taken')));
                    }
                  },
                ),
              ),
            ],),
          const SizedBox(height: 16,)
      ],):showOpenApp?Center(
        child: TextButton(onPressed: () async {
          await openAppSettings();
        }, child: const Text("Open Settings")),
      ):const Center(child: CircularProgressIndicator()),
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
