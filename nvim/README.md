# Neovim 配置

面向 WSL/Linux，当前在 Neovim 0.10.4 验证。配置采用原生 package 加载插件。

## 功能与按键

- `i/j/k/l` 向上/左/下/右移动，`h` 进入 Insert；`Alt+i/j/k/l` 使用原有分屏与 tmux 导航。
- `空格 f f` 查找项目文件，`空格 f g` 搜索项目内容。上下箭头或 `Ctrl+p/n` 选结果，Enter 打开，Esc 退出。
- 选区中 `空格 y` 复制到系统剪贴板，`空格 Shift+y` 复制当前行，`空格 p/P` 粘贴。
- Tree-sitter 高亮覆盖 Python、Shell、Dockerfile、Markdown、JSON、YAML、TOML、Lua。
- TokyoNight Moon 语法配色、纯黑代码背景、加亮的相对行号；Heirline 圆角模式状态栏。
- 持久撤销，Python 使用 4 空格缩进，其余已配置类型使用 2 空格；Markdown 视觉换行。

搜索优先使用当前文件所在 Git 项目的根目录，否则使用 Neovim 当前目录；包含隐藏文件并遵循 `.gitignore`。

## 在新机恢复

依赖：Neovim 0.10 或 0.11、Git、GNU Stow、fzf > 0.36、ripgrep、fd/fdfind、curl、tar、C/C++ 编译器、Nerd Font。WSL 剪贴板复用本仓库的 `tmux/scripts/clipboard-copy` 与 `clipboard-paste`。

仓库应克隆到 `~/dotfiles`。可通过根目录 `install.sh` 一起部署配置，也可按下文单独启用；插件仍需按下文安装。

先安装四个插件（已经存在的目录可跳过）：

```sh
pack="$HOME/.local/share/nvim/site/pack/manual/opt"
mkdir -p "$pack"
git clone https://github.com/rebelot/heirline.nvim.git "$pack/heirline.nvim"
git -C "$pack/heirline.nvim" checkout fae936abb5e0345b85c3a03ecf38525b0828b992
git clone https://github.com/ibhagwan/fzf-lua.git "$pack/fzf-lua"
git -C "$pack/fzf-lua" checkout ded1c96d3d9d74634287d722431c26690968a4bf
git clone --branch v4.14.1 https://github.com/folke/tokyonight.nvim.git "$pack/tokyonight.nvim"
git clone --branch master https://github.com/nvim-treesitter/nvim-treesitter.git "$pack/nvim-treesitter"
```

`nvim-treesitter` 必须使用兼容分支 `master`，不要替换成要求新版 Neovim 的 `main`。

安装所需语言解析器：

```sh
nvim --headless -u NONE \
  -c 'packadd nvim-treesitter' \
  -c 'TSInstallSync python bash dockerfile markdown markdown_inline json yaml toml lua' \
  -c 'qa!'
```

若 `~/.config/nvim` 已有配置，先自行备份、移开冲突文件，再启用 Stow 包：

```sh
cd ~/dotfiles
stow --no-folding nvim
nvim
```

插件、解析器、缓存、撤销历史和本机备份均不随 Git 上传。

## 修改入口

`lua/config/` 下的 `options.lua`、`theme.lua`、`statusline.lua`、`search.lua`、`treesitter.lua`、`clipboard.lua` 分别控制对应功能。`lua/ijkl-navigation.lua` 保存原有导航映射。
