# Verification Checklist

> 标记说明：🔴 P0 = MVP 必达
>
> **MVP 截止线**：所有 🔴 项完成即视为可演示的 MVP。

---

## 基础设施

- [x] 🔴 `flutter doctor` 无报错，项目 `flutter run` 在 iOS 和 Android 均正常启动
- [x] 🔴 `pubspec.yaml` 所有依赖版本兼容，`flutter pub outdated` 无严重冲突
- [x] 🔴 Drift 数据库初始化成功，schema version = 10，`AppDatabase` 实例可正常获取
- [x] 🔴 目录结构符合 spec 定义（models/providers/screens/widgets/services/theme/utils/controllers）

---

## 数据持久化

- [x] 🔴 Card 表 CRUD：添加卡片含 name/tags/description/x/y/rotation → 重启 App 后位置和内容不变
- [x] 🔴 Connection 表 CRUD：创建连线含 from_card/to_card/label/connection_type → 重启后连线恢复
- [x] 🔴 Photo 表 CRUD：添加照片含 image_path/caption/x/y/photo_style → 重启后照片恢复
- [x] 🔴 删除卡片时级联删除其所有 Connection 和 Photo（外键 CASCADE 验证）
- [x] 🔴 Drift migration 测试：schema v1→v10 增量迁移正确执行，旧数据不丢失

---

## 手账美学主题

- [x] 🔴 色彩体系：所有界面使用低饱和度配色（AppColors），无高饱和荧光色
- [x] 🔴 字体系统：标题和正文使用本地打包字体（Caveat/SourceSerif4/LXGWWenKai/HarmonyOS/NotoSerifCJK），fallback 链正确
- [x] 🔴 纸质纹理：画布背景有可感知的纸纹（PaperTextureBackground），重复平铺无接缝
- [x] 🔴 毛玻璃面板：底部弹出面板有 BackdropFilter 模糊效果（AppDialogShell），圆角 + 柔和边框
- [x] 🔴 大头钉装饰：每张卡片上有图钉装饰（PushpinDecorator），随机微倾斜 rotation
- [x] 🔴 卡片纸张：柔和阴影（AppShadows）+ 纸张纹理 + 微倾斜 rotation
- [x] 🔴 全局视觉一致性：画布、编辑面板、弹窗风格统一

---

## 线索墙画布（核心）

- [x] 🔴 缩放：双指捏合，缩放范围 0.3x ~ 3x，卡片和连线等比缩放
- [x] 🔴 平移：双指拖动空白区域移动画布，边界有阻尼感不硬截断
- [x] 🔴 单指/双指手势不冲突：单指拖卡片，双指拖画布，互不干扰（GestureCoordinator）
- [x] 🔴 画布空状态：无卡片时画布中央显示提示（EmptyStateHint）
- [x] 🔴 卡片渲染：纸张样式 + 大头钉 + 标签 chip + 姓名文字，视觉完整
- [x] 🔴 卡片拖拽：长按 200ms 后进入拖拽态（触觉反馈），卡片跟随手指，松手停止
- [x] 🔴 卡片拖拽时连线实时更新端点位置，无延迟/抖动
- [x] 🔴 红线渲染：红色贝塞尔曲线连接两张卡片，视觉上像真实红线（RedThreadPainter）
- [x] 🔴 拖拽创建连线：从卡片拖出连线手柄到目标卡片，目标卡片高亮表示可连接
- [x] 🔴 长按空白处添加卡片：弹出快速编辑面板（AddCardDialog），确认后卡片出现在长按位置
- [x] 🔴 连线标签显示：有 label 的连线沿中段显示标签文字（小字号、半透明白底、圆角矩形），缩放等比；无 label 的连线无标签区域
- [x] 🔴 画布软边界：拖拽卡片或平移画布到边缘有阻尼感，不会飞出无限远，松手后回弹
- [x] 🔴 缩放全部可见：按钮触发（ToolButtons），画布自动缩放+平移使所有卡片可见
- [ ] 🔴 Forge2D 世界初始化不崩溃——当前未使用 Forge2D，采用纯贝塞尔渲染

