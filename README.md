# dotfiles

用于在多台电脑之间同步个人终端配置。目前维护：

- `wezterm`：WezTerm 配置、tabline 外观、快捷键和颜色
- `zsh`：Zsh 环境、插件清单、别名、fzf、zoxide
- `zsh/.config/starship.toml`：Starship 提示符配置

## 在新电脑上使用

先安装 Git、Zsh、GNU Stow、WezTerm、Starship，以及配置中用到的
`fzf`、`eza`、`bat` 和 `zoxide`。然后执行：

```bash
git clone <这个仓库的地址> ~/dotfiles
cd ~/dotfiles
./install.sh
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
git add wezterm zsh .gitignore README.md install.sh
git commit -m "Update dotfiles"
git push
```

本仓库不保存 `.zcompdump`、`wezterm_toggle` 等本机运行时文件，也不应
保存令牌、密码或私钥。
