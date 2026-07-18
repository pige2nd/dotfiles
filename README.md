# dotfiles

用于在多台电脑之间同步 Niri 桌面与终端配置。目前维护：

- `wezterm`：WezTerm 配置、tabline 外观、快捷键和颜色
- `zsh`：Zsh 环境、插件清单、别名、fzf、zoxide
- `zsh/.config/starship.toml`：Starship 提示符配置
- `niri`、`dms`：Niri 与 DMS 原生栏/桌面外壳
- `vicinae`、`systemd`：主启动器及用户服务
- `applications`：WeChat 的可移植 XWayland desktop 覆盖
- `im`、`rime`、`xresources`：Fcitx5/Rime 与 XWayland 输入缩放边界

架构边界见 `docs/ARCHITECTURE.md`，新机步骤见 `docs/MIGRATION.md`。

## 在新电脑上使用

Ubuntu 26.04 新机先按 `manifests/apt-packages.txt` 和迁移文档安装所需软件，
克隆仓库，然后执行：

```bash
git clone <这个仓库的地址> ~/dotfiles
cd ~/dotfiles
./install.sh
./tests/verify-desktop.sh
```

`zsh` 首次启动时会按 `.zsh_plugins.txt` 自动安装 Antidote 插件；
WezTerm 首次加载时会自动获取 `tabline.wez` 插件。

如果目标路径已有同名文件，Stow 会停止并提示冲突。确认备份后再处理，
不要直接覆盖未知配置。

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
