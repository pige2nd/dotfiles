# Yazi config

用于 macOS 与 WSL 的 Yazi 配置，平台专用行为按环境启用。

## Highlights

- `ijkl` navigation:
  - `i` / `k`: up / down with wraparound
  - `j`: leave directory
  - `l`: smart enter/open/archive handling via `augment-command`
- `f`：文件名片段和中文拼音首字母搜索，按提示标签跳转（`searchjump.yazi` + `sjch.yazi`）
- Markdown preview via `glow` + `piper.yazi`
- Directory tree preview via `eza`
- Media/image preview via `mediainfo.yazi`
- Lightweight Office preview script without LibreOffice:
  - `docx`, `odt`, `rtf`, `xlsx`, `pptx`
  - legacy `doc`, `xls`, `ppt` via fallback text extraction
- PDF preview through Yazi's built-in previewer with `poppler`

## External dependencies

```sh
brew install yazi p7zip glow eza poppler mediainfo ffmpeg imagemagick pandoc lazygit
```

## 安装

配置已合并到 [dotfiles](https://github.com/pige2nd/dotfiles)。先备份并移开原有的 `~/.config/yazi`（包括指向旧仓库的链接），然后执行：

```sh
cd ~/dotfiles
./yazi/install.sh
```

插件以仓库已收录的快照为准，安装时不下载或升级插件。更新时应检查 Git 差异，并保留标签补建与 macOS 限定等已有修正。

## Notes

`g D` 仅在 WSL 执行跳转；其他通用快捷键跨平台复用。

## 按目录记忆偏好

`pref-by-location` 保存并恢复各目录的排序、隐藏文件显示和行信息模式。当前沿用 WSL 已使用的插件，支持范围为 Yazi 26.5.6 至 26.9.1，上游已停止维护；来源与许可证见插件目录。

| 按键 | 操作 |
|---|---|
| `.` | 切换隐藏文件并保存 |
| `m s/P/b/m/o/n` | 显示大小/权限/创建时间/修改时间/所有者/无信息，并保存 |
| `, m/M` | 按修改时间正序/倒序排列，并保存 |
| `, b/B` | 按创建时间正序/倒序排列，并保存 |
| `, e` | 按扩展名排序并保存 |
| `, t` | 开关自动应用目录偏好 |
| `, R` | 重置当前目录偏好 |

偏好文件使用 `$XDG_STATE_HOME/yazi/pref-by-location`，未设置时位于 `~/.local/state/yazi/pref-by-location`。该文件留在本机，不迁移或提交；其他自定义排序快捷键需在命令末尾追加 `plugin pref-by-location -- save` 才会保存。

## 增强文件与标签操作

| 按键 | 操作 |
|---|---|
| `a` | 增强新建：无扩展名按目录创建并进入；有扩展名按文件创建，不自动打开 |
| `r` | 增强重命名，光标位于扩展名前 |
| `A` | 将选中项打包归档，需要 `7z` 等归档工具 |
| `t n` | 在光标所在目录中新建标签；光标不是目录时使用当前目录 |
| `t 1/2/3` | 切换到对应标签，缺失时自动补建 |
| `t p` | 最大化／还原预览，与 `T` 相同 |
| `t r` | 重置预览布局 |

收录的 `augment-command.yazi/tab-switch.lua` 修正了缺失标签少建一个的边界错误。插件更新时应保留或核对这处修正。

## 导航与 Git 工具

- `g D`：仅在 WSL 跳转到 `/mnt/d`；macOS 不注册此键，普通 Linux 不执行跳转。
- `g l`：在当前目录打开 lazygit，退出后返回 Yazi；两端均需安装 `lazygit`。

macOS 可运行 `brew install lazygit`，WSL 使用当前系统已安装的 lazygit。

## macOS 文件标签

`mactag` 仅在 macOS 初始化、读取和修改 Finder 文件标签，`b a` 添加标签，`b r` 移除标签。需要先运行 `brew install tag`。

这些快捷键仅注册到 macOS；WSL 和其他系统不初始化标签功能，状态采集入口直接跳过，不调用 `tag`。

## 平台配置与 Stow 部署

- 公共插件、快捷键和初始化：`yazi/.config/yazi/`。
- 默认主题和打开规则：`yazi/profiles/default/.config/yazi/`，供 macOS 与普通 Linux 使用。
- WSL 主题和打开规则：`yazi/profiles/wsl/.config/yazi/`，保留 Dracula、Windows 程序打开和 Glow 备选；文本仍默认 Neovim。

`yazi/install.sh` 使用 GNU Stow 链接公共配置与当前平台配置，依据 `WSL_DISTRO_NAME` 选择 WSL。修改正在生效的 `~/.config/yazi/theme.toml` 会直接修改对应平台的仓库文件。Mac 和 WSL 的主题可以分别调整。

本机目录偏好继续保存在 `~/.local/state/yazi/pref-by-location`，不放入 Stow 包。旧配置的 Git 历史、备份文件和运行数据不进入公共包。

公共 `full-border` 保留 WSL 当前在 Yazi 26.8.15 已验证的边框渲染实现；与标签补建、mactag 平台判断一样，以仓库中的实际源码为准。
