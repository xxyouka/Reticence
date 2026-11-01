# 关系线索墙 App Spec

## Why
目前市面上的人际关系管理工具大多是列表或传统图谱形式，缺乏直觉性和沉浸感。用户需要一种更自然、更有趣的方式来梳理和可视化社交关系网络——像侦探在软木板上用大头钉和红线串联线索一样。

## What Changes
- 构建 Flutter 跨平台移动端 App
- 单画布：一个主线索墙，所有卡片和连线在同一画布上
- 卡片系统：姓名、标签、可选描述
- 红线连线系统：卡片间关系线，具备真实物理弹性
- 手账/剪贴簿美学 UI 体系
- 本地数据持久化（Drift/SQLite）

## Impact
- Affected specs: 全新项目，无既有 spec
- Affected code: 全新代码库

## ADDED Requirements

### Requirement: 线索卡片
系统 SHALL 提供线索卡片（Card），每张卡片包含姓名（必填）、标签（0-N个）、描述（可选），卡片在画布上可自由拖拽定位。

#### Scenario: 添加卡片
- **WHEN** 用户在画布空白处长按或点击添加按钮
- **THEN** 在该位置创建一张新卡片，弹出编辑面板输入姓名、标签、描述

#### Scenario: 拖拽卡片
- **WHEN** 用户长按卡片并拖动
- **THEN** 卡片跟随手指移动，相关连线实时更新位置

#### Scenario: 编辑卡片
- **WHEN** 用户点击卡片
- **THEN** 弹出卡片详情面板，可编辑姓名、标签、描述

#### Scenario: 删除卡片
- **WHEN** 用户在卡片详情面板选择删除
- **THEN** 卡片及其所有连线被移除

### Requirement: 照片卡片
系统 SHALL 提供照片卡片（PhotoCard），每张照片包含图片路径（必填）、说明（可选）、位置坐标，支持 polaroid 和 vintage 两种风格。照片可独立存在于画布上，也可通过连线与卡片或其他照片关联。

#### Scenario: 添加照片
- **WHEN** 用户通过添加照片菜单选择图片
- **THEN** 在画布指定位置创建一张照片卡片，随机微旋转

#### Scenario: 拖拽照片
- **WHEN** 用户长按照片并拖动
- **THEN** 照片跟随手指移动，相关连线实时更新位置

#### Scenario: 编辑照片
- **WHEN** 用户点击照片
- **THEN** 弹出照片详情面板，可编辑说明文字

#### Scenario: 删除照片
- **WHEN** 用户在照片详情面板选择删除
- **THEN** 照片及其所有连线被移除

### Requirement: 红线连线
系统 SHALL 支持卡片和照片之间的红线连线（card→card、card→photo、photo→card、photo→photo），每条连线可标注关系描述和连接类型（neutral/ally/enemy/custom）。这是 App 的核心功能。

#### Scenario: 创建连线
- **WHEN** 用户从一张卡片拖向另一张卡片
- **THEN** 两张卡片之间创建一条红线，弹出输入框填写关系描述

#### Scenario: 编辑连线
- **WHEN** 用户点击连线
- **THEN** 弹出连线编辑面板，可修改关系描述

#### Scenario: 删除连线
- **WHEN** 用户在连线编辑面板选择删除
- **THEN** 连线被移除，两张卡片仍保留

#### Scenario: 连线标签显示
- **WHEN** 连线有关系描述（label 非空）
- **THEN** 沿红线中段显示标签文字（小字号、半透明白底、圆角矩形背景），缩放时等比缩放
- **WHEN** 连线标签为空
- **THEN** 不显示标签区域，红线保持纯视觉

### Requirement: 红线物理模拟
系统 SHALL 对连线实施真实物理模拟，使连线呈现弹性红线的视觉效果和交互行为，这是 App 的核心差异化特性。

#### Scenario: 连线自然下垂
- **WHEN** 两张卡片距离较远且无外力
- **THEN** 连线在重力作用下呈现自然悬垂弧度（悬链线），距离越远下垂越大

#### Scenario: 连线弹性
- **WHEN** 用户拖拽卡片使连线拉伸
- **THEN** 连线呈现绷紧状态（直线+微颤），松手后卡片回弹，连线恢复自然下垂弧度

