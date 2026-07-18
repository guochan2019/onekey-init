# onekey-init

Debian LXC 一键系统初始化脚本。**新建 LXC 后第一件事**。

## 快速开始

```bash
bash <(wget -qO- https://raw.githubusercontent.com/guochan2019/onekey-init/main/onekey-init.sh)
```

## 包含内容

| 步骤 | 内容 |
|------|------|
| 1/7 | 系统更新 (`apt full-upgrade`) |
| 2/7 | 安装基础工具（curl, wget, vim, git, htop, btop, nftables, chrony 等） |
| 3/7 | 配置 nftables 防火墙（放行 SSH/DNS/管理面板端口） |
| 4/7 | 配置 chrony 时间同步（替代 systemd-timesyncd） |
| 5/7 | 网络性能调优（BBR + 连接跟踪 + 缓冲区 + TIME_WAIT 优化） |
| 6/7 | 系统参数调优（swappiness=10、时区 Asia/Shanghai） |
| 7/7 | 清理（apt autoremove、autoclean） |

## nftables 规则

内网环境全放通模式（INPUT / FORWARD / OUTPUT 全部 ACCEPT），仅确保 nftables 服务已启用，不限制任何流量。

后续如果需要加规则，编辑 `/etc/nftables.conf` 后执行 `nft -f /etc/nftables.conf`。

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
