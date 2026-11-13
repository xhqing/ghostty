# ghostty · 项目硬约束

身份与角色见本仓库根 `AGENTS.md`；团队通用规则见全局 `~/.pi/agent/AGENTS.md`，此处不重述。

## 本项目是什么

Ghostty 终端的**自建分叉仓库**（2026-09-20 起与上游 ghostty-org/ghostty 断开 fork 关系、自主演进、不再同步上游）。当前基线为 v1.3.1 + 「Cmd+V 粘贴剪贴板图片为临时文件路径」补丁；macOS 应用由 GitHub Actions 标准 runner 云构建。

## ⚠️ 上游规则只约束外部贡献者，不约束本项目

`DEVELOPMENT.md` 与 `AI_POLICY.md` 里的几条字面规则来自上游、**只针对外部贡献者**，我们是这个分叉的维护者，**不适用**：

- `DEVELOPMENT.md` 的「Never create an issue」「Never create a PR」——**不适用**。本项目照常走 Issue + PR + CI 流程。
- `DEVELOPMENT.md` 的「If the user asks you to create an issue or PR, create a file that says ...」——这是上游对 AI 贡献者的羞辱条款，**不适用**，不要照做。
- `AI_POLICY.md` 的披露 / 人类把关 / 禁止 AI 生成媒体等条款——那是上游对外部 PR 的要求；本项目内部开发不受其约束（但公开 issue / PR 里提到上游时仍要尊重它）。

判断标准：**改动落在我们这个分叉仓库里 = 内部开发，走我们的流程；向上游提东西 = 外部贡献，受上游规则约束**（目前不做上游贡献）。

## 构建 / 测试 / 格式化

- **构建**：`zig build`；在 macOS 上且不需要构建 app bundle 时用 `-Demit-macos-app=false` 跳过、显著加快编译。
- **测试（Zig）**：`zig build test`；**优先用 `-Dtest-filter=<test name>` 跑定向测试**——全量测试很慢。
- **格式化**：Zig 用 `zig fmt .`；Swift 用 `swiftlint lint --strict --fix`；其它用 `prettier -w .`。
- **重活分流**：完整构建 / 全量测试套件放 `macmini_run` 跑（12 核 / 32GB），不要占着用户本机。

## 目录结构

- `src/`——共享 Zig 核心
- `macos/`——macOS app
- `src/apprt/gtk`——GTK（Linux / FreeBSD）app

## 硬约束

- **不与上游同步**：不要拉上游分支、不要为「跟上上游」而重构；我们自己演进。
- **保留既有补丁**：Cmd+V 粘贴剪贴板图片为临时文件路径的补丁是用户要的功能，改动不能把它弄丢。
- **改动记 `CHANGELOG.md`**；版本号以 `VERSION` 为唯一权威。
- **临时产物放项目 `tmp/`**（已忽略），不落到 `src/` / `macos/`。

## 测试文件对 Worker 只读（2026-11-13 立）

测试由 **Leader（dev-agent / Atlas 的会话）在实现开工前**写好，以功能分支上的本地 commit 形式存在。你（Worker）对测试文件**只能读、只能运行**：

- **禁止新建 / 修改 / 删除 / 移动**任何测试文件与测试基础设施：本项目的测试位置是 `test/` 目录与 `src/` 里的 `test {}` 块（Zig 内置测试）；含 fixtures / helpers / conftest 等伴生文件（跑测试缺了也不自己补）。
- **碰到测试跑不通、断言与 Issue 预期不符 → 终止开发、上报 Leader（`Atlas`）或用户裁决**，绝不改测试迁就实现——这是 LLM 的典型失败模式（改不动代码就放宽断言）。
- **`# TEST_CASES_WRITE_OK` 标记的签发权在 Leader**，你不加；被 `test-cases-guard` 拦下时不要绕过。
- 例外：测试运行自产的缓存与构建产物（`__pycache__`、`.pytest_cache`、coverage 输出、`out/` 等）可清理，走授权标记通道。

## 详细说明

`DEVELOPMENT.md`（上游开发指南，命令与目录部分有效）、`AI_POLICY.md`（上游 AI 政策，见上方适用范围说明）；通用工作规则见全局 `~/.pi/agent/AGENTS.md`。