#### Scenario: 连线拨动
- **WHEN** 用户在画布上快速划过一条连线
- **THEN** 连线像真实红线一样被拨动，产生波动效果并逐渐衰减

#### Scenario: 波动传导
- **WHEN** 一条连线被拨动
- **THEN** 波动通过共享卡片传导到相邻连线

#### Scenario: 松手回弹
- **WHEN** 用户松开被拉伸连线的卡片
- **THEN** 连线弹簧力将卡片拉回平衡位置，回弹不超过 3 次，0.5s 内稳定

### Requirement: 画布交互
系统 SHALL 支持画布的缩放（双指捏合）和平移（双指拖动），以及卡片的大头钉固定视觉效果。

#### Scenario: 缩放画布
- **WHEN** 用户双指捏合
- **THEN** 画布相应缩放，卡片和连线等比缩放

#### Scenario: 平移画布
- **WHEN** 用户双指拖动画布空白区域
- **THEN** 画布平移，显示不同区域

#### Scenario: 手势不冲突
- **WHEN** 用户操作画布
- **THEN** 单指拖卡片，双指拖画布，互不干扰

#### Scenario: 画布软边界
- **WHEN** 用户拖拽卡片或平移画布使内容超出可视区域
- **THEN** 画布边缘有阻尼感（越远阻力越大），卡片不会飞到无限远；松手后内容自动回弹到可视范围内

#### Scenario: 缩放全部可见
- **WHEN** 用户双击空白处或点击"缩放适配"按钮
- **THEN** 画布自动缩放+平移，使所有卡片在屏幕内可见（四周留 40px 边距），动画过渡 300ms

### Requirement: 手账剪贴簿美学
系统 SHALL 采用手账/剪贴簿视觉风格，包含以下设计要素：
- 低饱和度配色 + 纸质纹理背景
- 复古排版与字体
- 卡片呈软木板大头钉效果（图钉、微倾斜、纸张质感）
- 轻悬浮卡片式设计（柔和阴影）
- 毛玻璃质感面板

#### Scenario: 视觉一致性
- **WHEN** 用户使用 App 任何界面
- **THEN** 所有界面遵循统一的手账剪贴簿美学规范

### Requirement: 本地数据持久化
系统 SHALL 使用 Drift (SQLite) 进行本地数据持久化，所有卡片和连线数据存储在设备本地。

#### Scenario: 数据持久化
- **WHEN** 用户创建或修改任何数据
- **THEN** 变更即时写入本地存储，App 重启后数据完整恢复

### Requirement: 错误恢复与降级
系统 SHALL 在 Forge2D 物理引擎出现异常时提供降级方案，确保 App 不崩溃、不白屏。

#### Scenario: Forge2D 初始化失败
- **WHEN** Forge2D 物理世界初始化抛出异常（设备不支持 OpenGL、内存不足等）
- **THEN** 自动降级为纯贝塞尔渲染模式：连线使用静态贝塞尔曲线 + 简单弹簧动画（无拨动、无断裂、无波动传导），SnackBar 提示"物理效果已简化"，App 其余功能正常可用

#### Scenario: Forge2D 运行时崩溃
- **WHEN** Forge2D 物理步进（step）过程中抛出异常
- **THEN** 捕获异常，销毁当前物理世界，降级为纯贝塞尔渲染，记录错误日志

#### Scenario: Drift 读写失败
- **WHEN** 数据库读写操作抛出异常（磁盘满、数据库损坏等）
- **THEN** SnackBar 提示"数据保存失败"+ 重试按钮；数据库损坏时尝试 `PRAGMA integrity_check` + 重建

#### Scenario: App 退后台恢复
- **WHEN** App 从后台恢复到前台
- **THEN** Forge2D 物理世界暂停/恢复正确，无残留异常状态，画布渲染帧率在 0.5s 内恢复到正常水平

---

## 数据模型

### Card（线索卡片）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int (PK) | 自增主键 |
| name | String | 姓名，必填 |
| card_type | String | 卡片类型，默认 'person' |
| tags | String (JSON array) | 标签列表，如 ["同事","大学同学"] |
| description | String? | 可选描述 |
| x | double | 画布 X 坐标 |
| y | double | 画布 Y 坐标 |
| scale | double | 缩放比例，默认 1.0（0.3~3.0） |
| rotation | double | 卡片微旋转角度（模拟贴歪效果），默认 0 |
| created_at | DateTime | 创建时间 |
| updated_at | DateTime | 最后修改时间 |