---

## 红线物理模拟（核心差异化）

- [ ] 🔴 连线自然下垂：距离 > 100px 的连线有明显下垂弧度（悬链线）——当前为静态贝塞尔曲线
- [ ] 🔴 连线弹性：拖拽卡片拉伸连线 → 线条绷直 + 微颤——当前无弹性物理
- [ ] 🔴 松手回弹：松开卡片后连线弹簧力将卡片拉回平衡位置——当前无回弹
- [ ] 🔴 连线拨动：长按连线 → 产生横向波动沿连线传播——当前无拨动交互
- [ ] 🔴 波动传导：拨动一条连线，通过共享卡片传导到相邻连线——当前无波动传导
- [ ] 🔴 物理帧率：≤30 张卡片 + 50 条连线时，FPS ≥ 55

---

## 卡片与连线编辑

- [x] 🔴 卡片详情面板：点击卡片 → 底部弹出毛玻璃面板（CardDetailDialog），显示姓名/标签/描述
- [x] 🔴 卡片编辑：姓名 TextField 非空校验 + 标签 chip 添加/删除 + 描述多行 TextField
- [x] 🔴 卡片删除：详情面板"删除"按钮 → 确认弹窗"将同时删除 N 条连线" → 确认后卡片和连线移除
- [x] 🔴 连线编辑面板：点击连线 → 底部弹出面板（ConnectionDetailDialog），显示关系描述
- [x] 🔴 连线删除：编辑面板"删除"按钮 → 连线立即移除，两张卡片保留
- [x] 🔴 编辑面板关闭时数据已写入 DB（不是关闭后再异步写，防止丢数据）
- [x] 🔴 照片详情面板：点击照片 → 底部弹出面板（PhotoDetailDialog），显示照片/说明
- [x] 🔴 照片编辑：说明文字 TextField
- [x] 🔴 照片删除：详情面板"删除"按钮 → 确认后照片和连线移除

---

## 撤销/重做

- [x] 🔴 撤销/重做框架：UndoRedoNotifier + UndoableCommand 接口，最大历史 50 条
- [x] 🔴 卡片移动撤销：MoveCardsCommand
- [x] 🔴 卡片添加/删除撤销：AddCardCommand / DeleteCardCommand（含关联连线恢复）
- [x] 🔴 照片移动撤销：MovePhotosCommand
- [x] 🔴 照片添加/删除撤销：AddPhotoCommand / DeletePhotoCommand（含关联连线恢复）
- [x] 🔴 连线添加/删除/更新撤销：AddConnectionCommand / DeleteConnectionCommand / UpdateConnectionCommand

---

## 线索类型与关系类型（v1.1）

- [x] 🔴 新建线索时可选择人物/地点/事件，面板标题随类型变化
- [x] 🔴 卡片详情可修改类型，保存后持久化并刷新视觉
- [x] 🔴 卡片始终显示类型徽章（图标 + 中文名），即使没有标签
- [x] 🔴 图钉颜色按类型区分：人物红、地点蓝、事件黄铜
- [x] 🔴 连线详情可选择中立/盟友/敌对/自定义，保存后持久化
- [x] 🔴 创建连线后自动打开关系详情面板，立即设置类型与描述
- [x] 🔴 关系线按类型着色：中立红、盟友绿、敌对近黑、自定义灰蓝
- [x] 🔴 连线标签左侧显示关系类型色圆点
- [x] 🔴 搜索支持类型中文名（人物/地点/事件、中立/盟友/敌对/自定义）
- [x] 🔴 类型字段往返持久化测试 + 选择器/徽章/关系保存组件测试
- [x] 🔴 小屏 + 键盘场景下对话框可滚动，不遮挡保存按钮

---

## 关系图例与筛选（v1.2）

