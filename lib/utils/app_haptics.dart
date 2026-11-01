/// 应用触觉反馈体系 —— 有节制的物理反馈
///
/// 本文件定义了 Reticence 应用的触觉反馈（Haptic Feedback）系统。
/// 每种触觉模式都对应一种交互语义，让用户通过手指感受到
/// 操作的结果，增强"在软木板上操作实体卡片"的沉浸感。
///
/// 核心设计：节流保护（Throttling）
/// ─────────────────────────────────
/// 触觉反馈如果触发过于频繁（如快速滑动时每帧都触发），
/// 会导致：1) 用户体验混乱，无法区分单次反馈；
/// 2) 硬件马达过热或损坏；3) 系统性能下降。
///
/// 因此所有触觉方法都经过 `_shouldTrigger()` 节流保护：
/// - 两次触发之间至少间隔 50ms（_minimumInterval）
/// - 全局开关（_enabled）允许在特定场景下禁用触觉
/// - 复合触觉模式（success/error/warning 等）内部不受节流影响，
///   因为它们是刻意设计的多拍节奏
library;

import 'dart:async';
import 'package:flutter/services.dart';

class AppHaptics {
  /// 全局触觉开关，允许在特定场景（如无障碍模式）下禁用所有触觉
  static bool _enabled = true;

  /// 上一次触发触觉的时间，用于节流计算
  static DateTime? _lastHapticTime;

  /// 两次触觉触发之间的最小间隔
  ///
  /// 50ms 是一个经验值：足够短以不遗漏用户感知，
  /// 足够长以防止连续快速触发导致的反馈混乱。
  /// 人耳/手指对触觉的时间分辨率约为 10-20ms，
  /// 50ms 确保每次反馈都是可区分的独立事件。
  static const Duration _minimumInterval = Duration(milliseconds: 50);

  /// 启用触觉反馈
  static void enable() => _enabled = true;

  /// 禁用触觉反馈（如无障碍模式、静音模式等）
  static void disable() => _enabled = false;

  /// 节流判断：是否应该触发本次触觉反馈
  ///
  /// 同时满足以下条件才允许触发：
  /// 1. 全局开关已启用（_enabled == true）
  /// 2. 距上次触发已超过最小间隔（50ms）
  ///
  /// 通过后更新 _lastHapticTime 作为下次判断的基准。
  static bool _shouldTrigger() {
    if (!_enabled) return false;
    final now = DateTime.now();
    if (_lastHapticTime != null &&
        now.difference(_lastHapticTime!) < _minimumInterval) {
      return false;
    }
    _lastHapticTime = now;
    return true;
  }

  // ============================================================
  // 基础触觉模式（Basic Haptic Patterns）
  //
  // 三种力度对应三种交互重量感：
  // - light：轻微触碰，如轻点按钮
  // - medium：中等力度，如切换选项
  // - heavy：重击感，如确认删除
  // ============================================================

  /// 轻触反馈——最轻微的触觉
  /// 适用于：按钮轻点、卡片选中、小型开关切换
  static void light() {
    if (!_shouldTrigger()) return;
    HapticFeedback.lightImpact();
  }

  /// 中等反馈——明显的触觉
  /// 适用于：选项切换、标签选择、模式切换
  static void medium() {
    if (!_shouldTrigger()) return;
    HapticFeedback.mediumImpact();
  }

  /// 重击反馈——强烈的触觉
  /// 适用于：危险操作确认、重要状态变更
  static void heavy() {
    if (!_shouldTrigger()) return;
    HapticFeedback.heavyImpact();
  }

  // ============================================================
  // 功能性触觉模式（Functional Haptic Patterns）
  // ============================================================

  /// 选择反馈——轻微的"咔嗒"感
  /// 模拟旋钮或拨盘卡入档位的物理反馈。
  /// 适用于：下拉菜单选项、滑块刻度、列表项选中
  static void selection() {
    if (!_shouldTrigger()) return;
    HapticFeedback.selectionClick();
  }

  /// 通用振动——最基础的振动模式
  /// 适用于：需要引起注意但不对应具体操作的场景
  static void vibrate() {
    if (!_shouldTrigger()) return;
    HapticFeedback.vibrate();
  }

  // ============================================================
  // 语义复合触觉模式（Semantic Compound Patterns）
  //
  // 这些模式由多个基础触觉组合而成，形成有节奏的"触觉语言"。
  // 每种模式都有明确的语义含义，让用户无需看屏幕就能
  // 通过手指感知操作的结果。
  // ============================================================

