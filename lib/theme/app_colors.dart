/// 应用色彩体系 —— 侦探软木板美学
///
/// 本文件定义了 Reticence 应用的全部色彩常量，围绕"侦探调查板"（Cork Board）
/// 的视觉隐喻进行组织。想象一位侦探在昏暗的办公室里，将线索卡片钉在软木板上、
/// 用红线串联关联线索——这就是整个色彩体系的灵感来源。
///
/// 色彩按以下类别分组：
/// - 软木板底色：模拟真实软木板的棕褐色调，作为应用的主背景
/// - 纸张与墨水：线索卡片的纸张质感与手写墨迹颜色
/// - 红线：侦探串联线索时使用的红色棉线，是应用的核心视觉符号
/// - 图钉：固定卡片的金属图钉，有黄铜、红、绿、蓝四种颜色
/// - 标签：分类标记标签的柔和色调
/// - 阴影与玻璃：卡片投影和半透明覆盖层的颜色
/// - 暗色模式变体：为深色主题特别调整的颜色，保持氛围的同时确保可读性
/// - 和纸胶带：装饰性胶带的柔和色彩
/// - 回形针与旧纸：办公文具和老化纸张的质感色
/// - 卡片类型色：人物/地点/事件三种线索卡片的区分色
/// - 强调色与柔和色：用于交互反馈和视觉层次的辅助色彩
library;

