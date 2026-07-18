# onekey-init

Debian 基础环境一键初始化脚本。

## 快速开始

```bash
bash <(wget -qO- https://raw.githubusercontent.com/guochan2019/onekey-init/main/onekey-init.sh)
```

## 包含内容

| 步骤 | 内容 |
|------|------|
| 1/3 | 系统更新（`apt full-upgrade`） |
| 2/3 | 安装基础工具（curl, wget, vim, nano, git, iproute2, nftables, jq, cron 等） |
| 3/3 | 启用 nftables（空规则集，全放通） |

## 安装的工具

| 工具 | 用途 |
|:----|:-----|
| curl / wget | 网络请求 / 下载 |
| vim / nano | 文本编辑器 |
| git | 版本管理 |
| iproute2 / net-tools | 网络管理（ip, ifconfig 等） |
| nftables | 防火墙框架（默认空规则，后续按需添加） |
| jq | JSON 命令行处理 |
| cron | 定时任务 |
| unzip | 解压 |
| ca-certificates | CA 证书 |
