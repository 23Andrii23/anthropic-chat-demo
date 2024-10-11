import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:flutter/material.dart';
import 'package:test_chat/consts.dart';
import 'package:test_chat/pages/chat_page.dart';
import 'package:test_chat/pages/screenshot_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AnthropicClient client;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    client = AnthropicClient(apiKey: ANTHROPIC_KEY);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          _selectedIndex == 0 ? 'Chat Page' : 'Image Analysis Page',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ChatPage(client: client),
          ScreenshotPage(client: client),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Screenshot',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
