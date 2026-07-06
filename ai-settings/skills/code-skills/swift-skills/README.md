# swift-skills

一组面向 Swift / SwiftUI 应用开发的 agent skills。每个子目录是一个独立 skill,带 `SKILL.md` 与 YAML frontmatter,可被 Claude Code / Codex / Cursor / Gemini 等工具按需触发。

目标:从 **立项 → 编码 → 审查 → 测试 → 上线 → 维护** 的每一步都能找到合适的指导。

---

## 开发全生命周期 × Skills 映射

### 阶段 1 — 立项与脚手架

新建一个 SwiftUI app 或 Swift package 时使用。

| Skill             | 何时用                                                                   |
| ----------------- | ------------------------------------------------------------------------ |
| **project-setup** | 决定 Xcode app vs SPM 包结构,搭建 feature-based 目录,配置 build settings |
| **packaging**     | 写 `Package.swift`、拆 local SPM 包、声明依赖、绑定 resources            |

### 阶段 2 — 编码(每天高频使用)

写代码时持续参考,SwiftUI / Swift 两类各取所需。

**SwiftUI 视图层**

| Skill                | 何时用                                                           |
| -------------------- | ---------------------------------------------------------------- |
| **view-composition** | 拆 view 结构、写动画、安排 `body` 与子视图                       |
| **navigation**       | 写 `NavigationStack`、`sheet`、alert、confirmation dialog        |
| **data-flow**        | 设计 `@Observable` / `@State` / `@Bindable` 数据流               |
| **design**           | 套用 HIG、字号、间距、`ContentUnavailableView`、`LabeledContent` |

**Swift 语言层 / 横切关注**

| Skill                 | 何时用                                                                      |
| --------------------- | --------------------------------------------------------------------------- |
| **swift-modern**      | 现代 Swift 6.2 写法、并发、formatter、可选解包                              |
| **api-modernization** | 检索是否在用 `foregroundColor` / `cornerRadius` / `NavigationView` 等老 API |
| **persistence**       | 设计 SwiftData 模型、`@Query`、关系、CloudKit 约束                          |
| **networking**        | 设计 URLSession async client、错误处理、与 `task()` 集成                    |
| **localization**      | 加新字符串就走 String Catalog + symbol key 流程                             |

### 阶段 3 — 审查与重构

写完一块功能后,或接手他人代码时使用。

| Skill                 | 何时用                                                                   |
| --------------------- | ------------------------------------------------------------------------ |
| **accessibility**     | 检查 VoiceOver、Dynamic Type、Reduce Motion、tap target                  |
| **performance**       | 排查掉帧、`AnyView`、`body` 重算、`LazyVStack`、`task()` vs `onAppear()` |
| **api-modernization** | 全文扫一遍是否还有 deprecated API                                        |
| **view-composition**  | 看 `body` 是否过长、是否把子视图提到独立 struct                          |

### 阶段 4 — 测试

| Skill                | 何时用                                                              |
| -------------------- | ------------------------------------------------------------------- |
| **testing-strategy** | 写新测试、迁移到 Swift Testing(`@Test`/`#expect`)、设计 mock、配 CI |

### 阶段 5 — 文档

| Skill             | 何时用                                             |
| ----------------- | -------------------------------------------------- |
| **documentation** | 写 DocC 注释、catalog、`## Topics`、`docc preview` |

### 阶段 6 — 上线前

发版前的强制 checklist。

| Skill                  | 何时用                                                       |
| ---------------------- | ------------------------------------------------------------ |
| **security**           | 检查 Keychain、ATS、`os.Logger` 隐私、entitlements、敏感字段 |
| **localization**       | 确认所有语言 100% 翻译,跑 pseudolanguage                     |
| **code-hygiene**       | secrets、SwiftLint、字符串 manual extraction、测试覆盖       |
| **release-management** | 版本号 / build number、archive、TestFlight、App Store 提交   |

### 阶段 7 — 维护期

线上版本日常维护、迭代。

| Skill                  | 何时用                                        |
| ---------------------- | --------------------------------------------- |
| **api-modernization**  | 升级到新 iOS 版本后清理 deprecated API        |
| **persistence**        | 加新字段时设计 versioned migration            |
| **performance**        | 用 Instruments 后定位的热点,对照本 skill 优化 |
| **release-management** | 跑增量发布、phased release、rollback 流程     |

---

## 最小可用子集

如果你只想先挑几个开始,按以下顺序加载:

1. **swift-modern** + **view-composition** + **data-flow** — 写出像样的 SwiftUI 代码
2. **api-modernization** + **accessibility** — 避开最常见的两类坑
3. **project-setup** + **testing-strategy** — 项目结构和测试基础
4. **persistence** 或 **networking** — 看你的应用主要做什么
5. **security** + **release-management** — 临近上线时再加

---

## 18 个 skill 总览

```
swift-skills/
├── accessibility/          # VoiceOver, Dynamic Type, Reduce Motion
├── api-modernization/      # 现代 SwiftUI API 替换
├── code-hygiene/           # secrets, lint, 长期可维护性
├── data-flow/              # @Observable, @State, @Bindable
├── design/                 # HIG, 字体, 间距, 系统样式
├── documentation/          # DocC
├── localization/           # String Catalog, plurals, RTL
├── navigation/             # NavigationStack, sheet, alert
├── networking/             # URLSession async client
├── packaging/              # Swift Package Manager
├── performance/            # SwiftUI 性能
├── persistence/            # SwiftData, CloudKit, 迁移
├── project-setup/          # Xcode / SPM 脚手架
├── release-management/     # 版本, 签名, TestFlight, App Store
├── security/               # Keychain, ATS, entitlements
├── swift-modern/           # Swift 6.2, 并发, formatter
├── testing-strategy/       # Swift Testing, XCTest, mock
└── view-composition/       # 视图拆分, 动画
```

---

## 致谢

`accessibility` / `api-modernization` / `code-hygiene` / `data-flow` / `design` / `navigation` / `performance` / `swift-modern` / `view-composition` 这 9 个 skill 改编自 Paul Hudson 的 [SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill)(MIT 协议)。

其余 9 个 skill 由本项目原创,沿用 [python-skills](../python-skills/) 风格。
