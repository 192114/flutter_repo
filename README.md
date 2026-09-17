# flutter_repo

基于 Flutter 的分层架构模板工程：**严格分层 + MVVM**，内置多环境配置、语义化主题（明暗切换）、统一日志、集中路由与 AI 协作工具链，开箱即用，可直接作为新项目的脚手架。

## 目录

- [技术选型](#技术选型)
- [快速开始](#快速开始)
- [运行与调试](#运行与调试)
- [项目结构](#项目结构)
- [架构设计](#架构设计)
- [主题与配色](#主题与配色)
- [日志设计](#日志设计)
- [多环境配置](#多环境配置)
- [路由设计](#路由设计)
- [测试策略](#测试策略)
- [静态检查与 Lint](#静态检查与-lint)
- [持续集成（CI）](#持续集成ci)
- [AI 协作工具链](#ai-协作工具链)
- [常用命令速查](#常用命令速查)

## 技术选型

| 场景 | 方案 | 说明 |
|---|---|---|
| SDK 管理 | FVM（Flutter 3.47.0） | `.fvmrc` 锁定版本，所有命令加 `fvm` 前缀 |
| 状态管理 / DI | `flutter_riverpod` 3.x | Notifier/AsyncNotifier，Provider 即依赖注入容器 |
| 网络请求 | `dio` | 全局单实例 `dioProvider`，拦截器统一装配 |
| JSON 序列化 | `freezed` + `json_serializable` + `build_runner` | 不可变模型，代码生成 |
| 导航 | `go_router` | 集中声明路由，页面间只传 ID |
| 日志 | `logger`（封装为 `AppLogger`） | 全项目唯一日志出口 |
| 本地存储 | `shared_preferences` | 主题模式等非敏感持久化 |
| 安全存储 | `flutter_secure_storage` | Token 等敏感值 |
| 模型不可变 | `freezed` | copyWith / == / pattern matching 支持 |

> 以上选型为项目强制约定（详见 [AGENTS.md](AGENTS.md)）：禁止引入 http、bloc/getx/provider、手写 fromJson、`print` 等替代方案。

## 快速开始

前置要求：安装 [FVM](https://fvm.app/)，SDK 版本由 `.fvmrc` 自动锁定（Flutter 3.47.0 / Dart ^3.13.0），无需全局 Flutter。

```bash
# 安装依赖
fvm flutter pub get

# 运行（dev 环境，缺省安全回落 dev + 演示 API）
fvm flutter run

# 指定环境运行
fvm flutter run --dart-define-from-file=env/dev.json
fvm flutter run --dart-define-from-file=env/staging.json
fvm flutter run --dart-define-from-file=env/prod.json
```

日常开发推荐一键脚本或 IDE 调试（含热重载说明），见 [运行与调试](#运行与调试)。

## 运行与调试

两种启动方式二选一：**命令行一键脚本**（不依赖 IDE）或 **VSCode 调试面板**。

### 命令行：一键脚本

[scripts/run.sh](scripts/run.sh) 自动完成全流程：检测目标模拟器是否已启动（`xcrun simctl list`）→ 未启动则 `boot` 并用 `bootstatus` 阻塞等待系统就绪 → 打开 Simulator 窗口 → 按环境执行 `fvm flutter run -d ... --dart-define-from-file=...`：

```bash
./scripts/run.sh              # dev 环境（缺省）
./scripts/run.sh staging      # staging 环境
./scripts/run.sh prod         # prod 环境

# 目标模拟器缺省 iPhone 17 Pro，可用环境变量覆盖：
SIMULATOR="iPhone 16e" ./scripts/run.sh dev
```

- 环境参数白名单 dev / staging / prod（对应 `env/*.json`），拼错直接报错退出，不静默回落；
- 模拟器名不存在时列出全部可用设备便于修正；
- 仅 macOS 支持模拟器流程（依赖 `xcrun simctl`）；非 macOS 会跳过模拟器、由 flutter 自动选择已连接设备。

### 命令行：手动等价命令

不使用脚本时的等价手动流程：

```bash
xcrun simctl boot "iPhone 17 Pro"            # 启动模拟器
xcrun simctl bootstatus "iPhone 17 Pro" -b   # 阻塞等待系统就绪
open -a Simulator                            # 显示模拟器窗口
fvm flutter run -d "iPhone 17 Pro" --dart-define-from-file=env/dev.json
```

### VSCode / IDE 调试

复制 `.vscode/launch.example.jsonc` 为同目录 `launch.json`（个人文件已被 gitignore 忽略，不会污染仓库），按 F5 在运行面板选择 dev / staging / prod（debug）或 prod (profile) 启动。Dart 扩展会自动读取 `.fvmrc` 锁定的 SDK 版本，无需额外配置。

### 热重载 / 热重启

`flutter run` 运行期间，在其终端**直接按键**（非输入命令）：

| 按键 | 作用 |
|---|---|
| `r` | 热重载：注入改动代码，保留页面状态 |
| `R` | 热重启：App 整体重启，状态清零（改 `main()` / 依赖 / 全局初值后使用） |
| `q` | 退出调试会话 |

> 误按 `q` 退出但 App 仍在运行时，可用 `fvm flutter attach -d "iPhone 17 Pro"` 重新挂载，之后 `r` / `R` 照常可用；修改 `pubspec.yaml` 或执行 build_runner 后，热重载不生效，需退出后重新运行。

## 项目结构

```
flutter_repo/
├── env/                          # 多环境配置（dev / staging / prod，编译期注入）
├── lib/
│   ├── main.dart                 # 入口：组合根（异步依赖初始化 + Provider overrides）
│   ├── app.dart                  # 根 Widget：MaterialApp.router + 主题模式接入
│   ├── core/                     # 横切关注点（与业务无关）
│   │   ├── config/               # 多环境配置：AppEnvironment + AppConfig(freezed)
│   │   └── logging/              # 统一日志：AppLogger + DioLoggingInterceptor
│   ├── data/                     # 数据层
│   │   ├── models/               # freezed 不可变模型（+ json_serializable）
│   │   ├── repositories/         # 抽象 Repository + 生产实现（*_impl.dart）
│   │   ├── services/             # dio_client / api services / 本地与安全存储
│   │   └── exceptions/           # sealed AppException 异常体系
│   └── ui/                       # UI 层（MVVM）
│       ├── core/                 # 跨 feature 共享：router / theme / widgets
│       │   ├── router/           # go_router 集中路由
│       │   ├── theme/            # 主题 token 与明暗切换
│       │   └── widgets/          # 通用组件（AsyncValueView 等）
│       └── features/<name>/      # 业务功能模块
│           ├── view_model/       # Riverpod Notifier/AsyncNotifier
│           └── widgets/          # dumb Widget（只渲染 + 回调）
├── test/                         # 单元 / Widget 测试（目录结构镜像 lib/）
│   ├── fakes/                    # Fake Repository（供测试替换）
│   ├── core/                     # config / logging 测试
│   ├── data/                     # models / services 测试
│   └── ui/                       # theme 与 user feature 测试
├── .github/workflows/            # CI：push / PR 自动执行 analyze + test
├── scripts/                      # 命令行辅助脚本（run.sh：自动启动模拟器 + 按环境一键运行）
├── .qoder/                       # AI 工具链（skills / rules）
├── .vscode/                      # 调试配置模板（launch.example.jsonc）
├── .mcp.json                     # Dart MCP server 接入
├── AGENTS.md                     # AI 协作强制约定
└── pubspec.yaml
```

## 架构设计

### 分层与 MVVM

```
┌─────────────────────────────────────────────┐
│ UI Layer (ui/)                              │
│   Widget（dumb，只渲染 + 回调）                │
│   ViewModel（Riverpod Notifier，持有状态与逻辑）│
├─────────────────────────────────────────────┤
│ Data Layer (data/)                          │
│   Repository（抽象 + Impl）                   │
│   Service（dio / api / storage）             │
│   Model（freezed）/ AppException（sealed）    │
├─────────────────────────────────────────────┤
│ Core (core/)  横切关注点：config / logging    │
└─────────────────────────────────────────────┘
```

核心规则：

- **严格分层**：UI → Data 单向依赖；仅当业务逻辑需被多个 ViewModel 复用时才引入 Domain 层 UseCase。
- **Widget 保持 dumb**：禁止在 Widget 中写业务逻辑或发请求，一切状态与逻辑收敛到 ViewModel。
- **单向数据流**：状态不可变（freezed），UI 只 `ref.watch` 状态 + 调用 ViewModel 方法。
- **Repository 必须是抽象类**：抽象定义与 DI 绑定同文件（如 `user_repository.dart`），生产实现在 `user_repository_impl.dart`，测试用 `test/fakes/` 中的 Fake 一行切换。

### 组合根（Composition Root）

所有需要异步初始化的依赖（SharedPreferences 等）在 [main.dart](lib/main.dart) 中一次性完成创建，再通过 `ProviderScope.overrides` 注入容器；业务层零感知初始化细节：

```dart
final sharedPreferences = await SharedPreferences.getInstance();

runApp(
  ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      // userRepositoryProvider.overrideWithValue(FakeUserRepository()), // 测试切换
    ],
    child: const App(),
  ),
);
```

### 异常体系

[data/exceptions/app_exception.dart](lib/data/exceptions/app_exception.dart) 定义 sealed class 异常：Repository 负责把底层技术异常（DioException、存储异常等）转换为语义化的 `AppException`，UI 层 switch 处理时编译器保证穷举不遗漏：

- `NetworkException` — 网络不可用 / 超时 / 5xx
- `NotFoundException` — 资源不存在（404）
- `CacheException` — 本地缓存读写失败
- `UnknownException` — 未预期异常

> 防护约定：HTTP 200 但响应体为空时，Service 层直接抛 `NotFoundException`（视为资源不存在）——避免 `response.data!` 空断言抛出 Error 形态异常、绕过 Repository 的异常映射把技术细节泄露给 UI 层。

### 全局错误捕获

[main.dart](lib/main.dart) 在 runApp 前挂载全局兜底处理（越早挂载漏网越少），未捕获异常统一收敛到 AppLogger（`f` 级）：

- `FlutterError.onError` — Framework 异常（build / layout 抛错等），记录后仍调 `presentError` 保持 debug 下红屏行为；
- `PlatformDispatcher.instance.onError` — Zone 之外未捕获的异步异常，返回 `true` 抑制控制台噪音。

> 该处是未来接入 Crashlytics / Sentry 的唯一挂点：替换内部上报实现即可，全项目调用点零改动。

### Riverpod 3.x 要点

- family 参数经**构造函数注入**（`FamilyAsyncNotifier` 已移除）；
- 取可空值用 `state.value`（`valueOrNull` 已改名）；
- 完整 3.x 迁移坑位记录见 [AGENTS.md](AGENTS.md) 与 [analysis_options.yaml](analysis_options.yaml) 中 riverpod_lint 插件配置。

## 主题与配色

主题能力位于 [lib/ui/core/theme/](lib/ui/core/theme/)，采用 **shadcn 语义 token + ThemeExtension** 方案，支持运行时明暗切换与持久化。

### token 分层

| 文件 | 职责 |
|---|---|
| [app_colors.dart](lib/ui/core/theme/app_colors.dart) | `AppColors extends ThemeExtension`：21 个 shadcn 语义颜色字段（随主题变化，禁止 static const），light/dark 两套色板 |
| [app_tokens.dart](lib/ui/core/theme/app_tokens.dart) | `AppSpacing`（4px 栅格）/ `AppRadius`：不随主题变化，保持 `static const` |
| [app_theme.dart](lib/ui/core/theme/app_theme.dart) | ThemeData 组装：AppColors 挂载到 `Theme.extensions`，Material 组件经 `toColorScheme()` 显式映射取色（零算法派生） |
| [app_theme_mode.dart](lib/ui/core/theme/app_theme_mode.dart) | `ThemeModeNotifier`：system/light/dark 三态，切换时先落盘再更新状态 |
| [theme_ext.dart](lib/ui/core/theme/theme_ext.dart) | 消费收口：`context.colors` / `context.isDarkMode` |

### 关键设计

- **语义化命名**：background / muted / destructive / ring 等与设计稿 token 一一对应，填色零翻译；
- **运行时换肤**：颜色是 ThemeExtension 实例而非常量，随 `themeMode` 切换全树自动换肤；
- **lerp 必须逐字段实现**：明暗过渡期 Flutter 会对 ThemeExtension 插值，缺失会在过渡期抛异常；
- **持久化**：`ThemeModeStorage`（data 层）经 SharedPreferences 读写，非法值安全回落 system；
- **暗色主色提亮**：保证暗底对比度。

### 色板一览

| Token | Light | Dark |
|---|---|---|
| primary | `#4F6DF5` | `#8B9DF9` |
| background | `#FFFFFF` | `#09090B` |
| foreground | `#09090B` | `#FAFAFA` |
| card | `#FFFFFF` | `#18181B` |
| muted | `#F4F4F5` | `#27272A` |
| mutedForeground | `#71717A` | `#A1A1AA` |
| accent | `#EEF2FF` | `#262B45` |
| destructive | `#DC2626` | `#EF4444` |
| border | `#E4E4E7` | `#27272A` |
| success | `#16A34A` | `#4ADE80` |
| warning | `#D97706` | `#FBBF24` |
| info | `#2563EB` | `#60A5FA` |

> 品牌主色为 seed 蓝 `#4F6DF5`（暗色提亮为 `#8B9DF9`），中性色采用 shadcn zinc 系列。完整 21 字段见源码。

### 使用方式

```dart
// Widget 中取色：唯一入口，禁止散落 Theme.of(context).extension<AppColors>()
final colors = context.colors;
Container(color: colors.muted);

// 间距 / 圆角：编译期常量，无需 context
SizedBox(height: AppSpacing.lg);
BorderRadius.circular(AppRadius.md);

// 判断暗色
if (context.isDarkMode) { ... }
```

## 日志设计

日志是横切关注点，位于 [lib/core/logging/](lib/core/logging/)，**全项目禁止 `print`、禁止直接 import logger 包**，统一经 [AppLogger](lib/core/logging/app_logger.dart) 出口（`appLoggerProvider` 注入）。

- **五级 API**：`d`（高频流程跟踪）/ `i`（重要节点）/ `w`（可恢复异常）/ `e`（错误 + 堆栈）/ `f`（致命）；
- **debug 模式**：PrettyPrinter 彩色分级输出，时间戳 + 耗时；
- **release 模式**：DevelopmentFilter 全静默——零 IO、零信息泄漏；
- **可替换**：未来接入 Sentry / Crashlytics 时替换内部实现即可，所有调用点零改动；
- **测试友好**：构造函数可注入带自定义 LogOutput 的 Logger 实例以捕获日志做断言。

网络日志由 [DioLoggingInterceptor](lib/core/logging/dio_logging_interceptor.dart) 统一走 AppLogger：请求/响应为 `d` 级（含耗时），异常为 `e` 级（携带 DioException 与堆栈），替代 dio 自带 LogInterceptor 的 print 系直出。

## 多环境配置

采用「env 文件 + dart-define-from-file」方案，环境在**编译期**确定，运行期只读。

| 文件 | APP_ENV | baseUrl | 超时 |
|---|---|---|---|
| [env/dev.json](env/dev.json) | dev | `https://jsonplaceholder.typicode.com` | 10s |
| [env/staging.json](env/staging.json) | staging | `https://staging.api.example.com` | 10s |
| [env/prod.json](env/prod.json) | prod | `https://api.example.com` | 15s |

配置收敛链路（[lib/core/config/app_config.dart](lib/core/config/app_config.dart)）：

```
运行命令 --dart-define-from-file=env/<env>.json
  → EnvConstants（String.fromEnvironment，每项带安全缺省值）
  → AppConfig（freezed 不可变，AppEnvironment 枚举）
  → appConfigProvider（唯一出口，dioProvider 等消费）
```

安全约定：

- 环境文件入库，但**只放非敏感配置**（baseUrl、超时）；
- **API Key / Secret 禁止走 dart-define**（会进编译产物被提取），由后端代理签发；
- 不传任何 dart-define 直接运行时，安全回落 dev + 公共演示 API，工程开箱可跑；
- 启动时 main.dart 打印当前环境与 baseUrl 便于确认。

## 路由设计

[lib/ui/core/router/app_router.dart](lib/ui/core/router/app_router.dart) 集中声明全部路由（`goRouterProvider`）：

- 路由名收敛为 `AppRoute` 枚举，杜绝魔法字符串；
- **页面间只传 ID 不传对象**（如 `/users/:id`），天然支持深链接与状态恢复；
- 详情页数据由各自 ViewModel 按 ID 加载，页面自身无状态依赖；
- 禁止在业务代码直接调用 Navigator 1.0 API。

## 测试策略

```bash
fvm flutter test
```

测试组织约定：`test/` 目录结构镜像 `lib/`，测试文件命名为 `<被测文件名>_test.dart`；共享 Fake 统一放 `test/fakes/`。

| 位置 | 覆盖内容 |
|---|---|
| `test/fakes/` | Fake Repository（如 FakeUserRepository），配合 ProviderScope override 替换真实数据源 |
| `test/core/config/` | 环境解析与缺省回落 |
| `test/core/logging/` | DioLoggingInterceptor（自定义 HttpClientAdapter mock） |
| `test/data/models/` | 模型 JSON 序列化 |
| `test/data/services/` | UserApiService 响应解析与空响应防护 |
| `test/ui/core/theme/` | AppColors lerp/映射、ThemeMode 持久化 |
| `test/ui/features/user/` | ViewModel 状态流转 |

## 静态检查与 Lint

[analysis_options.yaml](analysis_options.yaml) 在 `flutter_lints` 推荐集之上启用项目增强规则：

- **riverpod_lint 插件**（基于 analysis_server_plugin）：检测 ProviderScope 缺失、family 参数缺陷、Notifier 封装破坏等架构错误；
- **异步安全**：`unawaited_futures`、`avoid_void_async`；
- **依赖治理**：`depend_on_referenced_packages`；
- **不可变优先**：`prefer_final_locals`、`prefer_final_in_for_each`；
- **一致性**：`always_declare_return_types`、`directives_ordering`、`prefer_relative_imports`（lib 内统一相对导入）、`sort_pub_dependencies`；
- **性能与可维护性**：`avoid_slow_async_io`、`avoid_function_literals_in_foreach_calls`、`unnecessary_lambdas` 等。

> **注意**：`fvm flutter analyze` 不会加载 riverpod_lint 插件，完整检查必须用 `fvm dart analyze`。

提交前验证标准（全绿才可提交；CI 会自动执行同样检查，见 `.github/workflows/ci.yaml`）：

```bash
fvm dart analyze   # 0 issues
fvm flutter test   # all passed
```

## 持续集成（CI）

[.github/workflows/ci.yaml](.github/workflows/ci.yaml) 与本地验证标准完全一致，push 到 main/master 或提 PR 时自动执行：

- **SDK 版本直接读 `.fvmrc`**（subosito/flutter-action），CI 无需安装 FVM，与本地版本天然一致；
- **并发去重**：同一分支 / PR 的旧运行自动取消，节省 CI 时长；
- **门禁**：`dart analyze --fatal-infos`（info 级也视为失败，对齐「0 issues」标准）+ `flutter test` 全量通过。

## AI 协作工具链

本项目为 AI 编程助手（Qoder Agent 等）配备了完整的工具链，配置分布如下：

| 位置 | 作用 |
|---|---|
| [AGENTS.md](AGENTS.md) | AI 协作强制约定：命令前缀、架构规则、技术栈声明（压制冲突技能）、环境与验证标准 |
| [.mcp.json](.mcp.json) | Dart MCP server（`fvm dart mcp-server`）：支持运行中 App 的热重载、调试、 Flutter 工具链操作 |
| `.qoder/rules/flutter-hot-reload.md` | 触发式规则：编辑 `lib/**` 下 Dart 文件后自动经 Dart MCP 触发热重载/热重启 |
| `.qoder/skills/` | 26 个 Agent Skills：Dart 工程化（单测/覆盖率/静态分析/模式匹配等）、Flutter 架构/测试/布局、Riverpod 全套（providers/consumers/testing/auto-dispose/cancel）、设计工程（emil-design-eng） |
| [skills-lock.json](skills-lock.json) | Skills 版本锁定（来源仓库 + 内容哈希），保证团队/CI 一致性 |

> Skills 内容与项目技术栈声明的冲突处理规则：以 AGENTS.md 为准（如本项目用 dio 不用 http 包、用 freezed 不手写序列化）。

## 常用命令速查

```bash
fvm flutter pub get                                        # 安装依赖
fvm flutter pub add <包>                                    # 添加依赖
fvm flutter run --dart-define-from-file=env/dev.json       # 指定环境运行
fvm flutter pub run build_runner build --delete-conflicting-outputs  # 改 freezed/json 模型后必须执行
fvm dart analyze                                           # 静态检查（含 riverpod_lint）
fvm flutter test                                           # 全量测试
```

> 修改任何 `@freezed` / `@JsonSerializable` 模型后，必须重跑 build_runner 生成 `.freezed.dart` / `.g.dart`，否则编译失败。
