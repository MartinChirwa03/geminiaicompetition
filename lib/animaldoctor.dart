import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class AIGenerativePage extends StatefulWidget {
  @override
  _AIGenerativePageState createState() => _AIGenerativePageState();
}

class _AIGenerativePageState extends State<AIGenerativePage> {
  final TextEditingController _controller = TextEditingController();
  String _generatedText = '';
  bool _isLoading = false;

  Future<void> _generateContent() async {
    final apiKey = Platform.environment['AIzaSyCPRMhaIZVI1093HamBIuwV5gsMDq4NYLM'];
    if (apiKey == null) {
      setState(() {
        _generatedText = 'No API_KEY environment variable found.';
      });
      return;
    }

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent'); // Replace with the actual API URL

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gemini-1.5-flash',
          'prompt': _controller.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _generatedText = data['text'] ?? 'No response text available.';
        });
      } else {
        setState(() {
          _generatedText = 'Failed to generate content: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _generatedText = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Generative Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a prompt',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateContent,
              child: Text('Generate Content'),
            ),
            SizedBox(height: 16),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Text(
              _generatedText,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AIGenerativePage(),
  ));
}