  /// 成功反馈——"中-轻"双拍节奏
  ///
  /// 节奏：中击 → 100ms → 轻击
  /// 感知：先重后轻，像"点头确认"的触觉隐喻。
  /// 适用于：操作成功、保存完成、连接建立
  static Future<void> success() async {
    if (!_shouldTrigger()) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// 错误反馈——"重-重"双拍节奏
  ///
  /// 节奏：重击 → 150ms → 重击
  /// 感知：两次重击，像"摇头否定"的触觉隐喻。
  /// 间隔比 success 更长（150ms vs 100ms），
  /// 让用户能明确区分"成功"和"错误"两种反馈。
  /// 适用于：操作失败、验证错误、连接断开
  static Future<void> error() async {
    if (!_shouldTrigger()) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.heavyImpact();
  }

  /// 警告反馈——"中-中"双拍节奏
  ///
  /// 节奏：中击 → 100ms → 中击
  /// 感知：两次同等力度，像"敲桌提醒"的触觉隐喻。
  /// 力度介于 success 和 error 之间，传达"注意但非错误"。
  /// 适用于：潜在风险提示、接近限制阈值、未保存更改
  static Future<void> warning() async {
    if (!_shouldTrigger()) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  // ============================================================
  // 拖拽触觉模式（Drag Haptic Patterns）
  //
  // 拖拽开始和结束使用不同力度，让用户感知
  // "拿起"和"放下"两个不同的物理动作。
  // ============================================================

  /// 拖拽开始——轻触反馈
  /// 模拟手指"吸起"卡片时的轻微触感。
  static Future<void> dragStart() async {
    if (!_shouldTrigger()) return;
    HapticFeedback.lightImpact();
  }

  /// 拖拽结束——中等反馈
  /// 模拟卡片"落回"软木板时的较重触感，比拿起时更明显。
  static Future<void> dragEnd() async {
    if (!_shouldTrigger()) return;
    HapticFeedback.mediumImpact();
  }

  // ============================================================
  // 连线触觉模式（Connection Haptic Patterns）
  //
  // 连接和断开使用相反的力度顺序，形成"收紧-放松"的
  // 触觉隐喻，与红线的"拉紧-松开"视觉动作对应。
  // ============================================================

  /// 连接反馈——"轻-中"双拍节奏
  ///
  /// 节奏：轻击 → 80ms → 中击
  /// 感知：先轻后重，像红线"拉紧"的触觉隐喻。
  /// 间隔最短（80ms），传达"快速扣合"的即时感。
  /// 适用于：两条线索建立关联、红线连接完成
  static Future<void> connect() async {
    if (!_shouldTrigger()) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  /// 断开反馈——"中-轻"双拍节奏
  ///
  /// 节奏：中击 → 100ms → 轻击
  /// 感知：先重后轻，像红线"松开"的触觉隐喻。
  /// 与 connect 的力度顺序相反，让用户能通过触觉
  /// 区分"连接"和"断开"两种操作。
  /// 适用于：取消线索关联、红线断开
  static Future<void> disconnect() async {
    if (!_shouldTrigger()) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  // ============================================================
  // 卡片操作触觉模式（Card Operation Haptic Patterns）
  // ============================================================

  /// 卡片添加——"轻-中"双拍节奏
  ///
  /// 节奏：轻击 → 100ms → 中击
  /// 感知：与 connect 相似但间隔更长，传达"放置到位"的确认感。
  /// 模拟图钉钉入软木板时先接触后固定的两步动作。
  /// 适用于：新线索卡片添加到软木板
  static Future<void> cardAdded() async {
    if (!_shouldTrigger()) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// 卡片删除——单次重击
  ///
  /// 感知：干脆的单次重击，传达"移除"的决断感。
  /// 不使用双拍节奏，因为删除是一个不可逆的单一动作，
  /// 单次重击比双拍更符合"一击移除"的语义。
  /// 适用于：线索卡片从软木板移除
  static Future<void> cardDeleted() async {
    if (!_shouldTrigger()) return;
    await HapticFeedback.heavyImpact();
  }

  // ============================================================
  // 滚动触觉模式（Scroll Haptic Pattern）
  // ============================================================

  /// 滚动反馈——选择点击
  ///
  /// 使用 selectionClick 而非 impact，因为滚动时的触觉
  /// 应该模拟"经过刻度"的咔嗒感，而非"撞击"的冲击感。
  /// 配合节流保护，确保快速滚动时不会过度触发。
  /// 适用于：列表滚动经过项目边界、缩放经过预设级别
  static void scroll() {
    if (!_shouldTrigger()) return;
    HapticFeedback.selectionClick();
  }
}
