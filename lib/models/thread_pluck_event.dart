/// 红线拨动事件
///
/// 画布长按命中某条连线时发出，携带连线 ID 和在画布坐标系中的触点。
/// [ThreadLayer] 根据触点位置把波注入到绳子的对应位置。
library;

import 'dart:ui';

class ThreadPluckEvent {
  final int connectionId;
  final Offset position;

  const ThreadPluckEvent({
    required this.connectionId,
    required this.position,
  });
}
