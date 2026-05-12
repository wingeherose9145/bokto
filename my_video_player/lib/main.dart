import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(theme: ThemeData.dark(), home: FakeLoginScreen()));

// --- 1. 伪装启动页 (系统工具样式) ---
class FakeLoginScreen extends StatefulWidget {
  @override
  _FakeLoginScreenState createState() => _FakeLoginScreenState();
}

class _FakeLoginScreenState extends State<FakeLoginScreen> {
  final TextEditingController _passController = TextEditingController();
  void _verify() {
    if (_passController.text == "13579") { // 你的进入密码
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PlayerScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("系统环境检测正常 (Code: 200)")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("系统组件更新检查")),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Icon(Icons.system_update_alt, size: 80, color: Colors.blueGrey),
            SizedBox(height: 20),
            TextField(controller: _passController, decoration: InputDecoration(hintText: "请输入内部授权码"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _verify, child: Text("开始检查")),
          ],
        ),
      ),
    );
  }
}

// --- 2. 视频播放器 (物理复制 & 自动适配) ---
class PlayerScreen extends StatefulWidget {
  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  bool _showControls = true;

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.video);
    if (result != null) {
      File sourceFile = File(result.files.single.path!);
      // 关键步骤：复制到 App 内部，这样删除原视频也能播
      final directory = await getApplicationDocumentsDirectory();
      String newPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      File internalFile = await sourceFile.copy(newPath);
      _initializePlayer(internalFile);
    }
  }

  void _initializePlayer(File file) async {
    _controller?.dispose();
    _controller = VideoPlayerController.file(file);
    await _controller!.initialize();
    setState(() {});
    _controller!.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 适配逻辑：BoxFit.contain 保证不拉伸，自动适配横竖屏
          if (_controller != null && _controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          
          // 单击感应层
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
          ),

          // 控制按钮
          if (_showControls)
            Positioned(
              bottom: 40,
              child: Container(
                color: Colors.black54,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(icon: Icon(Icons.skip_previous), onPressed: () {}),
                    IconButton(icon: Icon(Icons.play_arrow), onPressed: () => _controller?.play()),
                    IconButton(icon: Icon(Icons.pause), onPressed: () => _controller?.pause()),
                    IconButton(icon: Icon(Icons.add_to_photos), onPressed: _pickVideo, color: Colors.blueAccent),
                    IconButton(icon: Icon(Icons.skip_next), onPressed: () {}),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}