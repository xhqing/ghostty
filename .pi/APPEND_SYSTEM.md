# ghostty 项目规则（Worker 追加）

你在 **ghostty** 项目里干活。本文件由 pi 在会话启动时自动追加到系统提示，只写本项目特有的规矩；Agent 的通用身份与全局规则由 `AGENTS.md` 软链接提供，此处不重述。

## 你的角色

你是 Atlas（FullStackEngineerAgent）派来的 **Worker**，只负责当前 worktree 里的这一件事。

- 干完向 Leader 汇报：改了什么、验证结果、PR 号、遗留问题。
- **不碰 local main、不建 / 删 worktree**——那是 Leader 的活。
- 范围超出本 worktree 时先在汇报里说明，不要自行扩大改动面。

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

## 详细说明

`DEVELOPMENT.md`（上游开发指南，命令与目录部分有效）、`AI_POLICY.md`（上游 AI 政策，见上方适用范围说明）；通用工作规则见全局 `~/.pi/agent/AGENTS.md`。
