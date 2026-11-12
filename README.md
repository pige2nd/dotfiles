# dotfiles

集中维护终端内的工具配置：Zsh、Starship、tmux、Yazi 和 Neovim。终端模拟器与 Linux 桌面环境独立维护。

| 目录 | 内容 |
|---|---|
| `zsh` | Zsh 环境、Antidote 插件、fzf、zoxide、Starship |
| `tmux` | tmux 配置、剪贴板与会话脚本、TPM 插件安装入口 |
| `yazi` | Yazi 配置、主题、插件和 Office 预览脚本，详见 [说明](yazi/README.md) |
| `nvim` | Neovim 配置，依赖与插件安装见 [说明](nvim/README.md) |

## 安装

面向 Linux/WSL 和 macOS 的工具配置；Yazi 沿用原有 macOS 配置，未新增 Linux/WSL 集成。按各模块说明安装软件与依赖，先备份并移开冲突配置，再执行：

```sh
git clone https://github.com/pige2nd/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
./tmux/install-plugins.sh
```

需要 GNU Stow。仓库放在 `~/dotfiles`：现有 tmux 与 Neovim 的辅助脚本引用该位置。安装入口只部署配置，不安装软件、不改桌面服务；Stow 遇到冲突会停止。Zsh 首次启动会自动获取 Antidote 插件；Neovim 插件按模块说明手动安装。

只启用部分工具时，可运行 `stow --no-folding --target="$HOME" zsh tmux`。Starship 跟随 `zsh` 包部署。

原来把 yazi-config 克隆到 `~/.config/yazi` 的用户，先将该目录备份并移开，再部署本仓库的 `yazi` 包。原插件、主题和第三方许可证一并保留。

## 日常同步

```sh
cd ~/dotfiles
git pull --rebase
./install.sh
```

修改配置后检查 `git diff` 再提交。运行状态、缓存、令牌和私钥不纳入同步。

## 独立仓库

- [wezterm-config](https://github.com/pige2nd/wezterm-config)：WezTerm 配置、配色与测试。
- [alacritty-config](https://github.com/pige2nd/alacritty-config)：Windows Alacritty 配置与主题。
- [linux-desktop](https://github.com/pige2nd/linux-desktop)：Niri、DMS、Noctalia、输入法与桌面部署。

原有桌面与终端模拟器文件已迁往上述仓库，历史版本仍可从 Git 历史查看。Yazi 从 [yazi-config@14252c7](https://github.com/pige2nd/yazi-config/tree/14252c7a44997b2f0b65b57945debcd5fe88566b) 合入。

已有机器切换前，按新仓库迁移说明重新连接旧 Stow 链接；不要在仍有运行中桌面会话依赖旧目录时直接删除旧配置目录。
