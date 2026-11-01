/// 静态贝塞尔连线计算 Provider
///
/// 从 card/photo/connection 三个 provider 读取数据，
/// 直接计算每条连线的贝塞尔控制点，供 RedThreadPainter 绘制。
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/rendered_connection.dart';
import '../theme/wall_constants.dart';
import 'card_provider.dart';
import 'connection_provider.dart';
import 'photo_provider.dart';

/// 渲染连线数据 Provider
///
/// 监听卡片、照片、连线列表的变化，静态计算每条连线的贝塞尔控制点。
/// 无物理引擎、无 tick 循环，仅在数据变化时重新计算。
///
/// 使用 [ref.select] 对卡片/照片位置做浅比较，避免拖拽时每帧
/// 因列表引用变化而触发全部连线重算。
final renderedConnectionsProvider = Provider<List<RenderedConnection>>((ref) {
  final connections = ref.watch(connectionListProvider).value ?? [];
  if (connections.isEmpty) return [];

  // 仅提取位置数据，用深比较避免拖拽时每帧重算
  final cardPositions = ref.watch(_cardPositionProvider);
  final photoPositions = ref.watch(_photoPositionProvider);

  final result = <RenderedConnection>[];
  for (final conn in connections) {
    final from = _resolveEndpointFromMaps(
        conn.fromCardId, conn.fromPhotoId, cardPositions, photoPositions);
    final to = _resolveEndpointFromMaps(
        conn.toCardId, conn.toPhotoId, cardPositions, photoPositions);
    if (from == null || to == null || conn.id == null) continue;
    result.add(_buildRenderedConnection(conn.id!, from, to));
  }
  return result;
});

/// 卡片位置快照 Provider（id → Offset）
///
/// 从 cardListProvider 提取每张卡片的图钉中心位置。
/// 使用 select 做浅比较：只有当卡片实际位置变化时才触发重算。
final _cardPositionProvider = Provider<Map<int, Offset>>((ref) {
  final cards = ref.watch(cardListProvider).value ?? [];
  return {
    for (final c in cards)
      if (c.id != null)
        c.id!: Offset(c.x + c.width / 2, c.y + WallConstants.pushpinCenterOffset),
  };
});

/// 照片位置快照 Provider（id → Offset）
final _photoPositionProvider = Provider<Map<int, Offset>>((ref) {
  final photos = ref.watch(photoListProvider).value ?? [];
  return {
    for (final p in photos)
      if (p.id != null)
        p.id!: Offset(p.x + p.width / 2, p.y + WallConstants.pushpinCenterOffset),
  };
});

/// 从位置快照 Map 中解析连线端点的画布坐标
Offset? _resolveEndpointFromMaps(
  int? cardId,
  int? photoId,
  Map<int, Offset> cardPositions,
  Map<int, Offset> photoPositions,
) {
  if (cardId != null) {
    return cardPositions[cardId];
  } else if (photoId != null) {
    return photoPositions[photoId];
  }
  return null;
}

/// 根据两个端点计算贝塞尔曲线的 4 个控制点
///
/// 算法：
/// 1. 计算两端距离，据此得出下垂量（sag）
/// 2. 控制点位于线段 1/4 和 3/4 处，Y 坐标叠加下垂偏移
RenderedConnection _buildRenderedConnection(
    int connectionId, Offset from, Offset to) {
  final dx = to.dx - from.dx;
  final dy = to.dy - from.dy;
  final distance = sqrt(dx * dx + dy * dy);

  // 下垂量：线越短下垂越小，超过 falloff 距离时基本没有下垂
  final sag = (WallConstants.maxSag *
          (1 - distance / WallConstants.connectingLineSagFalloff))
      .clamp(0.0, WallConstants.maxSag);

  // 控制点位于 1/4 和 3/4 处，Y 叠加下垂偏移
  final cp1 = Offset(
    from.dx + dx * 0.25,
    from.dy + dy * 0.25 + sag * 0.8,
  );
  final cp2 = Offset(
    from.dx + dx * 0.75,
    from.dy + dy * 0.75 + sag * 0.8,
  );

  return RenderedConnection(
    connectionId: connectionId,
    points: [from, cp1, cp2, to],
    tension: distance / WallConstants.connectingLineSagFalloff,
  );
}
