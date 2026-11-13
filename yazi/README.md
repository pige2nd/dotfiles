# Yazi config

Personal Yazi configuration for macOS.

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
brew install yazi p7zip glow eza poppler mediainfo ffmpeg imagemagick pandoc
```

## 安装

配置已合并到 [dotfiles](https://github.com/pige2nd/dotfiles)。先备份并移开原有的 `~/.config/yazi`（包括指向旧仓库的链接），然后执行：

```sh
cd ~/dotfiles
stow --no-folding --target="$HOME" yazi
```

已收录的插件和主题随配置一起部署。`ya pkg install` 或插件更新可能修改 Stow 管理的目录；如需更新，请检查 Git 差异后提交。

## Notes

This repo intentionally avoids Linux/WSL-specific integrations such as `wl-clipboard`, `gvfs`, and Windows opener rules.

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
