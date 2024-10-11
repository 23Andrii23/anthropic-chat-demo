import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class ScreenshotPage extends StatefulWidget {
  final AnthropicClient client;
  const ScreenshotPage({required this.client, super.key});

  @override
  State<ScreenshotPage> createState() => _ScreenshotPageState();
}

class _ScreenshotPageState extends State<ScreenshotPage> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          screenshotController
              .capture(delay: const Duration(milliseconds: 10))
              .then((capturedImage) async {
            if (!context.mounted) return;
            if (capturedImage != null) {
              showCapturedWidget(context, capturedImage);
            }
          }).catchError((onError) {
            debugPrint(onError);
          });
        },
        child: const Icon(Icons.camera),
      ),
      body: Screenshot(
        controller: screenshotController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(height: 100, width: 100, color: Colors.red),
            const SizedBox(height: 25),
            Container(height: 120, width: 120, color: Colors.green),
            const SizedBox(height: 25),
            Container(height: 100, width: 100, color: Colors.blue),
            const SizedBox(height: 25),
            const Text('This widget will be captured as an image'),
          ],
        ),
      ),
    );
  }

  Future<String> _analyzeImage(Uint8List capturedImage) async {
    final directory = await getTemporaryDirectory();
    final file = File(
        '${directory.path}/captured_image_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(capturedImage);

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    final message = Message(
      role: MessageRole.user,
      content: MessageContent.blocks(
        [
          const Block.text(text: 'What is in this image?'),
          Block.image(
            source: ImageBlockSource(
              data: base64Image,
              mediaType: ImageBlockSourceMediaType.imagePng,
              type: ImageBlockSourceType.base64,
            ),
          ),
        ],
      ),
    );

    try {
      final res = await widget.client.createMessage(
        request: CreateMessageRequest(
          model: const Model.model(Models.claude35Sonnet20240620),
          maxTokens: 1024,
          messages: [message],
        ),
      );

      String aiResponseText = '';
      if (res.content is MessageContentBlocks) {
        for (var block in (res.content as MessageContentBlocks).value) {
          if (block is TextBlock) {
            aiResponseText += block.text;
          }
        }
      } else if (res.content is MessageContentText) {
        aiResponseText = (res.content as MessageContentText).value;
      }

      return aiResponseText;
    } catch (e) {
      return 'Error occurred while processing the image.';
    }
  }

  Future<void> showCapturedWidget(
    BuildContext context,
    Uint8List capturedImage,
  ) {
    final Future<String> aiResponseFuture = _analyzeImage(capturedImage);

    return showDialog(
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text("Captured Image Analysis"),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.memory(capturedImage, width: 300, height: 500),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("What is in this image?"),
              ),
              FutureBuilder<String>(
                future: aiResponseFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Error: ${snapshot.error}"),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        snapshot.data ?? "No response",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
