<!-- LOGO -->
<h1>
<p align="center">
  <img src="https://github.com/user-attachments/assets/fe853809-ba8b-400b-83ab-a9a0da25be8a" alt="Logo" width="128">
  <br>Ghostty
</h1>
  <p align="center">
    Fast, native, feature-rich terminal emulator pushing modern features.
    <br />
    <a href="#关于">关于</a>
    ·
    <a href="https://ghostty.org/download">下载</a>
    ·
    <a href="https://ghostty.org/docs">文档</a>
    ·
    <a href="CONTRIBUTING.md">贡献</a>
    ·
    <a href="HACKING.md">开发</a>
  </p>
</p>
<p align="center">
  <a href="./LICENSE.md"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" /></a>
  <a href="https://github.com/xhqing/ghostty/releases"><img alt="Version" src="https://img.shields.io/badge/Version-1.3.1--paste.1-blue?style=flat-square" /></a>
  <img alt="Type: Project" src="https://img.shields.io/badge/Type-Project-lightgrey?style=flat-square" />
</p>

**简体中文** | [English](README.md)

> **本仓库是独立分叉。** 2026-09-20 起与
> [ghostty-org/ghostty](https://github.com/ghostty-org/ghostty) 断开 fork 关系、独立维护，
> 不与上游同步。在 v1.3.1 基线之上带一个补丁：用 Cmd+V 粘贴剪贴板图片时，
> 把图片写入临时文件并粘贴该文件路径。

## 关于

Ghostty 是一款终端模拟器，它的特别之处在于同时做到快速、功能丰富、体验原生。市面上优秀的终端模拟器不少，但它们大多迫使你在「快」「功能多」「原生界面」三者之间做取舍，而 Ghostty 三者兼得。

我无意宣称 Ghostty 在任何一个方面都是最好的（最快的、功能最全的、最原生的），但它在三方面都很有竞争力，而且不需要你为了其中一方面放弃另外两方面。

Ghostty 还希望拓展终端模拟器的能力边界：它提供一批默认关闭的现代特性，让 CLI 工具开发者能做出交互更丰富、功能更完整的应用。

目标虽大，第一步很实在：把 Ghostty 做成最符合标准的终端模拟器之一——既兼容现有的各种 shell 和软件，又支持生态里最新的终端创新。你可以把它直接当作现有终端模拟器的替代品来用。

更多细节见 [关于 Ghostty](https://ghostty.org/docs/about)。

## 下载

请见 Ghostty 官网的[下载页面](https://ghostty.org/download)。

## 文档

请见 Ghostty 官网的[文档](https://ghostty.org/docs)。

## 贡献与开发

如果你对 Ghostty 有想法、发现了问题，或想通过 pull request 参与贡献，请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)（「为 Ghostty 贡献」）。希望参与 Ghostty 开发的，还应阅读 [HACKING.md](HACKING.md)（「开发 Ghostty」）以了解更详细的技术细节。

## 路线图与进度

项目的高层规划，按顺序如下：

|  #  | 步骤                                                      | 状态 |
| :-: | --------------------------------------------------------- | :----: |
|  1  | 符合标准的终端模拟                                        |   ✅   |
|  2  | 有竞争力的性能                                            |   ✅   |
|  3  | 基础自定义能力 —— 字体、背景色等                          |   ✅   |
|  4  | 更丰富的窗口功能 —— 多窗口、标签页、分屏                  |   ✅   |
|  5  | 原生平台体验（如 macOS 偏好设置面板）                     |   ⚠️   |
|  6  | 跨平台、可嵌入的 `libghostty`                             |   ⚠️   |
|  7  | Windows 终端（含 PowerShell、Cmd、WSL）                   |   ❌   |
|  N  | 花哨特性（后续再展开）                                    |   ❌   |

下面逐步展开说明。

#### 符合标准的终端模拟

过去一年多里，每天都有数百名测试者把 Ghostty 当作日常终端使用，这说明它已实现的控制序列足够完整。我们还做过一次[全面的 xterm 对照审计](https://github.com/ghostty-org/ghostty/issues/632)，把 Ghostty 的行为与 xterm 逐项比较，并据此建立了一套一致性测试用例。

我们认为 Ghostty 是目前兼容性最好的终端模拟器之一。

终端行为一部分是成文标准（即 [ECMA-48](https://ecma-international.org/publications-and-standards/standards/ecma-48/)），但更多是事实标准——由世界各地流行的终端模拟器共同定义。Ghostty 的做法是：以 ① 现行标准、② xterm（该功能在 xterm 中存在时）、③ 其它流行终端 的先后顺序为准，这个顺序就是 Ghostty 项目对「标准」的定义。

#### 有竞争力的性能

要持续验证这一点还需要更好的基准测试，但总体而言，Ghostty 的性能与其它一流的终端模拟器处于同一档。

渲染方面，我们采用多渲染器架构：Linux 上用 OpenGL，macOS 上用 Metal。据我所知，除 iTerm 之外，Ghostty 是唯一直接使用 Metal 的终端模拟器；而支持连字的 Metal 渲染器更是只有我们（iTerm 开启连字时会退回 CPU 渲染）。高负载下我们能稳定保持约 60fps，通常还更高——不过屏幕变化少时，实际渲染帧率往往低得多。

IO 方面，我们有一个专门的 IO 线程，即便在高负载读写（例如 `cat` 一个大文本文件）下也能把抖动控制得很小。在 IO 基准测试中，我们通常与其它高速终端模拟器只差毫厘。举例来说，读取纯文本转储的速度是 iTerm 和 Kitty 的 4 倍、Terminal.app 的 2 倍；Alacritty 也很快，我们与它大体相当，而我们的应用体验要丰富得多。

> [!NOTE]
> 尽管已经*非常快*，这里仍有很大的改进空间。

#### 更丰富的窗口功能

macOS 版与 Linux 版（GTK 构建）都支持多窗口、标签页和分屏。

#### 原生平台体验

Ghostty 是跨平台终端模拟器，但我们不追求「最小公分母」式的体验。它有大量用 Zig 编写的共享核心，同时也做了很多贴合各平台原生习惯的事情：

- macOS 版是真正的 SwiftUI 应用，具备你期待的一切：原生窗口、菜单栏、设置界面等。
- macOS 使用真正的 Metal 渲染器，字体发现交给 CoreText。
- Linux 版基于 GTK 构建。

还有不少改进空间：macOS 的设置窗口仍是半成品，Linux 侧也会陆续跟上。

#### 跨平台、可嵌入的 `libghostty`

除了作为独立的终端模拟器，Ghostty 还是一个 C 兼容库，可以把快速、功能丰富的终端模拟器嵌入任何第三方项目，这个库叫 `libghostty`。

考虑到项目规模，我们把 libghostty 拆成若干个独立的库，先做的是 `libghostty-vt`——专注于解析终端序列、维护终端状态。详见[这篇博客](https://mitchellh.com/writing/libghostty-is-coming)。

`libghostty-vt` 现在已经可用，支持 Zig 与 C，兼容 macOS、Linux、Windows 和 WebAssembly。写到这里时它的 API 尚未稳定，也还没打正式版本，但核心逻辑已经过充分验证（Ghostty 自己就在用），我们正在加紧推进。

最终目标并非空想：macOS 版本身就是 `libghostty` 的使用者——它是用 Xcode 开发的 Swift 原生应用，`main()` 就在 Swift 里，Swift 应用链接 `libghostty` 并通过 C API 渲染终端。

## 崩溃报告

Ghostty 内置崩溃报告器，会把崩溃报告写入磁盘，保存目录为 `$XDG_STATE_HOME/ghostty/crash`；若未设置 `$XDG_STATE_HOME`，默认为 `~/.local/state`。**崩溃报告不会自动发送到你的机器之外的任何地方。**

崩溃报告只在崩溃后的下一次启动 Ghostty 时生成。如果 Ghostty 崩溃了而你想拿到报告，至少要重启一次 Ghostty；届时日志里会出现一条「已生成崩溃报告」的提示。

> [!NOTE]
>
> 用 `ghostty +crash-report` CLI 命令可以列出已有的崩溃报告。未来的 Ghostty 版本会让你更方便地在 CLI 和图形界面里查看报告内容。

崩溃报告以 `.ghosttycrash` 为扩展名，格式是 [Sentry envelope 格式](https://develop.sentry.dev/sdk/envelopes/)。你可以把它们上传到自己的 Sentry 账号查看内容；该格式也有公开文档，其它工具同样可以解析。用 `ghostty +crash-report` 命令可以列出所有崩溃报告，未来的版本会直接展示报告内容。

要把报告发给 Ghostty 项目，可以用 [Sentry CLI](https://docs.sentry.io/cli/installation/) 执行：

```shell-session
SENTRY_DSN=https://e914ee84fd895c4fe324afa3e53dac76@o4507352570920960.ingest.us.sentry.io/4507850923638784 sentry-cli send-envelope --raw <path to ghostty crash>
```

> [!WARNING]
>
> 崩溃报告可能包含敏感信息。报告本身不会刻意包含敏感信息，但其中含有崩溃时各线程的完整栈内存——重建调用栈要靠它，而栈内存里是否恰好残留敏感数据，取决于崩溃发生的时机。

## 版权与署名

MIT 许可证——见 [LICENSE.md](LICENSE.md)。

Copyright (c) 2024 Mitchell Hashimoto, Ghostty contributors（原 Ghostty 项目）。Copyright (c) 2026 All Contributors（本分叉）。

本仓库部分内容源自 [ghostty-org/ghostty](https://github.com/ghostty-org/ghostty)，于 2026-09-20 断开分叉；该部分内容保留原作者版权与 MIT 声明。

### 署名方式

引用本项目时请署名到项目而非个人：注明仓库地址（`https://github.com/xhqing/ghostty`），并保留 [LICENSE.md](LICENSE.md) 中的版权声明。

### 项目地址引用

仓库地址：`https://github.com/xhqing/ghostty`
