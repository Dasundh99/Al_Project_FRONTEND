import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(key: Key('myHomePage')),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> _selectedImages = [];
  List<List<String>> _similarImages = [];

  Future<void> findSimilarImages(List<String> images) async {
    const url = 'http://127.0.0.1:5000/find_similar_images';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'images': images}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _similarImages = List<List<String>>.from(
          data['similar_images'].map((group) => List<String>.from(group)),
        );
      });
      debugPrint('Similar Images: $_similarImages');
    } else {
      debugPrint('Error: ${response.reasonPhrase}');
    }
  }

  void pickDirectory() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath != null) {
      final directory = Directory(directoryPath);
      final List<String> imagePaths = [];

      await for (var entity in directory.list(recursive: false)) {
        if (entity is File && (entity.path.endsWith('.png') || entity.path.endsWith('.jpg') || entity.path.endsWith('.jpeg'))) {
          imagePaths.add(entity.path);
        }
      }

      setState(() {
        _selectedImages = imagePaths;
      });
      findSimilarImages(_selectedImages);
    } else {
      debugPrint('No directory selected');
    }
  }

  Widget buildImageGrid(List<String> images) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Image.file(File(images[index]));
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Similarity Detection'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: pickDirectory,
                child: const Text('Select Directory'),
              ),
              if (_similarImages.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Similar Image Groups:'),
                for (var group in _similarImages) ...[
                  buildImageGrid(group),
                  const Divider(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
