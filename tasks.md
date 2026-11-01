# Tasks

> 时间估算是按学生独立开发、每天 4-6h 有效时间算的。实际会受课业影响，当参考别当承诺。

- [x] Task 1: 项目初始化与基础架构搭建  `⏱ 1天`
  - [x] SubTask 1.1: 使用 Flutter 创建项目，配置目录结构（lib/models, lib/providers, lib/screens, lib/widgets, lib/services, lib/theme, lib/utils, lib/controllers）
  - [x] SubTask 1.2: 添加依赖：riverpod, drift, sqlite3_flutter_libs, flutter_riverpod, image_picker, path_provider
  - [x] SubTask 1.3: 配置 Drift 数据库初始化，创建 AppDatabase 入口

- [x] Task 2: 数据模型与本地存储  `⏱ 1-2天`
  - [x] SubTask 2.1: 定义 Drift 数据表：Card、Connection、Photo（参照 spec 数据模型，含外键约束和级联删除）
  - [x] SubTask 2.2: 生成 Drift DAO，配置数据库迁移策略（schema v1→v10 增量迁移）
  - [x] SubTask 2.3: 实现 CardRepository（CRUD 卡片，含位置信息 x/y/rotation、标签 JSON 序列化）
  - [x] SubTask 2.4: 实现 ConnectionRepository（CRUD 连线，含 label、connection_type、photo 端点）
  - [x] SubTask 2.5: 实现 PhotoRepository（CRUD 照片，含 caption、photo_style、位置信息）

- [x] Task 3: 手账美学主题系统  `⏱ 2-3天`
  - [x] SubTask 3.1: 定义色彩体系（低饱和度主色、辅助色、背景色 → AppColors）
  - [x] SubTask 3.2: 定义字体系统（本地打包字体 Caveat/SourceSerif4/LXGWWenKai/HarmonyOS/NotoSerifCJK → AppTypography）
  - [x] SubTask 3.3: 实现纸质纹理背景 Widget（PaperTextureBackground）
  - [x] SubTask 3.4: 实现毛玻璃效果面板 Widget（AppDialogShell + BackdropFilter + 圆角 + 柔和边框）
  - [x] SubTask 3.5: 实现大头钉图钉装饰 Widget（PushpinDecorator，微倾斜随机角度）
  - [x] SubTask 3.6: 实现卡片纸张质感样式（微倾斜 rotation、柔和阴影 AppShadows、纸纹叠加）

- [x] Task 4: 视觉资源收集  `⏱ 0.5-1天`
  - [x] SubTask 4.1: 收集大头钉图钉 PNG（透明背景含阴影）
  - [x] SubTask 4.2: 收集软木板纹理 PNG（可平铺）+ 纸张纹理 PNG（可平铺）
  - [x] SubTask 4.3: 所有资源放入 assets/ 目录并在 pubspec.yaml 注册

- [x] Task 5: 线索墙画布视图（核心）  `⏱ 4-6天`
  - [x] SubTask 5.1: 实现可缩放平移画布（CanvasNavigationHandler + 手势冲突处理，GestureCoordinator 单指拖卡片/双指拖画布区分）
  - [x] SubTask 5.2: 实现纸质纹理软木板背景（PaperTextureBackground + 暗角 vignette 效果）
  - [x] SubTask 5.3: 实现线索卡片 Widget（ClueCardWidget：大头钉 + 纸张卡片 + 标签 chip + 微旋转）
  - [x] SubTask 5.4: 实现卡片拖拽交互（DragHandler + 位置实时更新 + 碰撞边界检测）
  - [x] SubTask 5.5: 实现 CustomPainter 绘制红线（RedThreadPainter：三次贝塞尔曲线，红色，带阴影和发光）
  - [x] SubTask 5.6: 实现连线标签渲染（沿红线中段显示 label 文字，小字号、半透明白底圆角矩形背景，缩放等比）
  - [x] SubTask 5.7: 实现卡片间拖拽创建连线交互（ConnectionHandler：从一张卡片拖出连线手柄到另一张）
  - [x] SubTask 5.8: 实现画布空白处长按添加卡片（AddCardDialog：弹出快速编辑面板）
  - [x] SubTask 5.9: 实现画布软边界（边缘阻尼 + 松手回弹，卡片不飞出可视范围）
  - [x] SubTask 5.10: 实现缩放全部可见（ToolButtons 触发，自动缩放+平移使所有卡片可见）
  - [ ] SubTask 5.11: 实现 Forge2D 物理世界初始化 + CustomPainter 坐标系映射——当前未使用 Forge2D
  - [x] SubTask 5.12: 实现纯贝塞尔渲染模式（RedThreadPainter：静态贝塞尔曲线 + 阴影发光效果）