- [x] 🔴 顶部常驻关系图例：四色圆点 + 名称 + 实时数量
- [x] 🔴 无连线时图例自动隐藏
- [x] 🔴 点击类型只看该类关系，再次点击取消
- [x] 🔴 支持多选累加；取消到空或选满四类时恢复全部
- [x] 🔴 未选关系线淡化显示，不显示标签、绳结，不响应点击和长按
- [x] 🔴 搜索命中的连线即使被筛选也保持高亮、可点击
- [x] 🔴 新建连线后自动清除筛选，确保新线立即可见
- [x] 🔴 360px 宽度下图例五项完整显示，不裁切
- [x] 🔴 关系筛选测试：切换纯函数 + 图例计数/隔离/多选/重置/零数量——10 个测试

---

## 搜索

- [x] 🔴 搜索功能：SearchController 支持按名称/标签/描述/类型搜索卡片和照片
- [x] 🔴 关系搜索：支持按关系类型（中立/盟友/敌对/自定义）匹配连线
- [x] 🔴 搜索结果：SearchResultBadge 显示匹配数量，点击定位到目标

---

## 测试

- [x] 🔴 Repository 单元测试覆盖率 ≥ 80%（Card/Photo/Connection 三个 Repository 全部 CRUD 覆盖，含 cardType 往返）——28 个测试
- [x] 🔴 Provider 单元测试：CardListNotifier/PhotoListNotifier/ConnectionListNotifier CRUD + 双阶段位置更新——17 个测试
- [x] 🔴 Handler 单元测试：DragHandler/ConnectionHandler/PhotoDragHandler/SelectionManager/UndoRedoNotifier——38 个测试
- [x] 🔴 Model 单元测试：ClueCard/PhotoCard/Connection 值相等/copyWith/默认值/类型枚举——21 个测试
- [x] 🔴 类型系统测试：搜索类型匹配、类型选择器、卡片徽章、关系类型保存——10 个测试
- [x] 🔴 关系筛选测试：切换纯函数、图例计数、隔离/多选/重置、零数量禁用——10 个测试
- [x] 🔴 Widget 测试：画布手势（拖拽/缩放/平移）、应用启动——6 个测试
- [x] 🔴 性能测试：10/30 张卡片渲染基准、模型创建性能——4 个测试
- [x] 🔴 黄金测试：onboarding 页面视觉回归——1 个测试
- [ ] 🔴 集成测试：完整用户流程（添加卡片→连线→编辑→重启验证持久化），在真机/模拟器通过
- [ ] 🔴 降级集成测试：mock Forge2D 失败 → 完整流程在降级模式下通过

---

## 性能 & 边界

- [ ] 🔴 30 张卡片 + 50 条连线 → 拖拽帧率 ≥ 55fps（DevTools Performance 验证）
- [ ] 🔴 100 张卡片极限场景 → FPS ≥ 30，UI 不卡死，内存 ≤ 200MB
- [ ] 🔴 内存无泄漏：反复创建删除卡片后内存无明显增长（DevTools Memory 验证）
- [ ] 🔴 Release APK ≤ 25MB，IPA ≤ 30MB
- [x] 🔴 空画布 + 编辑面板全空 → 均不崩溃不白屏
- [x] 🔴 快速连续操作（连续添加 10 张卡片 + 快速拖拽）→ 不丢帧不崩溃
- [ ] 🔴 App 退后台再回前台 → 无异常，帧率 0.5s 内恢复
- [ ] 🔴 物理降级：Forge2D 初始化失败时自动降级为纯贝塞尔渲染——当前直接使用贝塞尔渲染

---

## 打磨

- [ ] 🔴 无障碍：卡片有 Semantics label（"线索：张三，标签：同事、大学同学"），连线有含义描述
- [ ] 🔴 App 图标 + 启动页与手账剪贴簿风格一致
- [ ] 🔴 物理参数快照：调参结果存为 `test/fixtures/physics_params.json`
- [x] 🔴 首次启动冷启动 ≤ 2s（含 Drift 初始化）