import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  // 软木板底色（Cork Board）
  //
  // 模拟真实软木板的棕褐色调，是整个应用的视觉基底。
  // 主色取自天然软木的中等棕色，浅色和深色变体用于
  // 层次区分与光影效果，边框色模拟木制画框的深色边缘。
  // ============================================================
  static const corkBoard = Color(0xFF4A3C30); // 标准软木棕色——应用主背景
  static const corkBoardLight = Color(0xFF635548); // 浅软木色——受光面或高亮区域
  static const corkBoardDark = Color(0xFF33281F); // 深软木色——阴影面或凹陷区域
  static const corkFrame = Color(0xFF221A12); // 画框深棕色——AppBar 等边框区域

  // ============================================================
  // 纸张与墨水（Paper & Ink）
  //
  // 线索卡片的纸张采用泛黄的旧纸色，而非纯白，
  // 营造年代感和真实感。墨水色取自老式钢笔墨水的
  // 深棕黑色，比纯黑更温暖、更有手写质感。
  // ============================================================
  static const paperWhite = Color(0xFFEDE5D5); // 泛黄旧纸色——卡片表面，非纯白
  static const inkBlack = Color(0xFF1A1308); // 墨水深棕黑——主要文字颜色，比纯黑温暖
  static const inkLight = Color(0xFF3E352A); // 浅墨水色——次要文字或禁用状态

  // ============================================================
  // 红线（Red Thread）
  //
  // 侦探串联关联线索的红色棉线，是整个应用最具辨识度的
  // 视觉符号。三种明度变体分别用于：标准连线、悬停/高亮
  // 连线、以及深色背景上的连线。色调偏暗红而非鲜红，
  // 更接近真实棉线的质感。
  // ============================================================
  static const redThread = Color(0xFF7A2A20); // 标准红线色——线索连线的主色
  static const redThreadLight = Color(0xFF984840); // 浅红线色——高亮或悬停状态的连线
  static const redThreadDark = Color(0xFF501812); // 深红线色——强调或按下状态的连线

  // ============================================================
  // 图钉（Pins）
  //
  // 固定线索卡片到软木板上的金属图钉。黄铜色为默认图钉，
  // 红/绿/蓝三种颜色用于标记不同优先级或类别的卡片。
  // 色调偏暗偏金属质感，避免过于鲜艳破坏整体氛围。
  // ============================================================
  static const pinBrass = Color(0xFFB09840); // 黄铜图钉——默认图钉颜色
  static const pinRed = Color(0xFF8A3030); // 红色图钉——高优先级或紧急标记
  static const pinGreen = Color(0xFF4A6840); // 绿色图钉——已确认或安全标记
  static const pinBlue = Color(0xFF405870); // 蓝色图钉——待查证或信息标记

  // ============================================================
  // 标签（Tags）
  //
  // 线索分类标签的颜色，采用低饱和度的冷色调，
  // 既能在旧纸背景上清晰可辨，又不会喧宾夺主。
  // 蓝/绿/橙分别对应不同的线索分类维度。
  // ============================================================
  static const tagBlue = Color(0xFF506878); // 蓝色标签——信息类分类
  static const tagGreen = Color(0xFF507048); // 绿色标签——确认类分类
  static const tagOrange = Color(0xFF886840); // 橙色标签——待办类分类

  // ============================================================
  // 阴影与玻璃效果（Shadows & Glass）
  //
  // 卡片投影使用极低透明度的暖黑色，模拟真实软木板上
  // 卡片的自然阴影。玻璃效果用于覆盖层和底部弹窗，
  // 半透明的旧纸质感让底层内容若隐若现。
  // ============================================================
  static const shadowColor = Color(0x3A0A0604); // 卡片阴影——极低透明度暖黑色
  static const glassBackground = Color(0xCCDDD0B8); // 玻璃背景——半透明旧纸色覆盖层
  static const glassBorder = Color(0x352A1F14); // 玻璃边框——极低透明度深色描边

  // ============================================================
  // 暗色模式变体（Dark Mode Variants）
  //
  // 暗色模式并非简单地将亮色模式取反，而是重新调整色值
  // 以保持"昏暗侦探办公室"的氛围。软木板变得更深，
  // 纸张变为深褐色，墨水变为浅色以保证可读性，
  // 红线提亮以确保在深色背景上仍然醒目。
  // ============================================================
  static const corkBoardDarkMode = Color(0xFF221A12); // 暗色模式软木板——接近画框的深色
  static const paperWhiteDark = Color(0xFF2A2418); // 暗色模式纸张——深褐色替代泛黄白
  static const inkWhite = Color(0xFFD0C4AC); // 暗色模式墨水——浅暖色替代深墨色
  static const redThreadDarkMode = Color(0xFFB84A4A); // 暗色模式红线——提亮的红色保证可见性

  // ============================================================
  // 和纸胶带（Washi Tape）
  //
  // 日式和纸胶带的装饰性色彩，用于卡片顶部的装饰条。
  // 色调柔和低饱和，模拟真实和纸胶带的哑光质感，
  // 四种颜色提供视觉多样性但不破坏整体和谐。
  // ============================================================
  static const washiPink = Color(0xFF9A7878); // 粉色和纸胶带
  static const washiGreen = Color(0xFF708868); // 绿色和纸胶带
  static const washiBlue = Color(0xFF688090); // 蓝色和纸胶带
  static const washiYellow = Color(0xFF988868); // 黄色和纸胶带

  // ============================================================
  // 回形针与旧纸质感（Paper Clip & Aged Paper）
  //
  // 办公文具和老化纸张的质感色。回形针的金属灰和金色
  // 用于装饰性元素。旧纸、咖啡渍和复古奶油色用于
  // 不同老化程度的纸张表面，增加层次和真实感。
  // ============================================================
  static const paperClip = Color(0xFF807870); // 回形针金属灰——标准回形针颜色
  static const paperclipGold = Color(0xFFB89040); // 金色回形针——装饰性金色回形针
  static const agedPaper = Color(0xFFE0D4B8); // 老旧纸张色——中度泛黄的旧纸
  static const coffeeStain = Color(0xFF908060); // 咖啡渍色——模拟纸张上的咖啡痕迹
  static const vintageCream = Color(0xFFE2D6B8); // 复古奶油色——比 agedPaper 略亮 2 级

  // ============================================================
  // 柔和辅助色（Muted Colors）
  //
  // 低饱和度的辅助色彩，用于次要UI元素、禁用状态、
  // 背景装饰等。这些颜色与整体暖棕色调和谐共存，
  // 提供视觉层次而不分散注意力。棕褐色系（sepia）
  // 是贯穿整个设计的基调色。
  // ============================================================
  static const mutedRose = Color(0xFF887070); // 柔和玫瑰色——温暖的灰粉色
  static const sageGreen = Color(0xFF587050); // 鼠尾草绿——柔和的灰绿色
  static const dustyBlue = Color(0xFF587080); // 灰蓝色——低饱和度的冷色点缀
  static const warmGray = Color(0xFF686058); // 暖灰色——中性背景和分隔
  static const sepia = Color(0xFF685040); // 棕褐色——设计基调色，贯穿全局
  static const darkSepia = Color(0xFF483828); // 深棕褐色——强调和深色区域

  // ============================================================
  // 卡片表面色（Card Surface）
  //
  // 卡片组件的标准表面色，亮色和暗色模式各一。
  // 与 agedPaper 不同，这是更通用的卡片背景色，
  // 而 agedPaper 更偏向"老旧纸张"的特定质感。
  // ============================================================
  static const cardSurface = paperWhite; // 亮色模式卡片表面（同 paperWhite）
  static const cardSurfaceDark = Color(0xFF302820); // 暗色模式卡片表面

  // ============================================================
  // 图钉金属质感（Pushpin Metal）
  //
  // 图钉针尖的金属灰色渐变，从亮银到深灰，
  // 模拟真实金属针尖的光泽质感。
  // ============================================================
  static const needleLight = Color(0xFFCCCCCC); // 针尖亮银色——渐变起点
  static const needleMid = Color(0xFF777777);   // 针尖中灰色——渐变中点
  static const needleDark = Color(0xFF555555);  // 针尖深灰色——描边和渐变终点

  // ============================================================
  // 底部弹窗阴影（Bottom Sheet Shadow）
  //
  // 底部弹窗向上投射的柔和阴影，增强面板的浮起层次感。
  // ============================================================
  static const bottomSheetShadow = Color(0x30000000); // 底部弹窗阴影

  // ============================================================
  // 主题感知辅助方法（Theme-Aware Helpers）
  //
  // 根据当前亮度返回对应的颜色，避免 widget 中硬编码。
  // ============================================================

  /// 对话框/输入框背景色（亮色: agedPaper，暗色: paperWhiteDark）
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? agedPaper
          : paperWhiteDark;

  /// 主要文字色（亮色: inkBlack，暗色: inkWhite）
  static Color textOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? inkBlack
          : inkWhite;

  /// 次要文字色（亮色: inkBlack 55%，暗色: inkWhite 55%）
  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? inkBlack.withValues(alpha: 0.55)
          : inkWhite.withValues(alpha: 0.55);

  /// 输入框填充色（亮色: agedPaper 35%，暗色: paperWhiteDark 35%）
  static Color inputFillOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? agedPaper.withValues(alpha: 0.35)
          : paperWhiteDark.withValues(alpha: 0.35);

  /// 输入框边框色（亮色: sepia 8%，暗色: inkWhite 8%）
  static Color inputBorderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? sepia.withValues(alpha: 0.08)
          : inkWhite.withValues(alpha: 0.08);

  /// 输入框聚焦边框色（亮色: sepia 20%，暗色: inkWhite 20%）
  static Color inputFocusBorderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? sepia.withValues(alpha: 0.2)
          : inkWhite.withValues(alpha: 0.2);

  /// 提示文字色（亮色: sepia 35%，暗色: inkWhite 35%）
  static Color hintOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? sepia.withValues(alpha: 0.35)
          : inkWhite.withValues(alpha: 0.35);

  /// 卡片表面色（亮色: paperWhite，暗色: cardSurfaceDark）
  static Color cardSurfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? paperWhite
          : cardSurfaceDark;

  /// 软木板背景色（亮色: corkBoard，暗色: corkBoardDarkMode）
  static Color corkOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? corkBoard
          : corkBoardDarkMode;
}
