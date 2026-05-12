import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 锁定初始方向为竖屏
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
      theme: ThemeData.dark(useMaterial3: true), // 电影感深色主题
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

  // 加载 App 内部私密目录下的视频
  Future<void> _loadPrivateVideos() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> entities = directory.listSync();
    setState(() {
      _videoFiles = entities
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4') || f.path.endsWith('.mkv') || f.path.endsWith('.avi'))
          .toList();
    });
  }

  // 多选并导入视频
  Future<void> _importVideos() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: true, // 开启多选
    );

    if (result != null) {
      final directory = await getApplicationDocumentsDirectory();
      for (var path in result.paths) {
        if (path != null) {
          final file = File(path);
          // 复制到内部私密目录，防止系统相册扫描
          final String newPath = '${directory.path}/${file.uri.pathSegments.last}';
          await file.copy(newPath);
        }
      }
      _loadPrivateVideos(); // 刷新列表
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的私密库'),
        actions: [
          IconButton(
            onPressed: _importVideos,
            icon: const Icon(Icons.add_to_photos),
            tooltip: '导入视频',
          ),
        ],
      ),
      body: _videoFiles.isEmpty
          ? const Center(child: Text('点击右上角图标导入私密视频'))
          : ListView.builder(
              itemCount: _videoFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.video_file, color: Colors.blueAccent),
                  title: Text(_videoFiles[index].uri.pathSegments.last),
                  subtitle: Text('${(_videoFiles[index].lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB'),
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
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // 释放旧资源 - 注意：这里不使用 await，因为 dispose 返回 void
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    _videoPlayerController = VideoPlayerController.file(widget.videoFiles[_currentIndex]);
    
    await _videoPlayerController!.initialize();

    _