# Changelog (fork)

本文件记录本仓库的全部变更。仓库已于 2026-09-20 与原上游 `ghostty-org/ghostty` 断开 fork 关系（GitHub `fork: false`），独立分叉自主维护、不自动同步上游；上游自身变更见上游仓库。

## v1.3.1-paste.5（2026-11-10）

### 新增（默认外观编进二进制：装好即用，默认值不再来自可被外部改写的文件）

- **为什么改**：Ghostty 的配置全部来自磁盘文件，换机器或重装后终端外观要手工重建；而且任何能写 `~/.config/ghostty/config` 的程序都能顺手改掉这些默认值（cmux 读同一份文件时就发生过互相影响，见 Issue #24 与 xhqing/cmux#70）。
- **改了什么**：① 新增 `src/config/config-builtin.ghostty`（9 项外观默认值：主题、字体、字号、光标、shell 集成），由 `Config.loadDefaultFiles()` 在最开头用 `@embedFile` 加载——它是优先级最低的一层，任何用户配置文件（XDG / App Support）都在它之后加载、天然覆盖；`config-default-files = false` 时这一层与用户配置一起被丢弃，语义不变。② 内置配置只放与机器无关的值：窗口尺寸 / 位置和所有 `keybind`（快速终端的 `global:` 热键、`super+v` 贴图补丁）继续留给用户配置文件。③ 新增 Zig 单测：内置文件必须能解析、且后加载的用户配置覆盖它。
- **边界**：① `theme = GitHub Dark Default` 依赖随 App 打包的主题目录（`Contents/Resources/ghostty/themes`，`emit-themes` 默认为 true，无需额外打包）；② 从未创建过配置文件的机器首次启动仍会生成注释模板（原有行为），内置值在模板之上生效。

### 变更（构建产物改用固定自签证书签名，辅助功能授权不再随每次构建失效）

- **为什么改**：本分叉的产物是 ad-hoc 签名，而 macOS TCC 对 ad-hoc 签名的 App 是按签名哈希（cdhash）匹配辅助功能授权的——每次重新构建哈希必变，系统当成「新 App」，之前的授权自动作废（2026-09-22 实测：装上新构建后终端里 `osascript` 直接报 `not allowed to send keystrokes (1002)`，只能 `tccutil reset` + 手工重新授权，Issue #2）。
- **改了什么**：① `build.yml` 增加证书签名路径：从 secrets 取固定的自签证书（`.p12`）导入一次性 keychain、只对 codesign 策略标记信任、逐个签 Sparkle 的嵌套组件与 App 本体，签完校验签名并打印 designated requirement；构建结束删除 keychain。secrets 不可用时（fork 的 PR）自动回退 ad-hoc，CI 仍能出产物。② 新增 `SIGNING.md` 说明证书用途、secret 名称与「不要随手重建证书」的原因。③ 清理上游遗留的 workflow：`pull_request_target` 的 `vouch-check-pr.yml` / `milestone.yml`、`vouch-*` 系列，以及依赖上游 Namespace runner / Nix / 自有 CDN 与 minisign 的 `release-tag.yml`、`release-tip.yml`、`publish-tag.yml`、`flatpak.yml`、`snap.yml`、`nix.yml`、`test.yml`、`update-colorschemes.yml`——这些在本仓库要么永远跳过、要么只会失败，删掉后仓库只剩 `build.yml` 一条 CI。
- **边界**：① 自签证书不在 Apple 信任链、也不做公证，Gatekeeper 首次打开仍需手动放行（与 ad-hoc 时相同，非回归）；② 证书一旦投入使用不要重建——换证书等于换签名身份，所有机器要重新授权一轮；③ 本分支的构建即配对测试：`codesign -dv` 应显示证书身份（`Authority=Ghostty Fork Self-Signed`）而不是 `Signature=adhoc`，辅助功能授权跨版本持续在下一个 Release 安装后复测。
- **补充修复（同一版内）**：证书签名路径不加 `--options runtime`（hardened runtime）。hardened runtime 会启用 library validation，它要求被加载的 dylib 与主程序 Team ID 相同；自签证书没有 OU 字段，两边都是 `TeamIdentifier=not set`，dyld 仍报 `mapping process and mapped file have different Team IDs` 拒绝加载 `Sparkle.framework`，App 直接起不来（已用该构建的产物实测复现并验证去掉后恢复正常）。本分叉不做公证，hardened runtime 没有收益，旧 ad-hoc 构建本来也没开。

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