- [ ] Task 6: 🔴 红线物理模拟（核心差异化）  `⏱ 6-9天` ⚠️ 高风险任务
  - [ ] SubTask 6.1: 基于 Forge2D 实现连线弹性物理模型（DistanceJoint + 弹簧阻尼参数调校）
  - [ ] SubTask 6.2: 实现连线自然下垂渲染（对 Forge2D body 施加恒定向下重力，连线中点下垂量随距离非线性增长）
  - [ ] SubTask 6.3: 实现连线绷紧状态（拖拽卡片超过自然长度时连线拉直 + 微颤动画）
  - [ ] SubTask 6.4: 实现连线拨动交互（长按连线检测 → 对连线施加横向瞬时冲量 → 波动传播至相邻连线 → 阻尼衰减）
  - ~~SubTask 6.5: 实现连线断裂效果~~（已移除，不需要断裂机制）
  - [ ] SubTask 6.6: 实现卡片松手回弹（松手时被拉紧的连线弹簧力将卡片拉回平衡位置）
  - [ ] SubTask 6.7: 物理参数调参并存档（阻尼/弹性/重力/断裂阈值 → `test/fixtures/physics_params.json`）

- [x] Task 7: 卡片与连线编辑面板  `⏱ 2-3天`
  - [x] SubTask 7.1: 实现卡片详情底部弹出面板（CardDetailDialog：毛玻璃效果 + 拖拽手柄 + 弹性动画）
  - [x] SubTask 7.2: 实现姓名、标签（chip 输入/删除）、描述编辑表单
  - [x] SubTask 7.3: 实现连线编辑面板（ConnectionDetailDialog：关系描述 TextField + 预设标签）
  - [x] SubTask 7.4: 实现删除确认对话框（卡片删除警告"同时删除 N 条连线"，连线删除仅删连线）
  - [x] SubTask 7.5: 实现照片详情面板（PhotoDetailDialog：照片预览 + 说明编辑）
  - [x] SubTask 7.6: 实现添加照片菜单（AddPhotoMenu：拍照/相册选择）

- [x] Task 8: 单元测试与 Widget 测试  `⏱ 2-3天`
  - [x] SubTask 8.1: Repository 单元测试（Card/Photo/Connection 三个 Repository 全部 CRUD 覆盖）——26 个测试
  - [x] SubTask 8.2: Provider 单元测试（CardListNotifier/PhotoListNotifier/ConnectionListNotifier）——17 个测试
  - [x] SubTask 8.3: Handler 单元测试（DragHandler/ConnectionHandler/PhotoDragHandler/SelectionManager/UndoRedoNotifier）——32 个测试
  - [x] SubTask 8.4: Model 单元测试（ClueCard/PhotoCard/Connection）——13 个测试
  - [x] SubTask 8.5: Widget 测试（画布手势：拖拽/缩放/平移、应用启动）
  - [x] SubTask 8.6: 黄金测试（onboarding 页面视觉回归）
  - [x] SubTask 8.7: 性能基准测试（10/30 张卡片渲染、模型创建、连线创建性能）

