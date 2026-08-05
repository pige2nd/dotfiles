# 新机迁移

## 首次安装

目标系统为 Ubuntu 26.04。软件安装包由用户从官方渠道取得；
`manifests/apt-packages.txt` 和 `manifests/vicinae-extensions.txt` 是核对清单。
软件安装完成并克隆仓库后执行：

    cd ~/dotfiles
    ./scripts/install-nyxniri-deps.sh
    sudo patch --forward -d / -p0 < patches/dms-notification-timeout.patch
    ./install.sh
    ./scripts/install-nyxniri-system.sh
    ./scripts/install-system-sleep.sh
    ./tests/verify-desktop.sh

依赖脚本按 Noctalia 文档添加 Ubuntu 26.04 软件源，把 mpvpaper 构建到 `~/.local`，并顺序预取 official/community 插件源。若 Noctalia 已经安装而插件列表为空，可单独运行 `./scripts/prefetch-noctalia-plugins.sh`。NyxNiri 系统脚本只新增登录条目，不修改原 Niri 条目；挂起脚本会先确认硬件支持，再将 systemd 的内存挂起模式设为 `deep`。DMS 补丁若提示已经应用，可跳过。

WeChat、Vicinae、WezTerm 和 Rime Mint 的安装包自行从官方渠道取得。dotfiles 只接管已验证的配置；WeChat 的登录数据不迁移。

Rime Mint 的完整方案和约 400 MB 的万象语法模型不进入 dotfiles。先按 Mintimate/oh-my-rime 的说明安装完整方案，再运行 install.sh，让仓库中的 rime_mint.custom.yaml 覆盖个性设置，最后重新部署 Rime。

Vicinae 首次启动后，按 manifests/vicinae-extensions.txt 从商店恢复扩展。扩展数据库、剪贴板历史和索引不迁移。验证脚本会在扩展尚未恢复时明确失败。

FlClash 单独下载安装并导入订阅；它不属于这套自动化。

## 验证

    ./tests/verify-desktop.sh
    niri validate -c ~/.config/niri/config.kdl
    systemctl --user status dms.service vicinae.service
    systemctl --user is-enabled waybar.service

最后一条应返回 masked 或找不到该单元。登录 Niri 后人工确认：

1. 只有 DMS 一条可见栏。
2. Super+Space 打开 Vicinae。
3. 中文输入在原生 Wayland 应用、WeChat 和 WezTerm 中都正常。
4. 通知、控制中心、锁屏、电源菜单和剪贴板入口正常。

注销后在登录界面选择 NyxNiri，再确认 Noctalia Bar、Dock、通知、控制中心、锁屏、静态/视频壁纸和 Material You 配色。退出 NyxNiri 后，普通 Niri 会话仍应恢复 DMS。

## 日常变更

先确认当前状态可用并提交快照；之后一次只改变一个变量。改动完成后运行验证脚本并提交。DMS 升级后如果通知行为回退，先用 patch --dry-run 检查补丁是否仍匹配，再人工重放；不要强行套用不匹配的补丁。