### Photo（照片卡片）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int (PK) | 自增主键 |
| image_path | String | 图片文件路径 |
| caption | String? | 照片说明文字 |
| x | double | 画布 X 坐标 |
| y | double | 画布 Y 坐标 |
| rotation | double | 旋转角度，默认 0 |
| width | double | 宽度，默认 140 |
| height | double | 高度，默认 180 |
| photo_style | int | 照片风格枚举索引（0=polaroid, 1=vintage） |
| created_at | DateTime | 创建时间 |
| updated_at | DateTime | 最后修改时间 |

### Connection（红线连线）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int (PK) | 自增主键 |
| from_card_id | int? (FK → Card) | 起始卡片（与 from_photo_id 二选一） |
| to_card_id | int? (FK → Card) | 目标卡片（与 to_photo_id 二选一） |
| from_photo_id | int? (FK → Photo) | 起始照片（与 from_card_id 二选一） |
| to_photo_id | int? (FK → Photo) | 目标照片（与 to_card_id 二选一） |
| label | String? | 关系描述，如"大学室友" |
| connection_type | String | 连接类型枚举，默认 'neutral'（neutral/ally/enemy/custom） |
| created_at | DateTime | 创建时间 |

> **注意**：Connection 恰好有两个端点 ID 非 null（card→card、card→photo、photo→card、photo→photo 四种组合）。不存储运行时物理状态——只有连线关系和描述存 DB，物理模拟数据只在内存。

---

## 性能约束

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 卡片数量上限 | 100 张 | 超出后提示用户，避免渲染掉帧 |
| 连线数量上限 | 200 条 | |
| 画布渲染帧率 | ≥ 55fps（≤30 张卡片时） | CustomPainter + Forge2D 并行基准 |
| 极限帧率 | ≥ 30fps（100 张卡片） | UI 不卡死，内存 ≤ 200MB |
| Forge2D 物理步长 | 1/60s（16.67ms） | 与屏幕刷新率同步 |
| 首次启动冷启动 | ≤ 2s | 含 Drift DB 初始化 |
| 包体积 | APK ≤ 25MB，IPA ≤ 30MB | Forge2D + assets + Google Fonts |

---

## 技术架构

| 层级 | 技术选型 | 说明 |
|------|---------|------|
| 框架 | Flutter 3.x + Dart SDK ^3.6.0 | 跨平台移动端（iOS + Android） |
| 状态管理 | Riverpod 2.6.1 (flutter_riverpod) | AsyncNotifier + 响应式 |
| 本地存储 | Drift (SQLite) | 类型安全 ORM，schema v10，增量迁移 |
| 画布渲染 | CustomPainter | 自定义绘制连线（三次贝塞尔曲线） |
| 动画 | Flutter AnimationController | 微交互和转场动画 |
| 字体 | 本地打包字体（Caveat, SourceSerif4, LXGWWenKai, HarmonyOS, NotoSerifCJK） | 手账美学排版，无运行时下载 |

### 连线渲染方案

当前实现采用静态贝塞尔曲线渲染连线（`RedThreadPainter`），通过三次贝塞尔曲线模拟自然下垂效果。连线以红色绘制，带阴影和发光效果，模拟真实红线在软木板上的视觉质感。

连线标签沿中段显示，支持半透明白底圆角矩形背景，缩放时等比缩放。

---

## 测试策略

| 层级 | 工具 | 覆盖范围 | 当前状态 |
|------|------|---------|---------|
| 单元测试 | flutter_test | Repository CRUD、数据模型、Handler 逻辑、UndoRedo | 102 个测试全部通过 |
| Widget 测试 | flutter_test | 画布手势（拖拽/缩放/平移）、应用启动 | 已覆盖 |
| 黄金测试 | golden_toolkit | 手账主题视觉回归 | 已覆盖 onboarding 页面 |
| 集成测试 | integration_test | 完整流程 | 待补充 |

> 当前测试覆盖：Repository（Card/Photo/Connection CRUD 全覆盖）、Provider（CardListNotifier/PhotoListNotifier/ConnectionListNotifier）、Handler（DragHandler/ConnectionHandler/PhotoDragHandler/SelectionManager/UndoRedoNotifier）、Model（ClueCard/PhotoCard/Connection）。
