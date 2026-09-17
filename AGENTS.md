# AGENTS.md

本文件是 AI 编程助手（Qoder Agent 等）在本项目工作的强制约定。
**当本文件与任何通用 Flutter/Dart 技能（skills）或通用最佳实践冲突时，以本文件为准。**

## 命令约定（FVM 项目，全局无 dart/flutter 命令）

所有 Flutter/Dart 命令必须加 `fvm` 前缀（SDK 由 `.fvmrc` 锁定 3.47.0）：

```bash
fvm flutter pub add <包>
fvm flutter pub run build_runner build --delete-conflicting-outputs  # 改 freezed/json 模型后必须执行，否则编译失败
fvm flutter test
fvm dart analyze    # 静态检查必须用这个（fvm flutter analyze 不加载 riverpod_lint 插件）
```

- 修改任何 `@freezed` / `@JsonSerializable` 模型后，必须重跑 build_runner。
- 完整 lint 检查（含 riverpod_lint 规则）只能用 `fvm dart analyze`，`fvm flutter analyze` 会静默跳过插件。

## 架构（严格分层 + MVVM）

```
lib/
├── core/            # 横切关注点：config（环境）、logging（AppLogger）
├── data/
│   ├── models/      # freezed 不可变模型（+ json_serializable）
│   ├── repositories/  # 抽象 Repository + 实现（Impl）
│   ├── services/    # dio_client / api services / local storage
│   └── exceptions/  # sealed AppException 体系
└── ui/
    ├── core/        # router（go_router）、theme、共享组件
    └── features/<name>/view_model/ + widgets/
```

- **Repository 必须是抽象类**（与 DI 绑定同文件），实现类在 `*_impl.dart`；测试用 Fake 替换（见 `test/fakes/`）。
- **Widget 保持 dumb**：禁止在 Widget 中写业务逻辑/数据请求；ViewModel（Riverpod Notifier/AsyncNotifier）持有状态与逻辑。
- **单向数据流**：状态不可变，UI 只 watch 状态 + 调用 ViewModel 方法。
- Riverpod 3.x 要点：family 参数经**构造函数注入**（`FamilyAsyncNotifier` 已移除）；取可空值用 `state.value`（`valueOrNull` 已改名）。
- go_router：页面间**只传 ID**（不传对象），详情页数据由各自 ViewModel 按 ID 加载。

## 技术栈声明（压制冲突技能）

| 场景 | 本项目做法 | 禁止引入的替代方案 |
|---|---|---|
| 网络请求 | `dio`（`dioProvider`） | http 包（不用 `flutter-use-http-package` 技能） |
| JSON 序列化 | `freezed` + `json_serializable` + build_runner | 手写 dart:convert fromJson/toJson（不用 `flutter-implement-json-serialization` 技能） |
| 状态/DI | `flutter_riverpod` 3.x | bloc/getx/provider |
| 导航 | `go_router`（`goRouterProvider`） | Navigator 1.0 直接调用 |
| 日志 | `AppLogger`（`appLoggerProvider` 注入，lib/core/logging/） | `print` / 直接 import logger 包 / LogInterceptor |

## 环境配置（多环境）

- 环境文件：`env/dev.json` / `env/staging.json` / `env/prod.json`（入库，仅非敏感配置）。
- 运行：`fvm flutter run --dart-define-from-file=env/<env>.json`；VSCode 调试配置见 `.vscode/launch.example.jsonc`。
- 配置收敛：`lib/core/config/app_config.dart`（`AppEnvironment` 枚举 + freezed `AppConfig` + `appConfigProvider`），缺省安全回落 dev。
- **敏感值（API Key/Secret）禁止走 dart-define**（会进编译产物），由后端代理签发。

## 验证标准

提交前必须全绿：

```bash
fvm dart analyze   # 0 issues
fvm flutter test   # all passed
```

测试组织：`test/` 目录结构镜像 `lib/`，测试文件命名为 `<被测文件名>_test.dart`；共享 Fake 放 `test/fakes/`（不要在 lib 内写测试辅助类）。
