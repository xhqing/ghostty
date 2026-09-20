# MEMO

超低频备忘（条件触发、无排期压力）。做完移入 `MEMO-archive.md`。

## 🟢 维护

- [ ] **M1** 上游 ghostty 发新 stable tag 时 rebase 补丁并发布（记录：2026-09-20 20:00）
  触发条件：ghostty-org/ghostty 发布新 stable（关注其 release 页）。
  动作：`git fetch upstream tag vX.Y.Z`（或 origin，若已加上游 remote）→ 基于 `paste-image` 分支 rebase（冲突点预期只有 `macos/Sources/Helpers/Extensions/NSPasteboard+Extension.swift` 的 `getOpinionatedStringContents()`）→ 更新 `build.yml` 里的三处版本号（Xcode 路径按上游官方 release-tag.yml 同款、Zig 版本按新 tag 的 `build.zig.zon` `minimum_zig_version`、`-Dversion-string` 与 Info.plist）→ 云构建 → 本机验证 Cmd+V 贴图 → 打 `vX.Y.Z-paste.N` tag + Release → 从 Release 替换本机。
