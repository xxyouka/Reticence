/// 软木板画布常量 —— 物理空间的数字化映射
///
/// 本文件定义了 Reticence 应用中软木板画布（Wall）的全部常量参数。
/// 这些常量将"侦探在软木板上布置线索卡片"的物理空间映射为
/// 数字化的交互空间，每个数值都经过权衡以平衡：
///
/// - 真实感：画布足够大以容纳大量线索，卡片尺寸接近真实便签卡
/// - 可用性：缩放范围允许从全局概览到细节查看，触摸区域足够大
/// - 性能：画布尺寸和卡片数量在渲染性能可承受的范围内
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WallConstants {
  // ============================================================
  // 画布尺寸（Canvas Dimensions）
  //
  // 5000×5000 的虚拟画布相当于一块约 1.7m×1.7m 的软木板
  // （按 1px ≈ 0.33mm 换算），足够容纳数十张线索卡片
  // 同时保持合理的间距。用户通过缩放和平移来浏览整个画布。
  // ============================================================
  static const double canvasWidth = 5000; // 画布宽度（逻辑像素）
  static const double canvasHeight = 5000; // 画布高度（逻辑像素）

  // ============================================================
  // 卡片尺寸（Card Sizes）
  //
  // 标准线索卡片的尺寸接近一张 5×3.5 英寸的索引卡
  // （index card），这是侦探和研究人员最常用的笔记卡格式。
  // 中心点坐标用于定位和旋转计算。
  // ============================================================
  static const double cardWidth = 160; // 卡片默认宽度
  static const double cardHeight = 90; // 卡片默认高度

  // ============================================================
  // 缩放限制（Scale Limits）
  //
  // 最小缩放 0.3x 允许用户看到画布的全局概览，
  // 最大缩放 3.0x 允许用户查看卡片上的细节文字。
  // fitPadding 是"适应屏幕"操作时保留的边距，
  // 防止卡片紧贴屏幕边缘。
  // ============================================================
  static const double minScale = 0.3; // 最小缩放比——全局概览
  static const double maxScale = 3.0; // 最大缩放比——细节查看
  static const double fitPadding = 40.0; // 适应屏幕时的边距

  // ============================================================
  // 交互阈值（Hit Thresholds & Layout Randomness）
  //
  // connectionHitThreshold：连线的触摸命中区域半径。
  //   由于红线很细，直接触摸难以命中，因此扩大命中区域到 18px。
  //
  // randomOffsetRange / randomOffsetRangeY：新卡片放置时的随机偏移范围。
  //   模拟侦探随手将卡片钉在板上的自然感，避免所有卡片整齐排列。
  //
  // maxRotationDegrees：卡片的最大随机旋转角度。
  //   ±4° 的微旋转让卡片看起来像是被随手钉上的，
  //   而非数字化的完美对齐。
  // ============================================================
  static const double connectionHitThreshold = 18.0; // 连线触摸命中半径
  static const double connectionSnapRadius = 60.0; // 连线吸附检测半径
  static const double connectionFinishRadius = 40.0; // 连线完成检测半径
  static const double touchSlop = 18.0; // 卡片拖拽触摸判定阈值
  static const double pinTouchSlop = 10.0; // 图钉连线触摸判定阈值（更小，连线更容易触发）
  static const double maxSag = 30.0; // 红线最大下垂量（像素）
  static const double randomOffsetRange = 120; // 水平随机偏移范围
  static const double randomOffsetRangeY = 100; // 垂直随机偏移范围
  static const double maxRotationDegrees = 4.0; // 卡片最大随机旋转角度（度）
  static const double maxPhotoRotationDegrees = 5.0; // 照片最大随机旋转角度（度）
  static const double overlapFactor = 0.7; // 重叠检测系数（占卡片尺寸的比例）
  static const double exportPixelRatio = 2.0; // 导出截图像素比

  // ============================================================
  // 动画时长（Animation Durations）
  //
  // 画布级别的动画时长，比 AppAnimations 中的通用时长
  // 稍长一些，因为画布上的动画涉及更大的视觉变化
  // （缩放、平移、卡片飞入等），需要更多时间让用户感知。
  // ============================================================
  static const int animationDurationMs = 400; // 画布动画时长（毫秒）
  static const int zoomDelayMs = 300; // 缩放操作延迟（毫秒）

  // ============================================================
  // 图钉尺寸（Pushpin Size）
  //
  // 18px 的图钉尺寸在视觉上接近真实图钉的比例，
  // 同时作为触摸目标也满足 44px 最小触摸区域的要求
  // （图钉周围有隐形的扩大触摸区域）。
  // ============================================================
  static const double pushpinSize = 18; // 图钉视觉尺寸
  static const double pushpinHitArea = 44; // 图钉触摸区域尺寸
  static const double pushpinCenterOffset = 22; // 图钉居中偏移量 (pushpinHitArea / 2)

  // ============================================================
  // 连线动画参数（Connecting Line Animation）
  //
  // 连线绘制时的视觉参数，包括下垂量、线宽、光晕半径等。
  // ============================================================
  static const double connectingLineSagFactor = 0.08; // 下垂系数（与线段长度成正比）
  static const double connectingLineMinSag = 8; // 最小下垂量（像素）
  static const double connectingLineSagFalloff = 200; // 下垂衰减距离阈值（像素）
  static const double connectingLineShadowWidth = 3.5; // 阴影层线宽
  static const double connectingLineShadowBlur = 2.0; // 阴影模糊半径
  static const double connectingLineWidth = 2.0; // 主线宽度
  static const double connectingLineDotRadius = 5; // 终点半径
  static const double connectingLineGlowRadius = 9; // 外圈光晕半径
  static const double connectingLineKnotRadius = 2.5; // 起点绳结半径

  // ============================================================
  // 照片卡片尺寸（Photo Card Dimensions）
  //
  // 照片卡片比标准文字卡片更窄更高（140×180），
  // 模拟拍立得照片的比例。
  // ============================================================
  static const double photoCardWidth = 140; // 照片卡片宽度
  static const double photoCardHeight = 180; // 照片卡片高度

  // ============================================================
  // 照片卡片布局（Photo Card Layout）
  //
  // 拍立得和复古两种风格的照片卡片内边距和圆角。
  // ============================================================
  static const double photoInsetTopVintage = 14.0;
  static const double photoInsetTopPolaroid = 10.0;
  static const double photoInsetSideVintage = 14.0;
  static const double photoInsetSidePolaroid = 10.0;
  static const double photoInsetBottomVintage = 40.0;
  static const double photoInsetBottomPolaroid = 30.0;
  static const double photoCornerRadiusVintage = 3.0;
  static const double photoCornerRadiusPolaroid = 2.0;
  static const double photoCaptionBottomVintage = 8.0;
  static const double photoCaptionBottomPolaroid = 4.0;
  static const double photoCaptionFontSizeVintage = 13.0;
  static const double photoCaptionFontSizePolaroid = 14.0;

  // ============================================================
  // 卡片内容布局（Card Content Layout）
  //
  // 卡片内部文字区域的内边距、字号和间距。
  // ============================================================
  static const double cardContentPaddingH = 14.0;
  static const double cardContentPaddingV = 13.0;
  static const double cardNameFontSize = 19.0;
  static const double cardTagFontSize = 10.0;
  static const double cardDescFontSize = 11.0;
  static const double cardTagPaddingH = 7.0;
  static const double cardTagPaddingV = 2.5;
  static const double cardSeparatorHeight = 0.4;

  // ============================================================
  // 纸张纹理参数（Paper Grain Painter）
  //
  // 卡片表面的旧纸纹理效果参数，包括噪点密度、行线间距、边缘磨损等。
  // ============================================================
  static const int paperGrainDotCount = 60; // 噪点数量
  static const double paperGrainDotRadiusMax = 1.2; // 噪点最大半径
  static const double paperGrainDotRadiusMin = 0.3; // 噪点最小半径
  static const double paperGrainDotAlphaMax = 0.025; // 噪点最大透明度
  static const double paperGrainDotAlphaMin = 0.005; // 噪点最小透明度
  static const double paperGrainLineSpacing = 18.0; // 行线间距
  static const double paperGrainLineJitter = 1.5; // 行线水平偏移量
  static const double paperGrainEdgeWear = 6.0; // 边缘磨损区域宽度

  // ============================================================
  // 数量限制（Capacity Limits）
  //
  // 卡片和连线的数量上限，超过时向用户显示警告。
  // 100 张卡片 + 200 条连线在 5000×5000 画布上仍保持合理的视觉密度。
  // ============================================================
  static const int maxCards = 100; // 卡片数量上限
  static const int maxPhotos = 50; // 照片数量上限
  static const int maxConnections = 200; // 连线数量上限

  // ============================================================
  // 手势时长（Gesture Durations）
  //
  // 长按延迟：手指按下后多久触发长按手势。
  // 300ms 是移动端长按的标准阈值，兼顾响应速度和误触防护。
  // canvasLongPressDelayMs：画布空白区域的长按延迟，比卡片长按更长，
  //   避免用户在画布上滑动时误触发长按。
  // ============================================================
  static const int longPressDelayMs = 300; // 长按延迟（毫秒）
  static const int canvasLongPressDelayMs = 500; // 画布长按延迟（毫秒）
  static const int connectingAnimDurationMs = 300; // 连线动画时长（毫秒）

  // ============================================================
  // 卡片布局随机化（Card Placement Randomness）
  //
  // 新卡片放置时的边缘间距和重叠重试次数。
  // ============================================================
  static const double placementMargin = 20.0; // 放置边距（像素）
  static const int placementRetryLimit = 20; // 重叠重试次数上限

  // ============================================================
  // 按压反馈（Press Feedback）
  //
  // 按下卡片时的缩放比例，模拟真实按压纸张的轻微凹陷感。
  // 0.96 表示按下时缩小 4%，提供明确的触觉反馈。
  // ============================================================
  static const double pressScale = 0.96; // 按压缩放比例

  // ============================================================
  // 系统UI覆盖层样式（System UI Overlay Style）
  //
  // 透明状态栏 + 亮色图标，让系统状态栏融入软木板背景，
  // 不破坏沉浸式的侦探办公室氛围。
  // ============================================================
  static const systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // 透明状态栏背景
    statusBarIconBrightness: Brightness.light, // 亮色状态栏图标（适配深色软木板）
    statusBarBrightness: Brightness.dark, // iOS 端状态栏样式
  );
}
