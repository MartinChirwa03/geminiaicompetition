import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  Gemini.init(apiKey: '');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: const AI(),
    );
  }
}

class AI extends StatefulWidget {
  const AI({Key? key}) : super(key: key);

  @override
  State<AI> createState() => _AIState();
}

class _AIState extends State<AI> {
  final gemini = Gemini.instance;
  String? responseText;
  File? pickedImage;
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> responses = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getResponses();
  }

  Future<void> _getResponses() async {
    final db = await dbHelper.database();
    final result = await db.query('responses');
    setState(() {
      responses = result.reversed.toList(); // Reverse to show newest first
    });
  }

  Future<void> _insertResponse(String image, String response) async {
    final db = await dbHelper.database();
    await db.insert('responses', {'image': image, 'response': response});
    _getResponses();
  }

  Future<void> _deleteResponse(int id) async {
    final db = await dbHelper.database();
    await db.delete('responses', where: 'id = ?', whereArgs: [id]);
    _getResponses();
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        pickedImage = File(image.path);
      });
    }
  }

  Future<void> _generateResponse(BuildContext context) async {
    if (pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please choose an image first')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final textPrompt =
        'Analyse the image, identifying any livestock or bird diseases, malnutrition, or other health issues. Provide the cause, treatment, medication, drugs, vaccines, and prevention methods.';

    try {
      final response = await gemini.textAndImage(
        text: textPrompt,
        images: [pickedImage!.readAsBytesSync()],
      );
      setState(() {
        responseText = response?.content?.parts?.last.text;
        isLoading = false;
      });
      await _insertResponse(pickedImage!.path, responseText!);
    } catch (e) {
      print('Error generating response: $e');
      setState(() {
        responseText = 'Error generating response';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livestock AI Doctor',style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold
        ),),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/WhatsApp Image 2024-08-12 at 15.19.11_9cb19a32.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (pickedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(pickedImage!, height: 200, width: 200, fit: BoxFit.cover),
                  ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _getImage(ImageSource.gallery),
                      icon: Icon(Icons.photo_library),
                      label: Text('Gallery'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _getImage(ImageSource.camera),
                      icon: Icon(Icons.camera_alt),
                      label: Text('Camera'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : () => _generateResponse(context),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Generate Response'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
                SizedBox(height: 20),
                if (responseText != null)
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      responseText!,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                SizedBox(height: 20),
                Text(
                  'Past Responses:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: responses.length,
                  itemBuilder: (context, index) {
                    final response = responses[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          response['response'],
                          style: TextStyle(color: Colors.black),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteResponse(response['id']),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Full Response'),
                              content: SingleChildScrollView(child: Text(response['response'])),
                              actions: [
                                TextButton(
                                  child: Text('Close'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DatabaseHelper {
  Future<Database> database() async {
    return openDatabase(
      join(await getDatabasesPath(), 'responses.db'),
      onCreate: (db, version) {
        return db.execute(
            'CREATE TABLE responses(id INTEGER PRIMARY KEY AUTOINCREMENT, image TEXT, response TEXT)');
      },
      version: 1,
    );
  }
}
