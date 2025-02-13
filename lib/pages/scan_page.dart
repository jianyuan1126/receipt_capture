import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'dart:io';
import '../database/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isRearCameraSelected = true;
  FlashMode _flashMode = FlashMode.auto;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _disposeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

  Future<void> _initCamera() async {
    try {
      debugPrint('Requesting camera permission...');
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        debugPrint('Camera permission denied');
        return;
      }

      debugPrint('Getting available cameras...');
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras found');
        return;
      }

      await _disposeCamera();
      
      debugPrint('Initializing camera...');
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        debugPrint('Camera initialized successfully');
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    
    try {
      FlashMode nextMode;
      switch (_flashMode) {
        case FlashMode.auto:
          nextMode = FlashMode.always;
          break;
        case FlashMode.always:
          nextMode = FlashMode.off;
          break;
        default:
          nextMode = FlashMode.auto;
      }
      
      await _controller!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) return;

      final newCameraIndex = _isRearCameraSelected ? 1 : 0;
      final newCamera = cameras[newCameraIndex];
      
      await _disposeCamera();
      
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isRearCameraSelected = !_isRearCameraSelected;
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview with aspect ratio
          Container(
            width: double.infinity,
            height: double.infinity,
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // Overlay UI
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black26,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Scan Receipt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _flashMode == FlashMode.always
                              ? Icons.flash_on
                              : _flashMode == FlashMode.off
                                  ? Icons.flash_off
                                  : Icons.flash_auto,
                          color: Colors.white,
                        ),
                        onPressed: _toggleFlash,
                      ),
                    ],
                  ),
                ),

                // Bottom controls
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.black26,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      IconButton(
                        icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                        onPressed: _pickFromGallery,
                      ),
                      // Capture button
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: Colors.white24,
                          ),
                          child: Center(
                            child: Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Switch camera button
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 32),
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing Image...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    if (!_controller!.value.isInitialized) {
      debugPrint('Camera not initialized');
      return;
    }

    try {
      debugPrint('Taking picture...');
      final XFile image = await _controller!.takePicture();
      debugPrint('Picture taken: ${image.path}');

      final Directory appDir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final timeStr = DateFormat('HH:mm:ss').format(now);
      final filename = 'scan_${now.millisecondsSinceEpoch}.jpg';
      final File newImage = File(path.join(appDir.path, filename));
      await File(image.path).copy(newImage.path);
      debugPrint('Image saved locally: ${newImage.path}');

      final fileSize = await newImage.length();

      // Upload and get API response
      String apiResponse = '';
      try {
        apiResponse = await ApiService.submitImage(newImage);
        debugPrint('API Response received');
      } catch (e) {
        debugPrint('API Error: $e');
        apiResponse = 'Error: $e';
      }

      // Save to database
      await DatabaseHelper.instance.insertScan(
        filename: filename,
        location: 'Unknown',
        date: dateStr,
        time: timeStr,
        fileSize: fileSize,
        apiReturnCode: apiResponse,
      );
      debugPrint('Saved to database');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image captured and processed')),
        );
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      
      if (image == null) {
        debugPrint('No image selected');
        return;
      }

      debugPrint('Image picked: ${image.path}');

      final Directory appDir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final timeStr = DateFormat('HH:mm:ss').format(now);
      final filename = 'scan_${now.millisecondsSinceEpoch}.jpg';
      final File newImage = File(path.join(appDir.path, filename));
      await File(image.path).copy(newImage.path);
      debugPrint('Image saved locally: ${newImage.path}');

      final fileSize = await newImage.length();

      // Upload and get API response
      String apiResponse = '';
      try {
        apiResponse = await ApiService.submitImage(newImage);
        debugPrint('API Response received');
      } catch (e) {
        debugPrint('API Error: $e');
        apiResponse = 'Error: $e';
      }

      // Save to database
      await DatabaseHelper.instance.insertScan(
        filename: filename,
        location: 'Unknown',
        date: dateStr,
        time: timeStr,
        fileSize: fileSize,
        apiReturnCode: apiResponse,
      );
      debugPrint('Saved to database');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image processed successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
} 