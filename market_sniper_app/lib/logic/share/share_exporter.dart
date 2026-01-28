import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; 

import 'share_prompt_loop.dart';

class ShareExporter {
  static Future<String?> captureAndSave(GlobalKey key, String filename) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      if (boundary.debugNeedsPaint) {
        // capture usually safe if visible
      }

      final image = await boundary.toImage(pixelRatio: 2.0); // optimized ratio
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(pngBytes);

      return file.path;
    } catch (e) {
      debugPrint("Share Export Error: $e");
      return null;
    }
  }

  static Future<void> shareFile(BuildContext context, String path,
      {String text = "MarketSniper Insight"}) async {
    
    // Native Share
    try {
       // ignore: deprecated_member_use
       await Share.shareXFiles([XFile(path)], text: text);
    } catch (e) {
       debugPrint("Native Share Failed: $e");
    }

    if (context.mounted) {
      // D45.10 Share Prompt Loop (Post-Export Booster)
      await SharePromptLoop.maybeShow(context);
    }
  }
}
