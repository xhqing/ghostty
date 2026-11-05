# Changelog (fork)

本文件记录本仓库的全部变更。仓库已于 2026-09-20 与原上游 `ghostty-org/ghostty` 断开 fork 关系（GitHub `fork: false`），独立分叉自主维护、不自动同步上游；上游自身变更见上游仓库。

## v1.3.1-paste.4（2026-11-05）

### 变更（关掉最后一个窗口即退出，Dock 图标不再残留小点）

- **为什么改**：macOS 上关掉最后一个 Ghostty 窗口后进程仍驻留，Dock 图标下面一直挂着小点；而「App 在运行」和「还有窗口没关」在小点上看起来完全一样，于是每次关窗都得再核查一遍有没有漏下的窗口，很麻烦（Issue #15）。Ghostty 本来就有开关 `quit-after-last-window-closed`（macOS 侧由 `applicationShouldTerminateAfterLastWindowClosed` 直接返回它），只是默认值写成「仅 Linux 为 `true`」，macOS 默认 `false`——因此这不是缺陷，而是默认行为选择。
- **改了什么**：① `src/config/Config.zig` 里该开关的默认值由 `builtin.os.tag == .linux` 改为 `true`（两平台一致），文档注释同步说明本分叉为何与上游不同、以及想恢复旧行为如何显式写 `false`；② `macos/Tests/Ghostty/ConfigTests.swift` 把默认值断言由 `false` 改为 `true`，并新增「显式写 `false` 时为 `false`」的用例。
- **行为边界**：① 关窗口时若有进程在跑，仍先走 `confirm-close-surface` 的关闭确认，不会被静默杀进程；② Quick Terminal 的窗口用 `orderOut` 隐藏、窗口对象一直存在（`releasedWhenClosed="NO"`），已实测这种「只剩一个隐藏窗口」的情形不会阻塞退出判定（用一个最小 AppKit 程序验证：先建一个隐藏窗口、再关掉唯一可见窗口，`applicationShouldTerminateAfterLastWindowClosed` 仍被调用并正常退出）；③ 唯一残留情形是「关掉最后一个普通窗口时 Quick Terminal 正显示着」——那属于「还有窗口可见」，App 不退出，等它收起后也不补退出（收起是隐藏、不是关闭）；④ `quit-after-last-window-closed-delay` 仍只在 Linux 生效，本次不动。

### 变更（产物改由保留期回收，删除 Clean Artifacts 定时任务）

- **为什么改**：产物（每次构建上传的 30MB `Ghostty.app.zip`）只在两个场景有意义——「不本地编译就能真机验收某个提交」与「发版时取二进制挂 Release」；验证「能不能构建成功」本身不需要产物。但 `upload-artifact` 没有设保留期，默认继承了仓库的 90 天，于是产物按「每次改动两份」堆积（2026-11-05 实测 9 份、276.5MB）。为了不让它们无限涨，才养了 `Clean Artifacts` 这个每日定时任务，而它正是 2026-09-28 起每天失败、每天发一封 Run failed 邮件的那个工作流——「为了收拾产物而维护一个会出故障的定时任务」，因果倒置。用户 2026-11-05 选定方案 A：把回收交给 GitHub 自带的保留期，删掉定时任务。
- **改了什么**：① `build.yml` 的 `Upload artifact` 步骤加 `retention-days: 7`（产物一周后由 GitHub 自动删除）；② 删除 `.github/workflows/clean-artifacts.yml`（连带上一版刚给它补的 `actions: write` 权限修复一起退场，历史记录仍保留在本文件下方）。
- **后果与边界**：① 产物保留 7 天，够验收也够发版取材；② 若发版距目标提交的构建超过 7 天，需先手动 `workflow_dispatch` 跑一次构建再下载（发版频率低，可接受）；③ PR 构建仍会上传产物（未改成条件上传），若以后确认从不下载 PR 构建，可再加 `if: github.event_name != 'pull_request'` 减半；④ 已存在的 9 份旧产物不会自动清空到 7 天——它们按创建时的默认保留期（由各自上传时的 90 天计时），到期自然消失后不会再累积。

### 修复

- **Clean Artifacts 定时任务失败（每天失败一次、并触发 Run failed 邮件）**：为什么改——该 workflow 用 `c-hive/gha-remove-artifacts` 删除 1 周前的构建产物，删除接口需要 `actions: write` 权限，而本仓库默认 workflow 权限是 `read`（GITHUB_TOKEN 只有 contents / metadata / packages 三项只读）。列表接口在公开仓库上免鉴权也能读，所以「没有可删的产物」的日子里任务能通过；一旦真的有超过 1 周的产物要删，就 403 失败——自 2026-09-28 起第一份构建产物「变老」后，每天必然失败。改了什么——`clean-artifacts.yml` 显式声明 `permissions: actions: write`。验证方式：在分支上用 `workflow_dispatch` 手动触发，确认成功、旧产物被清理。

