import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:socially_app/services/reels/reel_service.dart';
import 'package:socially_app/services/reels/reel_storage.dart';

// --- Theme Colors ---
const mainPurpleColor = Color(0xFFC913B9);
const mainOrangeColor = Color(0xFFF9373F);
const mobileBackgroundColor = Color.fromRGBO(0, 0, 0, 1);

class AddReelModal extends StatefulWidget {
  const AddReelModal({Key? key}) : super(key: key);

  @override
  _AddReelModalState createState() => _AddReelModalState();
}

class _AddReelModalState extends State<AddReelModal> {
  final _captionController = TextEditingController();
  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isUploading = false;

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      // කලින් තිබූ controller එක විනාශ කිරීම
      await _videoController?.dispose();

      setState(() {
        _videoFile = File(pickedFile.path);
        _videoController = VideoPlayerController.file(_videoFile!)
          ..initialize().then((_) {
            setState(() {});
            _videoController?.play();
            _videoController?.setLooping(true);
          });
      });
    }
  }

  void _submitReel() async {
    if (_videoFile != null && _captionController.text.isNotEmpty) {
      try {
        setState(() => _isUploading = true);
        if (kIsWeb) return;

        // Video එක Storage එකට Upload කිරීම
        final videoUrl = await ReelStorageService().uploadVideo(
          videoFile: _videoFile!,
        );

        // Reel එකේ දත්ත Database එකේ සුරැකීම
        final reelDetails = {
          'caption': _captionController.text,
          'videoUrl': videoUrl,
          'createdAt': DateTime.now(),
        };

        await ReelService().saveReel(reelDetails);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reel published successfully!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post reel. Please try again.'),
          ),
        );
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video and write a caption'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 15,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: mobileBackgroundColor.withOpacity(0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Handle
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 25),

                // Video Preview Area (Fitted Cover)
                Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: _videoFile != null
                          ? mainOrangeColor.withOpacity(0.3)
                          : Colors.white10,
                      width: 1.5,
                    ),
                    boxShadow: _videoFile != null
                        ? [
                            BoxShadow(
                              color: mainPurpleColor.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child:
                        _videoController != null &&
                            _videoController!.value.isInitialized
                        ? Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _videoController!.value.size.width,
                                  height: _videoController!.value.size.height,
                                  child: VideoPlayer(_videoController!),
                                ),
                              ),
                              // Glassy Play/Pause Button
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _videoController!.value.isPlaying
                                        ? _videoController!.pause()
                                        : _videoController!.play();
                                  });
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Colors.black26,
                                    child: Icon(
                                      _videoController!.value.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 45,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          mainPurpleColor,
                                          mainOrangeColor,
                                        ],
                                      ).createShader(bounds),
                                  child: const Icon(
                                    Icons.movie_creation_outlined,
                                    size: 65,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Video Preview",
                                  style: TextStyle(
                                    color: Colors.white24,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Caption Input (Modern Glassy Style)
                TextField(
                  controller: _captionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Write a catchy caption...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.all(18),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: mainPurpleColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Buttons
                _buildThemeButton(
                  text: 'Select Video from Gallery',
                  icon: Icons.video_library_rounded,
                  isGradient: false,
                  onPressed: _pickVideo,
                ),
                const SizedBox(height: 12),

                _buildThemeButton(
                  text: _isUploading ? 'Publishing...' : 'Publish Reel',
                  icon: Icons.rocket_launch_rounded,
                  isGradient: true,
                  isLoading: _isUploading,
                  onPressed: _isUploading ? () {} : _submitReel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Common Theme Button UI
  Widget _buildThemeButton({
    required String text,
    required IconData icon,
    required bool isGradient,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: isGradient
            ? const LinearGradient(
                colors: [mainPurpleColor, mainOrangeColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isGradient ? null : Colors.white.withOpacity(0.08),
        border: isGradient ? null : Border.all(color: Colors.white10),
        boxShadow: isGradient
            ? [
                BoxShadow(
                  color: mainPurpleColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, color: Colors.white, size: 22),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
