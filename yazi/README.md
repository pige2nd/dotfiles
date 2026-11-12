# Yazi config

Personal Yazi configuration for macOS.

## Highlights

- `ijkl` navigation:
  - `i` / `k`: up / down with wraparound
  - `j`: leave directory
  - `l`: smart enter/open/archive handling via `augment-command`
- Chinese pinyin initial matching with `searchjump.yazi` + `sjch.yazi`
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
