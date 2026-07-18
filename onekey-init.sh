#!/bin/bash
# ============================================================
# onekey-init — Debian 基础环境初始化脚本
# ============================================================
set -e

trap 'echo -e "\033[0;31m[ERROR] 脚本执行失败\033[0m" >&2' ERR

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

if [ "$(id -u)" -ne 0 ]; then
  echo -e "\033[0;31m[ERROR] 请以 root 用户运行\033[0m"
  exit 1
fi

echo ""
info "=== 1/3 系统更新 ==="
apt update -qq
apt full-upgrade -y -qq
info "  ✓ 系统已更新"

info "=== 2/3 安装基础工具 ==="
apt install -y -qq \
  curl \
  wget \
  vim \
  nano \
  git \
  iproute2 \
  nftables \
  ca-certificates \
  unzip \
  net-tools \
  jq \
  cron
info "  ✓ 基础工具已安装"

info "=== 3/3 启用 nftables ==="
systemctl enable nftables
systemctl start nftables
info "  ✓ nftables 已启用（空规则集，全放通）"

echo ""
info "========== 初始化完成 =========="
echo "  $(grep -c processor /proc/cpuinfo) vCPU / $(free -h | awk '/^Mem:/{print $2}') RAM"
echo "  内核: $(uname -r)"
