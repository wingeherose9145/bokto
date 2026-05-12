import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyPrivatePlayer());
}

class MyPrivatePlayer extends StatelessWidget {
  const MyPrivatePlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '私密播放器 Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const VideoListPage(),
    );
  }
}

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  List<File> _videoFiles = [];

  @override
  void initState() {
    super.initState();
    _loadPrivateVideos();
  }

  Future<void> _loadPrivateVideos() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> entities = directory.listSync();
    if (!mounted) return;
    setState(() {
      _videoFiles = entities
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4') || f.path.endsWith('.mkv') || f.path.endsWith('.avi'))
          .toList();
    });
  }

  Future<void> _importVideos() async {
    // 适配最新版 file_picker 的写法
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null) {
      final directory = await getApplicationDocumentsDirectory();
      for (var path in result.paths) {
        if (path != null) {
          final file = File(path);
          final String newPath = '${directory.path}/${file.uri.pathSegments.last}';
          await file.copy(newPath);
        }
      }
      _loadPrivateVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的私密库 Pro'),
        actions: [
          IconButton(onPressed: _importVideos, icon: const Icon(Icons.add_to_photos)),
        ],
      ),
      body: _videoFiles.isEmpty
          ? const Center(child: Text('点击右上角导入视频'))
          : ListView.builder(
              itemCount: _videoFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.video_file, color: Colors.blueAccent),
                  title: Text(_videoFiles[index].uri.pathSegments.last),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerPage(
                          videoFiles: _videoFiles,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class PlayerPage extends StatefulWidget {
  final List<File> videoFiles;
  final int initialIndex;

  const PlayerPage({super.key, required this.videoFiles, required this.initialIndex});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initPlayer(); // <--- 关键初始化函数
  }

  // 这是被“弄丢”的初始化函数，确保它存在
  Future<void> _initPlayer() async {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    final controller = VideoPlayerController.file(widget.videoFiles[_currentIndex]);
    await controller.initialize();

    final chewie = ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: true,
      showControls: true,
      aspectRatio: controller.value.aspectRatio,
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
    );

    controller.addListener(() {
      if (controller.value.position != Duration.zero &&
          controller.value.position == controller.value.duration) {
        _playNext();
      }
    });

    if (mounted) {
      setState(() {
        _videoPlayerController = controller;
        _chewieController = chewie;
      });
    }
  }

  void _playNext() {
    if (_currentIndex < widget.videoFiles.length - 1) {
      _currentIndex++;
      _initPlayer();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: (_chewieController != null && _videoPlayerController != null && _videoPlayerController!.value.isInitialized)
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(),
      ),
    );
  }
}