### 变更

- **子项目 `.pi` 由软链接改为真实目录 + 资源引用（2026-10-30 全局规则修订）**：为什么改——用户 2026-10-30 修订「智能体专属文件」规则，旧做法把本仓库 `.pi` 整个软链接到 `~/Developer/FullStackEngineerAgent/.pi`，等于把「共享」和「独占」压在同一个符号上：本仓库往 `.pi` 写任何文件都会直接落进 Agent 项目、影响全部兄弟子项目并进它的 git 历史；而 `AGENTS.md` 没有 include 机制，想用复制做超集又必然随 Agent 侧演进而漂移。改了什么——①删除 `.pi → ../FullStackEngineerAgent/.pi` 软链接，改为本仓库自己的**真实目录** `.pi/`；②新增 `.pi/settings.json`，用路径把 Agent 项目的 `extensions` / `skills` / `prompts` / `themes` 四个资源目录引用进来，并保留本地的同名目录（本地新增资源由自动发现处理、不必写进 settings）；③`AGENTS.md → ../FullStackEngineerAgent/AGENTS.md` 软链接保持不变（身份层直接对齐、不做超集）。纪律：本仓库 `.pi/` 只允许**追加**（自己的资源目录、`.pi/APPEND_SYSTEM.md`），不允许重述 / 覆盖基座规则；子项目专属规则用 `APPEND_SYSTEM.md`，不要用 `SYSTEM.md`（后者是整体替换，会把 agent 身份冲掉）。详见全局 `~/.pi/agent/docs/agents-registry.md`「智能体专属文件归属与子项目映射（2026-10-30 修订）」。

- **挂载「Agent 进驻」软链接（2026-10-17 用户修订）**：为什么改——用户 2026-10-17 修订智能体专属文件规则：实体只属负责的 Agent 项目（Atlas / FullStackEngineerAgent），子项目改挂两条指回 Agent 项目的软链接，在子项目目录开会话即继承 Atlas 的身份 / 规则 / 技能；详见全局 `agents-registry.md`「智能体专属文件归属与子项目映射（2026-10-17 修订）」。改了什么：新增 `AGENTS.md → ../FullStackEngineerAgent/AGENTS.md`、`.pi → ../FullStackEngineerAgent/.pi` 两条相对软链接并随仓库提交（单独 clone 时链接悬空、无害）。

- **同步 Atlas 子项目清单（加入 mp4-player）**：为什么改：Atlas 权威源把 mp4-player 登记为新子项目，按超集规则本仓库的随附版（`.claude/CLAUDE.md`）需同步最新全文。改了什么：随附的 FullStackEngineerAgent CLAUDE.md 全文更新——「目前在手项目」与「当前子项目清单」两处加入 mp4-player。

- **同步 Atlas 子项目清单（zcode-cli、cmux-launcher 短期搁置标注）**：为什么改：用户 2026-10-09 决定 zcode-cli 与 cmux-launcher 短期不再维护，Atlas 权威源已作标注。改了什么：随附的 FullStackEngineerAgent CLAUDE.md 全文更新——「目前在手项目」与「当前子项目清单」两处标注两者「自 2026-10-09 起短期搁置」。

## v1.3.1-paste.3（2026-10-12）

### 变更

- **迁移项目指南到 `DEVELOPMENT.md`，删除智能体专属文件**（2026-10-12 新规）：`.claude/CLAUDE.md` / `AGENTS.md` / `.agents/` 等智能体专属文件与目录不再保留；上游开发指南已迁入普通文档（`DEVELOPMENT.md`）。



### 新增

- **补齐项目标配（commit skill 第 9 步自动补全）**。为什么改：本仓库此前没有版本权威文件，中英双语文档入口与版权署名段也缺位，`/commit` 的标准检测要求补齐。改了什么：①新建 `VERSION`，取值 `1.3.1-paste.1`（来自本 CHANGELOG 顶部最新实际版本标题）；②把无后缀 `LICENSE` 转建为 `LICENSE.md`——保留上游版权行「Copyright (c) 2024 Mitchell Hashimoto, Ghostty contributors（原 Ghostty 项目）」（MIT 要求保留原版权声明，不得删除），另加一行「Copyright (c) 2026 All Contributors（本分叉）」，冗余的 `LICENSE` 删除；③`README.md` 顶部补 License / Version / Type 三枚静态徽章、中英互链、独立分叉与贴图补丁说明，底部补「License & Attribution」版权署名段；④新建中文版 `README_cn.md`，与英文版逐节对应；⑤新建 `.commit-cache.md`（commit skill 检测缓存）；⑥GitHub About 改为中英双语 description 并补 5 个 topics。

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
