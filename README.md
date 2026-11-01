# Reticence · 缄默

关系线索墙 — 用红线和图钉编织你的人际网络。  
A local-first relationship clue wall built with Flutter.

<p align="center"><img src="Reticence.png" width="180" alt="Reticence app icon"></p>

## 特性

- **单画布线索墙**：卡片、照片和连线都在同一张软木板上
- **红线物理**：关系线有弹性和阻尼，可以拖动、拉扯、重新钉住
- **手账 / 剪贴簿美学**：纸张纹理、图钉、手写字体和暖色主题
- **本地优先**：Drift / SQLite 持久化，无账号、无云端、无网络请求
- **编辑能力**：撤销 / 重做、搜索、卡片详情、关系备注、导出
- **照片卡片**：从相册添加照片，本地存储

<p align="center"><img src="assets/images/onboard_connect.png" alt="Onboarding illustration"></p>

## 技术栈

- Flutter / Dart 3.6+
- Riverpod、Drift（SQLite）、vector_math
- golden_toolkit、integration_test
- 自定义 Canvas painter（红线、纸张纹理、图钉）

## 运行

```bash
flutter pub get
flutter run
```

测试：

```bash
flutter test
flutter test integration_test
```

## 文档

- [spec.md](spec.md) — 产品与交互规格
- [checklist.md](checklist.md) — MVP 验收清单
- [tasks.md](tasks.md) — 开发任务拆分

## 第三方资产

项目内置了几套开源字体，许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。应用图标、插画和纹理为本项目自有资产。

## License

MIT © 2026 xx