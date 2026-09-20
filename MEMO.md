# MEMO

超低频备忘（条件触发、无排期压力）。做完移入 `MEMO-archive.md`。

## 🟢 维护

- [ ] **M1** 跟进上游 Ghostty 的重要改进（记录：2026-09-20 20:30）
  背景：本仓库已于 2026-09-20 与原上游 ghostty-org/ghostty 断开 fork 关系、独立分叉自主维护，**不自动同步上游**。
  触发条件：自主判断——上游出现值得吸收的改进（安全修复、重要 bug 修复、想要的新功能）时，手动对照移植（cherry-pick 或参照实现），冲突自行解决。
  移植后流程：更新 `build.yml` 三处版本信息（Xcode 按上游官方 release workflow 同款、Zig 按新代码 `build.zig.zon` 的 `minimum_zig_version`、`-Dversion-string` 与 Info.plist）→ 云构建 → 本机验证 Cmd+V 贴图 → 打 `vX.Y.Z-paste.N` tag + Release → 从 Release 替换本机。
