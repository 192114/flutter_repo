# flutter_repo

基于 Flutter 的分层架构模板工程：**严格分层 + MVVM**，内置中英文本地化、语义化主题（明暗切换）、一套移动端通用组件库与 Gallery 组件展示页、图片上传与裁剪流程、统一日志、集中路由与 AI 协作工具链，开箱即用，可直接作为新项目的脚手架。

## 目录

- [技术选型](#技术选型)
- [快速开始](#快速开始)
- [运行与调试](#运行与调试)
- [项目结构](#项目结构)
- [架构设计](#架构设计)
- [主题与配色](#主题与配色)
- [品牌与原生启动页](#品牌与原生启动页)
- [本地化](#本地化)
- [通用组件库与 Gallery](#通用组件库与-gallery)
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
| 本地化 | `flutter_localizations` + `intl`（gen-l10n） | 中英双语 arb，中文优先 |
| 日志 | `logger`（封装为 `AppLogger`） | 全项目唯一日志出口 |
| 本地存储 | `shared_preferences` | 主题模式等非敏感持久化 |
| 安全存储 | `flutter_secure_storage` | Token 等敏感值 |
| 图片选择 | `image_picker` | 上传与裁剪流程的选图入口 |
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

启动后首屏为用户列表页；AppBar 右侧「组件库」图标进入 [Gallery 组件展示页](#通用组件库与-gallery)，主题菜单可运行时切换明暗。

日常开发推荐一键脚本或 IDE 调试（含热重载说明），见 [运行与调试](#运行与调试)。

## 运行与调试

两种启动方式二选一：**命令行一键脚本**（不依赖 IDE）或 **VSCode 调试面板**。

### 命令行：一键脚本

[scripts/run.sh](scripts/run.sh) 自动完成全流程：检测目标模拟器是否已启动 → 未启动则后台启动并阻塞等待系统就绪（iOS 用 `simctl bootstatus`，Android 轮询 `sys.boot_completed`）→ 按环境执行 `fvm flutter run -d ... --dart-define-from-file=...`：

```bash
./scripts/run.sh                   # dev + iOS 模拟器（macOS 缺省）
./scripts/run.sh staging           # staging + iOS
./scripts/run.sh android           # dev + Android 模拟器
./scripts/run.sh android staging   # Android + staging（环境与平台参数顺序任意、均可省略）

# 目标设备可用环境变量覆盖：
SIMULATOR="iPhone 16e" ./scripts/run.sh dev       # iOS 模拟器名（缺省 iPhone 17 Pro）
AVD="Pixel_7_Pro" ./scripts/run.sh android dev    # Android AVD 名（缺省取列表第一个）
```

- 脚本自动定位项目根目录，从其他目录通过脚本路径调用也能正确找到环境文件；
- 环境参数白名单 dev / staging / prod（对应 `env/*.json`），拼错直接报错退出，不静默回落；
- iOS 依赖 `xcrun simctl`（仅 macOS），模拟器名不存在时列出全部可用设备便于修正；
- Android 依次探测 `ANDROID_HOME` / `ANDROID_SDK_ROOT` / `~/Library/Android/sdk` / `~/Android/Sdk` 定位 emulator 与 adb；AVD 不存在时列出全部可用 AVD；启动失败或超时会打印 emulator 日志末尾便于排查；
- 非 macOS 且未指定平台时跳过模拟器启动，由 flutter 自动选择已连接设备。

### 命令行：手动等价命令

不使用脚本时的等价手动流程：

```bash
# iOS
xcrun simctl boot "iPhone 17 Pro"            # 启动模拟器
xcrun simctl bootstatus "iPhone 17 Pro" -b   # 阻塞等待系统就绪
open -a Simulator                            # 显示模拟器窗口
fvm flutter run -d "iPhone 17 Pro" --dart-define-from-file=env/dev.json

# Android
~/Library/Android/sdk/emulator/emulator -avd Pixel_7_Pro &   # 后台启动 AVD
adb -s emulator-5554 shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done'
fvm flutter run -d emulator-5554 --dart-define-from-file=env/dev.json
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
├── l10n.yaml                     # gen-l10n 配置（arb 目录、中文优先）
├── lib/
│   ├── main.dart                 # 入口：组合根（全局错误处理 + bootstrap + Provider overrides）
│   ├── app.dart                  # 根 Widget：MaterialApp.router + 主题模式 + l10n 装配
│   ├── core/                     # 横切关注点（与业务无关）
│   │   ├── config/               # 多环境配置：AppEnvironment + AppConfig(freezed)
│   │   └── logging/              # 统一日志：AppLogger + DioLoggingInterceptor
│   ├── data/                     # 数据层
│   │   ├── models/               # freezed 不可变模型（+ json_serializable）
│   │   ├── repositories/         # 抽象 Repository + 生产实现（*_impl.dart）
│   │   ├── services/             # dio_client / api / 本地与安全存储 / 裁剪会话
│   │   └── exceptions/           # sealed AppException 异常体系
│   ├── l10n/                     # gen-l10n 产物（入库）：AppLocalizations + en/zh 实现
│   └── ui/                       # UI 层（MVVM）
│       ├── core/                 # 跨 feature 共享
│       │   ├── router/           # go_router 集中路由
│       │   ├── theme/            # 主题 token 与明暗切换
│       │   └── widgets/          # 通用组件库（表单/选择器/反馈/图片等，内嵌 Widget Preview）
│       └── features/
│           ├── user/             # 用户列表 / 详情（view_model/ + widgets/）
│           ├── gallery/          # 组件库演示页（8 组 demo + 索引页）
│           └── image_crop/       # 图片裁剪（会话式全屏编辑）
├── test/                         # 单元 / Widget 测试（45 个文件，目录结构镜像 lib/）
│   ├── fakes/                    # Fake / 可控 Repository、失败存储（供测试替换）
│   ├── core/  data/              # config / logging / models / repositories / services
│   ├── ui/core/widgets/          # 通用组件测试（渲染 / 交互 / 明暗 / 无障碍）
│   └── ui/features/              # user / gallery / image_crop
├── .github/workflows/ci.yaml     # CI：格式、代码生成一致性、analyze + test
├── scripts/                      # run.sh：一键运行；check.sh：格式检查 + analyze + test
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
│   Service（dio / api / storage / 裁剪会话）   │
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

[main.dart](lib/main.dart) 的 `bootstrap` 先校验环境配置，再初始化 SharedPreferences，成功后通过 `ProviderScope.overrides` 注入同一份配置和存储实例；业务层零感知初始化细节：

```dart
final config = loadConfig();
final sharedPreferences = await loadPreferences();

runApp(
  ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
    child: const App(),
  ),
);
```

初始化失败（配置校验不通过、存储不可用等）时进入独立的 [StartupFailureApp](lib/ui/core/widgets/startup_failure_app.dart) 启动失败页：展示可读的错误提示、支持重试且阻止重复点击，不泄露底层异常详情。重试会**新建 ProviderScope 容器**（避免在已有容器上改变 overrides 数量）并复用同一注入函数。`loadConfig` / `loadPreferences` 均为可注入参数，测试中配合 [test/fakes/failing_shared_preferences_store.dart](test/fakes/failing_shared_preferences_store.dart) 即可覆盖「初始化失败 → 重试恢复」路径。

### 异常体系

[data/exceptions/app_exception.dart](lib/data/exceptions/app_exception.dart) 定义 sealed class 异常：Repository 负责把底层技术异常（DioException、存储异常等）转换为语义化的 `AppException`，UI 层 switch 处理时编译器保证穷举不遗漏：

- `NetworkException` — 网络连接失败 / 超时
- `NotFoundException` — 资源不存在（404）
- `CacheException` — 本地缓存读写失败
- `UnknownException` — 其他 HTTP 错误（含 5xx）、响应解析失败及未预期异常

> 防护约定：HTTP 200 但响应体为空时，Service 层直接抛 `NotFoundException`（视为资源不存在）——避免 `response.data!` 空断言抛出 Error 形态异常、绕过 Repository 的异常映射把技术细节泄露给 UI 层。

### 全局错误捕获

[main.dart](lib/main.dart) 在 runApp 前挂载全局兜底处理（越早挂载漏网越少），未捕获异常统一收敛到 AppLogger（`f` 级）：

- `FlutterError.onError` — Framework 异常（build / layout 抛错等），记录后仍调 `presentError` 保持 debug 下红屏行为；
- `PlatformDispatcher.instance.onError` — 未被 Zone 等处理的根 isolate 异步异常；非 release 返回 `true` 抑制重复输出，release 返回 `false` 交还平台默认处理，保留崩溃痕迹。

> 该处是未来接入 Crashlytics / Sentry 的唯一挂点：替换内部上报实现即可，全项目调用点零改动。

### Riverpod 3.x 要点

- family 参数经**构造函数注入**（`FamilyAsyncNotifier` 已移除），如 [image_crop_view_model.dart](lib/ui/features/image_crop/view_model/image_crop_view_model.dart) 的 `NotifierProvider.autoDispose.family`；
- 取可空值用 `state.value`（`valueOrNull` 已改名）；
- 完整 3.x 迁移坑位记录见 [AGENTS.md](AGENTS.md) 与 [analysis_options.yaml](analysis_options.yaml) 中 riverpod_lint 插件配置。

## 主题与配色

主题能力位于 [lib/ui/core/theme/](lib/ui/core/theme/)，采用 **shadcn 语义 token + ThemeExtension** 方案，支持运行时明暗切换与持久化。

### token 分层

| 文件 | 职责 |
|---|---|
| [app_colors.dart](lib/ui/core/theme/app_colors.dart) | `AppColors extends ThemeExtension`：22 个 shadcn 语义颜色字段（+ Brightness 标记，随主题变化，禁止 static const），light/dark 两套色板 |
| [app_tokens.dart](lib/ui/core/theme/app_tokens.dart) | `AppSpacing`（4px 栅格，xs~xxxl）/ `AppRadius`（xs~xl + full，附 `circular()` 快捷）：不随主题变化，保持 `static const` |
| [app_theme.dart](lib/ui/core/theme/app_theme.dart) | ThemeData 组装：AppColors 挂载到 `Theme.extensions`，Material 组件经 `toColorScheme()` 显式映射取色（零算法派生） |
| [app_theme_mode.dart](lib/ui/core/theme/app_theme_mode.dart) | `ThemeModeNotifier`：system/light/dark 三态，切换时先落盘再更新状态 |
| [theme_ext.dart](lib/ui/core/theme/theme_ext.dart) | 消费收口：`context.colors` / `context.isDarkMode` |

### 关键设计

- **语义化命名**：background / muted / destructive / ring 等与设计稿 token 一一对应，填色零翻译；
- **运行时换肤**：颜色是 ThemeExtension 实例而非常量，随 `themeMode` 切换全树自动换肤；
- **lerp 必须逐字段实现**：明暗过渡期 Flutter 会对 ThemeExtension 插值，缺失会在过渡期抛异常；
- **前景色成对取用**：primary / success / warning / destructive 等均配有对应 `*Foreground` 字段，组件按「底色 + 前景色」成对使用，保证两套主题下的文字对比度（无障碍）；
- **持久化**：`ThemeModeStorage`（data 层）经 SharedPreferences 读写，非法值安全回落 system；
- **暗色主色提亮**：保证暗底对比度。

### 色板一览

| Token | Light | Dark |
|---|---|---|
| primary | `#465BF0` | `#8B9DF9` |
| background | `#FFFFFF` | `#09090B` |
| foreground | `#09090B` | `#FAFAFA` |
| card | `#FFFFFF` | `#18181B` |
| muted | `#F4F4F5` | `#27272A` |
| mutedForeground | `#71717A` | `#A1A1AA` |
| accent | `#EEF2FF` | `#262B45` |
| destructive | `#D11F1F` | `#EF4444` |
| border | `#E4E4E7` | `#27272A` |
| success | `#16A34A` | `#4ADE80` |
| warning | `#D97706` | `#FBBF24` |
| info | `#2563EB` | `#60A5FA` |

> 品牌主色为 seed 蓝 `#465BF0`（暗色提亮为 `#8B9DF9`），中性色采用 shadcn zinc 系列。完整 22 字段（含各 `*Foreground`、input、ring）见源码。

### 使用方式

```dart
// Widget 中取色：唯一入口，禁止散落 Theme.of(context).extension<AppColors>()
final colors = context.colors;
Container(color: colors.muted);

// 间距 / 圆角：编译期常量，无需 context
SizedBox(height: AppSpacing.lg);
AppRadius.circular(AppRadius.md);

// 判断暗色
if (context.isDarkMode) { ... }
```

## 品牌与原生启动页

App 已完成品牌化（橙色小幽灵图标 + 橙黑暖光启动页），资源分布在两侧原生工程：

- **iOS**：`ios/Runner/Assets.xcassets/AppIcon.appiconset`（1024 母版及全套尺寸）、`LaunchBackground` / `LaunchImage` imageset + `LaunchScreen.storyboard`；
- **Android**：`mipmap-anydpi-v26` 自适应图标（前景 / 背景分层，附各密度位图）、`launch_background.xml` 及 Android 12+ SplashScreen 资源（`splash_foreground` / `splash_branding`，含横屏与 `values-night` 暗色变体）；
- 系统栏颜色统一为 `splash_orange #FF6904`（`values/colors.xml`，供启动期状态栏 / 导航栏取色）。

替换品牌时同步更新上述资源；Flutter 侧品牌色请继续走 [AppColors](lib/ui/core/theme/app_colors.dart) 语义 token，不要在业务代码写死颜色。

## 本地化

采用 Flutter 官方 gen-l10n 方案（`flutter_localizations` + `intl`），双语、中文优先：

- 配置：[pubspec.yaml](pubspec.yaml) `flutter.generate: true` + 根目录 [l10n.yaml](l10n.yaml)（arb 目录 `lib/l10n`，模板 `app_en.arb`，`preferred-supported-locales: [zh]`）；
- 文案源：[lib/l10n/app_en.arb](lib/l10n/app_en.arb) / [app_zh.arb](lib/l10n/app_zh.arb)，支持占位符参数（如 `deleteLabel {label}`、`toastAnnouncement {status} {message}`）；
- 生成产物 `app_localizations*.dart` **已入库**，与 arb 同目录；
- 装配：[app.dart](lib/app.dart) 在 `MaterialApp.router` 上挂 `localizationsDelegates` + `supportedLocales`；
- 消费：通用组件的内置文案全部经 `AppLocalizations.of(context)!` 取用（含无障碍语义标签），不写死中文。

新增文案流程：arb 加 key（en 模板 + zh 翻译）→ 执行 `fvm flutter gen-l10n` 重新生成（`pub get` / 构建时也会自动触发）→ 一并提交生成产物。

## 通用组件库与 Gallery

通用组件位于 [lib/ui/core/widgets/](lib/ui/core/widgets/)，是「带设计规范的可复用 UI 资产」；每个组件在 [Gallery](#gallery-组件展示页) 有对应演示页。

### 设计约定

- **dumb / 受控**：组件不发请求、不持有业务状态（如 `AppUploadImage` 的上传进度由外部驱动后重建列表项）；
- **取色收口**：一律 `context.colors`；间距圆角走 `AppSpacing` / `AppRadius` 编译期常量；
- **文案走 l10n**，内置文案均双语；
- **明暗成对 @Preview**：按钮 / 输入 / 表单 / 选择 / 标签 / 下拉菜单 / 弹窗 / Toast / 上传等组件文件内嵌 Flutter 3.47 Widget Preview（`package:flutter/widget_previews.dart`），Light/Dark 各一个预览，可在 IDE 中直接查看。

### 组件清单

| 组件 | 能力 |
|---|---|
| `AppButton` | 5 变体（primary / secondary / outline / destructive / text）× 3 尺寸 |
| `AppInput` | 标签 + 输入框 + 错误文案的受控输入 |
| `AppFormCard` / `AppFormItem` | 卡片式表单分组（无分割线），label 支持 top / left 布局 |
| `AppPickerField` 系列 | 表单集成选择字段：`AppPickerField`、`AppFormDateRangeField`、`AppPickerFormField<T>`、`AppDateRangeFormField` |
| `AppRadio` / `AppCheckbox` / `AppSwitch` | 单选 / 多选 / 开关 |
| `AppDatePicker.show` / `AppTimePicker.show` | 底部弹层滚轮选择（日期为年 / 月 / 日三列，中行高亮） |
| `AppCalendarView` | 日历（滚动 / 月切换两种模式，支持日期范围选择） |
| `AppPickerSheet` / `AppSelectorField` / `AppPickerWheel` | 通用数据选择器（单列 / 多列滚轮） |
| `AppTag` | 实心 / 空心 × 5 色 × 3 尺寸，支持删除回调 |
| `AppDropdownMenu` | Vant 风格顶部菜单栏，排序与筛选 |
| `AppAlertDialog` / `AppConfirmDialog` | 弹窗（normal / destructive 意图） |
| `FeedbackToast` / `ToastController` | 轻提示（success / error / warning / loading），新 Toast 替换旧的而非叠加 |
| `AppEmpty` / `AppEmptyIllustration` | 空状态（内置 content / search / favorites 三种插图） |
| `AppUploadImage` | 受控九宫格上传：uploading / success / failed 状态 + 进度 + 重试 |
| `AppImageCropper` | 全屏裁剪：比例切换、旋转、双指缩放拖拽 |
| `AsyncValueView<T>` | AsyncValue 统一三态（加载 / 错误重试 / 数据） |
| `ThemeModeMenu` | AppBar 主题模式切换入口（system / light / dark） |
| `StartupFailureApp` | 启动失败兜底页（重试） |

### Gallery 组件展示页

入口：用户列表页 AppBar「组件库」图标 → `/gallery` 索引页（8 组 demo，宽屏收敛 maxWidth 720）。每组一个独立路由的演示页，复用 `GallerySection` 分区卡片组织内容：

| 分组 | 演示内容 | 路由 |
|---|---|---|
| 反馈组件 | Toast 轻提示与 Dialog 弹窗 | `/gallery/feedback` |
| 下拉菜单 | Vant 风格顶部菜单栏，排序与筛选 | `/gallery/dropdown` |
| 异步状态 | AsyncValueView 加载 / 错误 / 成功三态 | `/gallery/async-value` |
| Design Token | 颜色、圆角与间距规范速查 | `/gallery/tokens` |
| 表单组件 | 按钮、输入、选择控件与各类选择器 | `/gallery/form` |
| 标签 | 实心 / 空心、可删除与三档尺寸 | `/gallery/tag` |
| 图片上传 | 九宫格上传、进度状态与图片剪裁 | `/gallery/upload` |
| 空状态 | 自定义图标、标题、描述与底部操作 | `/gallery/empty` |

### 图片上传与裁剪流程

跨 data / ui 的完整示例（Gallery「图片上传」页可体验）：

1. `AppUploadImage` 触发 `onAdd` 回调，宿主经 image_picker 选图；
2. [ImageCropSessionStore](lib/data/services/image_crop_session_store.dart)（data 层，Provider 持有）以 `create(bytes)` 建立内存会话并返回会话 ID——原图只在内存保留，路由不携带字节；
3. 跳转 `/image-crop/:id`（只传 ID，深链安全；不支持恢复原图），`ImageCropScreen` + [ImageCropViewModel](lib/ui/features/image_crop/view_model/image_crop_view_model.dart)（`NotifierProvider.autoDispose.family`）按 ID 读取；
4. `AppImageCropper` 完成 / 取消后 `complete` / `cancel` 释放会话；ViewModel dispose 时自动兜底释放，防内存泄漏。

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
- 不传任何 dart-define 直接运行时，安全回落 dev + 公共演示 API，工程开箱可跑；未知 `APP_ENV` 仍回落 dev；
- `API_BASE_URL` 必须是主机非空的绝对 HTTP(S) URL，不含空白，显式端口为 1–65535；两项超时必须是正整数毫秒；
- 非法配置在启动时抛出带配置键名、不含原始值的 `FormatException` 并进入启动失败页；编译期配置错误需修正配置后重新运行，点击重试不会改变编译期值；
- 启动时 main.dart 打印当前环境与 baseUrl 便于确认。

## 路由设计

[lib/ui/core/router/app_router.dart](lib/ui/core/router/app_router.dart) 集中声明全部路由（`goRouterProvider`，`AppRoute` 枚举共 12 项，`initialLocation: /users`）：

- 路由名收敛为 `AppRoute` 枚举，杜绝魔法字符串；
- **页面间只传 ID 不传对象**（如 `/users/:id`、`/image-crop/:id`），天然支持深链接与状态恢复；
- `/users/:id` 对外部来源的 ID 做 `int.tryParse` 兜底：非法值（如 `/users/abc`）渲染兜底页而非构建时抛错；
- 详情页数据由各自 ViewModel 按 ID 加载，页面自身无状态依赖；
- Gallery 为 `/gallery` 索引 + 8 个子路由（见上表）；
- 显式 `MaterialPage` 包装页面（go_router 18 的 material_ui 类型识别与 SDK MaterialApp 不兼容）；Provider 销毁时 `ref.onDispose(router.dispose)` 释放资源；
- 禁止在业务代码直接调用 Navigator 1.0 API。

## 测试策略

```bash
fvm flutter test
```

测试组织约定：`test/` 目录结构镜像 `lib/`，测试文件命名为 `<被测文件名>_test.dart`；共享 Fake 统一放 `test/fakes/`。当前共 45 个测试文件：

| 位置 | 覆盖内容 |
|---|---|
| `test/fakes/` | FakeUserRepository / ControllableUserRepository、FailingSharedPreferencesStore（模拟落盘失败，驱动 bootstrap 失败路径） |
| `test/main_test.dart` | bootstrap 成功注入、初始化失败进入 StartupFailureApp、重试恢复 |
| `test/core/config/` | 环境解析、校验与缺省回落 |
| `test/core/logging/` | DioLoggingInterceptor（自定义 HttpClientAdapter mock） |
| `test/data/` | 模型 JSON 序列化；Repository 异常映射；api / 本地存储服务（含空响应防护） |
| `test/ui/core/theme/` | AppColors lerp/映射、ThemeMode 持久化 |
| `test/ui/core/widgets/` | 18 个通用组件测试：渲染、交互、明暗主题与无障碍语义 |
| `test/ui/features/` | user（ViewModel 状态流转、列表搜索/空态/刷新）、gallery（索引页 + 8 个演示页）、image_crop（会话生命周期与页面） |

## 静态检查与 Lint

[analysis_options.yaml](analysis_options.yaml) 在 `flutter_lints` 推荐集之上启用项目增强规则：

- **riverpod_lint 插件**（基于 analysis_server_plugin）：检测 ProviderScope 缺失、family 参数缺陷、Notifier 封装破坏等架构错误；
- **异步安全**：`unawaited_futures`、`avoid_void_async`；
- **依赖治理**：`depend_on_referenced_packages`；
- **不可变优先**：`prefer_final_locals`、`prefer_final_in_for_each`；
- **一致性**：`always_declare_return_types`、`directives_ordering`、`prefer_relative_imports`（lib 内统一相对导入）、`sort_pub_dependencies`；
- **性能与可维护性**：`avoid_slow_async_io`、`avoid_function_literals_in_foreach_calls`、`unnecessary_lambdas` 等。

> **注意**：`fvm flutter analyze` 不会加载 riverpod_lint 插件，完整检查必须用 `fvm dart analyze`。

提交前执行一键检查（需要先安装项目依赖）：

```bash
./scripts/check.sh
```

[scripts/check.sh](scripts/check.sh) 依次执行手写 Dart 格式检查、`fvm dart analyze --fatal-infos` 和 `fvm flutter test`，任一步失败立即退出。脚本自动定位项目根目录，检查不会自动格式化文件或运行代码生成。

格式范围为 `lib/`、`test/` 下的 Dart 文件，排除 `*.g.dart`、`*.freezed.dart`。需要修复格式时执行：

```bash
find lib test -type f -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' -print0 |
  xargs -0 fvm dart format
```

修改模型后仍需先手动执行 build_runner，见[常用命令速查](#常用命令速查)。

## 持续集成（CI）

[.github/workflows/ci.yaml](.github/workflows/ci.yaml) 在 push 到 main/master 或提 PR 时自动执行：

- **SDK 版本直接读 `.fvmrc`**（subosito/flutter-action），CI 无需安装 FVM，与本地版本一致；
- **并发去重**：同一分支 / PR 的旧运行自动取消，节省 CI 时长；
- **依赖与生成产物**：严格按 lockfile 安装依赖，重新执行 build_runner 并检查已跟踪的生成文件无差异；
- **格式门禁**：与 `check.sh` 相同的手写 Dart 范围，仅检查、不写文件；
- **分析与测试**：`dart analyze --fatal-infos`（info 级也视为失败，对齐「0 issues」标准）+ `flutter test` 全量通过。

## AI 协作工具链

本项目为 AI 编程助手（Qoder Agent 等）配备了完整的工具链，配置分布如下：

| 位置 | 作用 |
|---|---|
| [AGENTS.md](AGENTS.md) | AI 协作强制约定：命令前缀、架构规则、技术栈声明（压制冲突技能）、环境与验证标准 |
| [.mcp.json](.mcp.json) | Dart MCP server（`fvm dart mcp-server`）：支持运行中 App 的热重载、调试、 Flutter 工具链操作 |
| `.qoder/rules/flutter-hot-reload.md` | 触发式规则：编辑 `lib/**` 下 Dart 文件后自动经 Dart MCP 触发热重载/热重启 |
| `.qoder/skills/` | 11 个精简版 Agent Skills：Dart（单测、模式匹配、依赖冲突处理）、Flutter（组件测试、组件预览、响应式布局、布局排错）、Riverpod（providers/consumers/testing/auto-dispose） |
| [skills-lock.json](skills-lock.json) | Skills 来源与内容哈希清单，与保留的技能目录同步维护 |

> Skills 内容与项目技术栈声明的冲突处理规则：以 AGENTS.md 为准（如本项目用 dio 不用 http 包、用 freezed 不手写序列化）。

## 常用命令速查

```bash
fvm flutter pub get                                        # 安装依赖
fvm flutter pub add <包>                                    # 添加依赖
fvm flutter run --dart-define-from-file=env/dev.json       # 指定环境运行
fvm flutter pub run build_runner build --delete-conflicting-outputs  # 改 freezed/json 模型后必须执行
fvm flutter gen-l10n                                      # 修改 lib/l10n/*.arb 后重新生成本地化产物
./scripts/check.sh                                        # 格式检查 + 静态分析 + 全量测试
fvm dart analyze --fatal-infos                             # 静态检查（含 riverpod_lint）
fvm flutter test                                           # 全量测试
```

> 修改任何 `@freezed` / `@JsonSerializable` 模型后，必须重跑 build_runner 生成 `.freezed.dart` / `.g.dart`，否则编译失败；gen-l10n 产物已入库，重新生成后请一并提交。