- [ ] Task 9: 集成测试与性能优化  `⏱ 2-3天`
  - [ ] SubTask 9.1: 集成测试：添加卡片→连线→编辑→重启 App 验证持久化
  - [ ] SubTask 9.2: 性能基准测试：30 张卡片 + 50 条连线 → 帧率 ≥ 55fps
  - [ ] SubTask 9.3: 性能基准测试：100 张卡片极限场景 → 帧率 ≥ 30fps，交互不卡死
  - [ ] SubTask 9.4: 内存泄漏检查（DevTools Memory 面板）
  - [ ] SubTask 9.5: 包体积检查（release APK ≤ 25MB，IPA ≤ 30MB）

- [ ] Task 10: 打磨与收尾  `⏱ 1-2天`
  - [x] SubTask 10.1: 空状态处理（无卡片时画布提示"长按添加第一条线索" → EmptyStateHint）
  - [x] SubTask 10.2: 错误状态处理（Provider 层错误通过 errorProvider 暴露，SnackBar 提示 + 重试按钮）
  - [x] SubTask 10.3: 加载状态处理（画布进入时短暂淡入 → AppStateWidgets）
  - [ ] SubTask 10.4: 无障碍适配（Semantics label on 卡片和连线，屏幕阅读器可用）
  - [ ] SubTask 10.5: App 图标 + 启动页（手账剪贴簿风格，和主题一致）

---

## 已完成的额外优化（第四轮）

- [x] Provider 状态不可变性修复（card_provider/photo_provider 中 replaceAll 替代 in-place mutation）
- [x] 提取 PhotoDragHandler、SelectionManager（从 clue_wall_screen.dart 拆分）
- [x] 合并 _tryConnectToCard/_tryConnectToPhoto 为统一 _tryConnect
- [x] 接通全部撤销命令（连线增删改、照片增删、卡片增删移动、照片移动）
- [x] 为 silent catch 块添加 dart:developer log() 日志
- [x] 修复位置随机化不检查照片重叠
- [x] 修复 PhotoCardWidget Stack 布局约束问题
- [x] 批量修复 46 个文件的 dangling_library_doc_comments lint
- [x] 修复全部 prefer_const_constructors lint 提示
- [x] 全量测试 102 个通过，flutter analyze 0 issue

# Task Dependencies

```
Task 1 ──┬── Task 2 ── Task 5 ──────── Task 6
         │            │
         ├── Task 3 ──┤── Task 7
         │            │
         └── Task 4 ──┘
                                  │
         Task 8 ──────────────────┤（测试应在对应模块完成后立即写）
         Task 9 ──────────────────┘
         Task 10 ─────────────────┘（与 Task 9 并行）
```

**依赖说明**：
- Task 4（视觉资源）和 Task 2/3 并行，不阻塞彼此，但 Task 5 需要 Task 4 的资源就位
- Task 5.12（贝塞尔渲染）必须在 Task 6 开始前完成，作为 Task 6 的安全网
- Task 7（编辑面板）依赖 Task 5（画布视图），但可以和 Task 6 并行
- **Task 8（测试）不要堆到最后**：每个模块的 Repository 测试在对应 Task 完成后立即写；Widget 测试在组件完成后立即写；黄金测试在 Task 3 完成后就可以开始
- Task 9 依赖所有功能任务 + Task 8 完成
- Task 10 可以和 Task 9 并行

---

## 里程碑建议

| 里程碑 | 包含任务 | 预计累计时间 | 可交付物 |
|--------|---------|-------------|---------|
| M1: 基础跑通 | Task 1-4 | 5-7天 | 画布 + 卡片可拖拽 + 主题可见 + 红线渲染 |
| M2: 核心体验 | Task 5-7 | 14-22天 | 红线渲染完整 + 编辑面板 + 照片支持 + 撤销重做 |
| M3: 交付质量 | Task 8-10 | 19-30天 | 测试通过 + 性能达标 + 打磨完成 |

> **风险提示**：Task 6（红线物理）是最大不确定因素，Forge2D 参数调校可能超预期。当前已采用纯贝塞尔渲染作为基线，Forge2D 物理模拟为后续增强目标。
