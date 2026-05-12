import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始设为竖屏
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyPrivatePlayer());
}

class MyPrivatePlayer extends StatelessWidget {
  const MyPrivatePlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '私密播放器Pro',
      theme: ThemeData.dark(useMaterial3: true), // 使用深色主题，更有电影感
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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPrivateVideos();
  }

  // 加载私密目录下的视频
  Future<void> _loadPrivateVideos() async {
    final directory = await getApplicationDocumentsFuture();
    final List<FileSystemEntity> entities = directory.listSync();
    setState(() {
      _videoFiles = entities
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4') || f.path.endsWith('.mkv'))
          .toList();
    });
  }

  Future<Directory> getApplicationDocumentsFuture() async {
    return await getApplicationDocumentsDirectory();
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
          final String newPath = '${directory.path}/${file.uri.pathSegments.last}';
          await file.copy(newPath); // 复制到私密目录
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
          IconButton(onPressed: _importVideos, icon: const Icon(Icons.add_to_photos)),
        ],
      ),
      body: _videoFiles.isEmpty
          ? const Center(child: Text('点击右上角导入视频'))
          : ListView.builder(
              itemCount: _videoFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.video_library),
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

// 播放页面
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
    // 销毁旧控制器
    await _chewieController?.dispose();
    await _videoPlayerController?.dispose();

    _videoPlayerController = VideoPlayerController.file(widget.videoFiles[_currentIndex]);
    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      // 关键：允许切换全屏时根据视频比例自动旋转
      allowFullScreen: true,
      allowPlaybackSpeedChanging: true, // 开启倍速
      showControls: true,
      // 自定义控制样式
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      // 视频播放完自动播下一个
      errorBuilder: (context, errorMessage) {
        return Center(child: Text(errorMessage));
      },
    );

    // 监听播放完成
    _videoPlayerController!.addListener(() {
      if (_videoPlayerController!.value.position == _videoPlayerController!.value.duration) {
        _playNext();
      }
    });

    setState(() {});
  }

  void _playNext() {
    if (_currentIndex < widget.videoFiles.length - 1) {
      setState(() {
        _currentIndex++;
        _initPlayer();
      });
    } else {
      Navigator.pop(context); // 放完了回到列表
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    // 强制回到竖屏
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}