# Changelog (fork)

本文件记录本仓库的全部变更。仓库已于 2026-09-20 与原上游 `ghostty-org/ghostty` 断开 fork 关系（GitHub `fork: false`），独立分叉自主维护、不自动同步上游；上游自身变更见上游仓库。

## 未发布（2026-09-20）

### 变更

- **main 分支保护：只能通过 PR 提交并通过 CI（build-macos）后自动合并**。为什么改：用户要求锁定 main，杜绝直接 push，所有变更走 PR + CI 门禁。改了什么：①分支保护规则（required check = build-macos、strict 最新要求、enforce_admins 对管理员同样生效、禁 force push 与删除）；②仓库开启 allow_auto_merge；③同步移除 `build.yml` 的 paths 过滤——否则纯文档 PR 不触发 CI、required check 永不出现，PR 无法满足合并条件；④Release `v1.3.1-paste.1` 转为预发布。

- **断开与上游的 fork 关系，转为独立分叉仓库自主维护**。为什么改：用户决定本仓库长期自主演进、不再跟随上游同步（与 pi 同模式）。改了什么：①GitHub 侧仓库已是独立仓库状态（`fork: false`、无 parent）；②`main` 分支重置到补丁线顶端（v1.3.1 + 补丁 + 文档，丢弃 fork 时携带的上游 main 快照）；③删除 7 个上游遗留远程分支（1.1.x、1.2.x、1.3.x、offset-audit、push-tuwykoykluyz、setneedle-crash、tristan957/gtk-ng）；④仓库描述改为独立 fork 说明；⑤`MEMO.md` M1 从「上游发版 rebase」改写为「自主判断、手动移植上游重要改进」。

## v1.3.1-paste.1（2026-09-20）

基于上游 `v1.3.1`（commit `332b2aefc`）。

### 新增

- **macOS：Cmd+V 粘贴剪贴板图片为临时文件路径**（`macos/Sources/Helpers/Extensions/NSPasteboard+Extension.swift`）
  - 解决的问题：macOS 截图直接进剪贴板（Cmd+Shift+Ctrl+4）后，Ghostty 里按 Cmd+V 静默无反应——剪贴板里只有 PNG/TIFF 图片数据，没有文本也没有文件 URL，`getOpinionatedStringContents()` 只认文件 URL 和字符串，返回 nil。
  - 改动逻辑：在字符串分支之后新增兜底分支——检测到图片数据时写入 `$TMPDIR/ghostty-paste-<UUID>.png`（TIFF 自动转 PNG），把转义后的路径作为粘贴文本返回。放在最后兜底，现有粘贴行为（文件 URL → 路径、纯文本 → 原样）零变化。
  - 效果：TUI 应用（Claude Code、pi 等）通过 Cmd+V 收到图片路径文本，自行读取图片。与 cmux（宿主层实现）和 Warp（GUI 层拦截）同思路，本补丁在终端自身读取层实现。
  - 方案来源：ghostty-org/ghostty#11571（该 PR 因作者未被 vouch 被自动关闭，技术方案经本 fork 独立验证后落地，分支位置调整为最后兜底）。

- **CI：`.github/workflows/build.yml`**——标准 GitHub `macos-26` runner 云构建 Ghostty.app（上游官方 workflow 依赖自托管 runner，fork 用不了）。
  - 步骤：Xcode 26.2（上游 v1.3.1 官方构建同款，26.6 的 SDK 与 Zig 0.15.2 链接不兼容）→ Zig 0.15.2（注意 0.15.2 起 tarball 命名为 `zig-aarch64-macos-*`）→ Sparkle 2.9.6 → `zig build -Demit-macos-app=false` → `xcodebuild` → 改 Info.plist 版本信息 → ad-hoc 重签（顺序必须「先改 plist 后签名」，反了会破坏签名导致 LaunchServices 打不开，报 -54）→ 打 zip 上传 artifact。

### 变更

- fork 内禁用了上游继承的 `Test` / `Nix` workflow（防止误触发消耗 runner 分钟数）。
