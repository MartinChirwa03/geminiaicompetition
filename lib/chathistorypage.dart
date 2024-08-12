import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

class ChatHistoryPage extends StatelessWidget {
  final List<ChatMessage> messages;

  const ChatHistoryPage({Key? key, required this.messages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat History'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/_2930b917-e7ba-4962-85b7-0059c96271d0.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return ListTile(
              leading: message.medias?.isNotEmpty ?? false
                  ? Image.file(
                File(message.medias!.first.url),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : null,
              title: Text(message.user.firstName ?? 'Unknown'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.text),
                  SizedBox(height: 5),
                  Text(
                    '${message.createdAt.day}/${message.createdAt.month}/${message.createdAt.year} ${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              isThreeLine: true,
            );
          },
        ),
      ),
    );
  }
}
