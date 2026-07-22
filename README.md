# onekey-init

Debian LXC 一键系统初始化脚本。**新建 LXC 后第一件事**。

## 快速开始

```bash
bash <(wget -qO- https://raw.githubusercontent.com/guochan2019/onekey-init/main/onekey-init.sh)
```

## 包含内容

| 步骤 | 内容 |
|------|------|
| 1/8 | 替换 APT 源为清华镜像（备份原文件，支持 trixie/updates/backports/security） |
| 2/8 | 系统更新（`apt full-upgrade`） |
| 3/8 | 安装基础工具（curl, wget, vim, nano, git, htop, btop, nftables, chrony, jq, cron 等） |
| 4/8 | 启用 nftables（不写入规则，后续按需配置） |
| 5/8 | 配置 chrony 时间同步（替代 systemd-timesyncd） |
| 6/8 | 网络性能调优（BBR + 连接跟踪 + 缓冲区 + TIME_WAIT 优化） |
| 7/8 | 系统参数调优（swappiness=10、时区 Asia/Shanghai） |
| 8/8 | 清理（apt autoremove、autoclean） |

## 换源

默认替换为清华镜像源，备份文件保存在 `/etc/apt/sources.list.d/debian.sources.bak`。

## nftables

仅启用服务，不写入任何规则。后续需要时手动编辑 `/etc/nftables.conf` 后 `systemctl restart nftables`。

## 网络优化

- BBR 拥塞控制
- 连接跟踪上限 1048576
- TIME_WAIT 快速回收 + 端口范围 1024-65535
- 收发缓冲区 16MB
- swappiness=10

## 下一步

初始化完成后安装具体服务：

```bash
# 按顺序
onekey-mosdns   # DNS 分流（基础网络服务）
onekey-daed     # dae 透明代理面板（依赖 mosdns GEO 数据）
onekey-frpc     # 内网穿透
onekey-lucky    # DDNS / ACME / 端口转发
```
