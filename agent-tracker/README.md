# Codex CLI / Pi CLI 任务追踪

使用 [theniceboy 的 agent-tracker 服务端](https://github.com/theniceboy/.config/tree/c161f761c66da4aff6971edf4e586f8bbf6f99fc/agent-tracker)，版本固定在 `upstream-revision`。
本目录只维护 CLI 事件适配和 tmux 状态显示，不复制他的布局和快捷键。

## 使用

- 在 tmux pane 内启动 Codex CLI 或 Pi CLI。
- window 名后的 `~` 表示正在运行，`!` 表示有尚未查看的结束结果。
- 右侧 `!N` 是所有 session 中尚未查看的结束结果数量。
- `Alt-b` 后按 `a`：任务列表，方向键或 `Alt-j/k` 移动，Enter 跳转。
- `Alt-m`：跳到最新的未读结果。进入对应 pane 后清除未读。
- 结束不等于成功：错误或中断会记录在任务列表的结果文字里。

Codex 首次使用需在 CLI 的 `/hooks` 中审阅并信任这四个 hooks。
Pi 通过 `agent_settled` 上报结束，避免在自动重试或后续消息之前误报。
已启动的 Pi 可执行 `/reload`；Codex 需要重新打开会话加载 hooks。

当前仅接 tmux 标记和任务列表；系统弹窗关闭，Windows 通知未接入。
tracker 任务保存在内存中，服务重启会清空。摘要最多 160 字符，仅发给本机 Unix socket。

## 安装

此模块面向启用 systemd 用户服务的 Linux/WSL。仓库放在 `~/dotfiles`，依赖 Git、Python 3、tmux、fzf 和 Go 1.25.1 或更高版本。根目录 `install.sh` 只部署终端工具配置，不安装此模块。

先构建固定版本的上游程序：

```sh
cd ~/dotfiles
./agent-tracker/build.sh
# Go 不在 PATH 时改用：GO_BIN=/path/to/go ./agent-tracker/build.sh
```

首次安装时创建以下链接并安装服务。若目标路径已有配置，先检查并合并；已有 Codex hooks 应合并本模块的 hooks 条目，保留原有条目。

```sh
mkdir -p ~/.config/systemd/user ~/.codex ~/.pi/agent/extensions
ln -s "$HOME/.local/share/agent-tracker-source/agent-tracker" ~/.config/agent-tracker
ln -s "$HOME/dotfiles/agent-tracker/codex-hooks.json" ~/.codex/hooks.json
ln -s "$HOME/dotfiles/agent-tracker/pi.ts" ~/.pi/agent/extensions/agent-tracker.ts
install -m 0644 ~/dotfiles/agent-tracker/agent-tracker.service ~/.config/systemd/user/
install -m 0644 ~/dotfiles/agent-tracker/agent-tracker-tmux.service ~/.config/systemd/user/
mkdir -p ~/.config/agent-tracker/run
# 仅首次创建；保留已有 settings.json：
test -e ~/.config/agent-tracker/run/settings.json || cp ~/dotfiles/agent-tracker/settings.json ~/.config/agent-tracker/run/settings.json
systemctl --user daemon-reload
systemctl --user enable --now agent-tracker.service agent-tracker-tmux.service
```

重新加载 tmux 配置以启用任务列表、未读显示和自动确认：

```sh
tmux source-file ~/dotfiles/tmux/.tmux.conf
```

之后按上文重新加载 CLI 的 hooks / 扩展。已有 WSL 安装可以保留当前链接、设置和运行中的服务，无需重复首次安装。

## 安装路径

- 上游源码和二进制：`~/.local/share/agent-tracker-source/agent-tracker/`
- `~/.config/agent-tracker` 指向上述目录。
- `~/.codex/hooks.json` 指向本目录 `codex-hooks.json`。
- `~/.pi/agent/extensions/agent-tracker.ts` 指向本目录 `pi.ts`。
- 两个 `.service` 文件安装到 `~/.config/systemd/user/`。

`build.sh` 使用 Go 1.25.1 或更高版本，从固定提交编译。
可用 `GO_BIN=/path/to/go ./build.sh` 指定编译器。
首次安装把 `settings.json` 放到 `~/.config/agent-tracker/run/settings.json`，
再执行 `systemctl --user enable --now agent-tracker.service agent-tracker-tmux.service`。

```sh
systemctl --user status agent-tracker.service agent-tracker-tmux.service
journalctl --user -u agent-tracker-tmux.service -n 30
~/.config/agent-tracker/bin/agent tracker state
```

禁用时移除本集成的 Codex hooks / Pi 扩展，停止上述两个服务，
并移除 tmux 中标为 Agent task results 的绑定和 hooks。


## 回归验证

```sh
python3 tests/test-agent-tracker.py
```

测试使用独立 tmux socket 和临时 tracker socket，检查 CLI 事件上报、pane 上下文、状态标记及 tmux 配置解析，不连接正在运行的 tracker 服务。
