# Changelog (fork)

本文件只记录本 fork 相对上游 `ghostty-org/ghostty` 的变更，用于跟上游 rebase 时快速对账。上游自身的变更见上游仓库的 release notes。

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
