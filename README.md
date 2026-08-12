# dotfiles

用于在多台电脑之间同步终端配置，并复现 Linux 上的 Niri 桌面环境。
跨平台边界是：WezTerm 支持 Windows、macOS 和 Linux；Niri/DMS/Noctalia
及 `install.sh` 只面向 Ubuntu 26.04。

- `wezterm`：跨平台 WezTerm 配置、等宽动态标签栏、快捷键和 Amber Manpage 配色
- `zsh`：Zsh 环境、插件清单、别名、fzf、zoxide
- `zsh/.config/starship.toml`：Starship 提示符配置
- `niri`、`dms`：Niri 与 DMS 原生栏/桌面外壳
- `niri/nyxniri`：从 NyxNiri 移植的动画、透明模糊、窗口规则与护眼模式
- `vicinae`、`systemd`：主启动器及用户服务
- `applications`：WeChat 的可移植 XWayland desktop 覆盖
- `im`、`rime`、`xresources`：Fcitx5/Rime 与 XWayland 输入缩放边界

架构边界见 `docs/ARCHITECTURE.md`，新机步骤见 `docs/MIGRATION.md`。

## 在新电脑上使用

### Ubuntu 26.04

Ubuntu 26.04 新机先按 `manifests/apt-packages.txt` 和迁移文档安装所需软件，
克隆仓库，然后执行：

```bash
git clone <这个仓库的地址> ~/dotfiles
cd ~/dotfiles
./install.sh
./tests/verify-desktop.sh
```

`zsh` 首次启动时会按 `.zsh_plugins.txt` 自动安装 Antidote 插件；
WezTerm 首次加载时会自动获取 `wezterm-tabs` 插件。标签仍由 WezTerm 原生
tab bar 承载，标签数增加时会均匀缩短；插件只负责标题格式化。

登录 Niri 后可按 `Super+Ctrl+N` 切换护眼模式。它会联动 DMS 夜间色温，
并在“不透明、无模糊”和默认视觉效果之间切换；`Super+N` 仍是 DMS 通知中心。
顶部 Bar 将 NyxNiri V2 的左/中/右格局映射为 DMS 原生组件，并使用透明胶囊样式；
Noctalia 专属控件仍由现有 DMS 壁纸与控制中心功能承载。

如果目标路径已有同名文件，Stow 会停止并提示冲突。确认备份后再处理，
不要直接覆盖未知配置。

### Windows 与 macOS

两端只复用 `wezterm/.config/wezterm`，不运行 Linux 桌面安装脚本。Windows
默认打开 CMD，并在 Launcher 中提供 PowerShell 与 WSL；macOS 默认打开
`/bin/zsh`。Windows 与 macOS 的中文 fallback 统一使用 PingFang SC；Emoji
仍使用各自的系统字体。SF Mono 与 Windows 上的 PingFang SC 需要自行安装。
右上角状态跟随当前 pane：CMD/PowerShell 显示 `WINDOWS`，WSL 显示具体发行版；
SSH 能从前台进程或 WezTerm domain 取得目标时，显示具体的用户、主机或 IP。

## TODO

- 添加 Yazi 的 `yazi.toml`、`keymap.toml` 和 `theme.toml`；配置目录与 opener
  需要分别覆盖 Unix 和 Windows，完成前不纳入安装脚本。
- 在真实 SSH 主机上验证右上角远程目标识别；目前只覆盖可重复运行的 argv 与
  WezTerm domain 映射测试。

## 日常同步

```bash
cd ~/dotfiles
git pull --rebase
./install.sh
```

修改配置后提交并推送：

```bash
git add -A
git commit -m "Update dotfiles"
git push
```

本仓库不保存 `.zcompdump`、`wezterm_toggle` 等本机运行时文件，也不应
保存令牌、密码或私钥。
