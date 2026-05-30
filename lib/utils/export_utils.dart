/// 导出工具模块
///
/// 提供将线索墙导出为图片的功能，支持：
/// - 将画布区域截图保存为 PNG
/// - 通过系统分享菜单分享截图
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/wall_constants.dart';

/// 导出工具类
///
/// 提供静态方法用于将 Flutter Widget 树截图并导出。
class ExportUtils {
  /// 将 RepaintBoundary 截图并返回图片字节数据
  ///
  /// [boundaryKey] 是 RepaintBoundary 的 GlobalKey，
  /// 该 Widget 需要包裹在目标截图区域外层。
  ///
  /// 返回 PNG 格式的图片字节数据，失败返回 null。
  static Future<Uint8List?> capturePng(GlobalKey boundaryKey) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: WallConstants.exportPixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('截图失败: $e');
      return null;
    }
  }

  /// 将图片字节数据保存到临时文件并返回文件路径
  ///
  /// 文件保存在应用临时目录中，文件名格式为
  /// `reticence_线索墙_YYYYMMDD_HHmmss.png`。
  static Future<File?> saveToTempFile(Uint8List pngBytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final file = File('${dir.path}/reticence_$timestamp.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      debugPrint('保存临时文件失败: $e');
      return null;
    }
  }

  /// 截图并分享
  ///
  /// 完整的截图分享流程：
  /// 1. 将 RepaintBoundary 截图为 PNG
  /// 2. 保存到临时文件
  /// 3. 调用系统分享菜单
  ///
  /// [boundaryKey] 是 RepaintBoundary 的 GlobalKey。
  /// [subject] 是分享时的标题文本。
  static Future<void> captureAndShare(
    GlobalKey boundaryKey, {
    String subject = '线索墙',
  }) async {
    final pngBytes = await capturePng(boundaryKey);
    if (pngBytes == null) return;

    final file = await saveToTempFile(pngBytes);
    if (file == null) return;

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
      text: '来自 Reticence 的线索墙',
    );
  }
}
