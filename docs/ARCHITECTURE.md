# Niri 桌面架构

这份文件是桌面架构的唯一事实来源。目标是组件少、边界明确，并能在新机上复现。

## 固定决策

- Niri 负责合成、平铺、列布局和工作区；接受它的原生模型，不实现“假最小化”。
- 普通 `Niri` 登录会话仍以 DMS 作为唯一桌面外壳：原生栏、控制中心、通知、设置、锁屏、壁纸和剪贴板。
- 独立 `NyxNiri` 登录会话以 Noctalia V5 替换 Bar、Dock、通知、控制中心、锁屏和壁纸系统；进入时仅在本次用户运行时 mask 并停止 DMS，防止 `graphical-session.target` 将它重新拉起，退出时解除 mask 并恢复 DMS。
- 两个会话复用动画、阴影、透明模糊、护眼模式和窗口规则，但使用不同的 Niri 主配置；护眼脚本按当前会话调用 DMS 或 Noctalia 的夜间模式。
- 每个会话只有一条 Shell 栏：普通 Niri 使用 DMS，NyxNiri 使用 Noctalia；Waybar 不运行。
- Vicinae 是唯一键盘主启动器，Super+Space 打开；DMS 栏上的按钮保留为鼠标备用抽屉，不绑定快捷键。
- WeChat 与 WezTerm 暂时使用 XWayland，以优先保证输入法和缩放稳定。
- WeChat 保持平铺、完全不透明且关闭背景模糊，避免 XWayland 菜单和输入法候选窗出现合成瑕疵。
- Fcitx5 是唯一输入法框架，使用 Rime。
- 不做全局 DPI 补偿。Wayland 交给合成器；XWayland 的候选窗只通过 Xresources 设置 Xft.dpi。

## DMS 栏

- Bar 格局映射 NyxNiri V2 的三段式结构，并用归档 V1 的 DMS 胶囊参数实现。
- 左侧：启动器、工作区、当前窗口。
- 中间：日期与时钟。
- 右侧：媒体、后台应用托盘、通知、电池、控制中心、电源菜单。
- Bar 本体透明，各组件使用 80% 不透明度、4px 间隔和细描边形成独立悬浮胶囊。
- Noctalia 专属的壁纸、动态壁纸和音量组件不在 DMS 中伪造；壁纸继续由 DMS 管理，音量保留在控制中心。
- 托盘保留，用来确认 FlClash 等常驻应用是否仍在后台，并提供真正退出的入口。
- 音量、网络、蓝牙等入口统一收进控制中心，不在栏上重复放置。

## 配置所有权

- 手写源文件位于 dotfiles，静态配置由 GNU Stow 链接到用户目录。
- DMS 和 Fcitx5 会重写配置，因此仓库文件只作种子，由 install.sh 复制到运行目录，避免运行状态反写仓库。
- Noctalia 同样会重写 `config.toml`；仓库保存带路径占位符的种子，install.sh 展开为用户目录中的运行副本；静态 Hook 仍由 Stow 管理。
- DMS 生成的 niri/dms/*.kdl 仍由 DMS 管理，不手工修改。
- 手写的 `niri/nyxniri/*.kdl` 与 DMS 生成文件分离；`effects.kdl` 是运行时软链接，不进入仓库。
- Niri 快捷键覆盖通过 dms keybinds 写入，避免下次生成时丢失。
- NyxNiri 融合层只使用不冲突的 `Super+Ctrl+N` 切换护眼模式；已有 DMS 快捷键保持原样。
- DMS 的系统级通知补丁单独保存，系统升级后由引导脚本校验并重放。
- 运行数据、缓存、历史记录、密码、令牌和私钥不进仓库。

## NyxNiri 会话

- `~/.config/niri-nyxniri/config.kdl` 是独立入口，不包含任何 DMS 生成文件，也不含 NVIDIA 专用变量。和当前普通 Niri 配置一样不声明 `output`，继续使用 Niri 自动检测。
- Noctalia 按合成器官方建议由 Niri 自启动；不启用全局 Noctalia 用户服务。
- Bar 采用 NyxNiri V2 的三段胶囊布局，Dock 启用；媒体之后显示社区同步歌词组件，右侧用一个本地 Noctalia 插件轮播电量、音量和亮度。Vicinae 仍是 Super+Space 主启动器，终端仍是 WezTerm。
- 静态和视频壁纸位于 `~/Pictures/Wallpapers`。`mpvpaper` 插件播放视频，ffmpeg 抽帧交给 Noctalia 做 Material You 配色；桌面中央使用 Noctalia 内置的音频环形可视化，无音频时自动淡出。
- Noctalia 非 Bar 界面按 1.2 倍缩放；匿名启动遥测保持关闭。官方和社区插件源在依赖安装阶段顺序预取，避开首次启动并发克隆的短超时。
- 登录管理器条目新增 `/usr/share/wayland-sessions/niri-nyxniri.desktop`，通用启动器安装在 GDM 可访问的 `/usr/local/bin/niri-nyxniri-session`；原 `niri.desktop` 不修改。

## 明确排除

FlClash 不进入迁移仓库：不保存程序、内核、订阅、节点、配置、缓存、启动脚本或桌面文件。新机上自行下载并导入订阅。
