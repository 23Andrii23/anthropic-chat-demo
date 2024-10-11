import 'package:flutter/material.dart';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

class ChatPage extends StatefulWidget {
  final AnthropicClient client;
  const ChatPage({required this.client, super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _currentUser = ChatUser(
    id: '1',
    firstName: 'Andrii',
    lastName: 'Prystaiko',
  );

  final _aiUser = ChatUser(
    id: '2',
    firstName: 'Claude',
    lastName: 'AI',
  );

  final _messages = <ChatMessage>[];
  final _anthropicMessages = <Message>[];

  @override
  Widget build(BuildContext context) {
    return DashChat(
      messageOptions: const MessageOptions(
        currentUserContainerColor: Colors.blue,
        containerColor: Colors.green,
        textColor: Colors.white,
      ),
      currentUser: _currentUser,
      onSend: (m) {
        _sendMessage(m);
      },
      messages: _messages,
    );
  }

  Future<void> _sendMessage(ChatMessage m) async {
    setState(() {
      _messages.insert(0, m);
      _anthropicMessages.add(Message(
        role: MessageRole.user,
        content: MessageContent.text(m.text),
      ));
    });

    try {
      final res = await widget.client.createMessage(
        request: CreateMessageRequest(
          model: const Model.model(Models.claude35Sonnet20240620),
          maxTokens: 1024,
          messages: _anthropicMessages,
        ),
      );

      final aiMessage = ChatMessage(
        user: _aiUser,
        createdAt: DateTime.now(),
        text: res.content.text,
      );

      setState(() {
        _messages.insert(0, aiMessage);
        _anthropicMessages.add(Message(
          role: MessageRole.assistant,
          content: MessageContent.text(res.content.text),
        ));
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}
