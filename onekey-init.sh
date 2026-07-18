#!/bin/bash
# ============================================================
# onekey-init — Debian LXC 系统初始化脚本
# 适用环境: Debian 13 (fresh LXC)
# 功能: 系统更新 + 基础工具 + nftables + 网络调优
# ============================================================
set -e

trap 'echo -e "\033[0;31m[ERROR] 脚本执行失败，请检查:\033[0m
  - 网络连接
  - 是否以 root 运行" >&2' ERR

# ---------- 彩色输出 ----------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------- 检测 root ----------
if [ "$(id -u)" -ne 0 ]; then
  err "请以 root 用户运行 (当前非 root)"
fi

echo ""
echo "========================================"
echo "  Debian LXC 系统初始化"
echo "========================================"
echo ""

# =================== 1. 系统更新 ===================
info "=== 1/7 系统更新 ==="
apt update -qq
apt full-upgrade -y -qq
info "  ✓ 系统已更新"

# =================== 2. 安装基础工具 ===================
info "=== 2/7 安装基础工具 ==="
apt install -y -qq \
  curl wget vim nano git \
  htop iftop btop \
  iproute2 net-tools nftables \
  sudo ca-certificates jq \
  unzip cron chrony
info "  ✓ 基础工具已安装"

# =================== 3. 配置 nftables ===================
info "=== 3/7 启用 nftables ==="
systemctl enable nftables
systemctl start nftables
info "  ✓ nftables 已启用（未写入规则，按需添加）"

# =================== 4. 配置 chrony 时间同步 ===================
info "=== 4/7 配置时间同步 ==="
systemctl stop systemd-timesyncd 2>/dev/null || true
systemctl disable systemd-timesyncd 2>/dev/null || true
systemctl enable --now chrony
sleep 1
chronyc tracking 2>/dev/null | grep -E 'Stratum|System time' || true
info "  ✓ chrony 时间同步已启动"

# =================== 5. 网络性能调优 ===================
info "=== 5/7 网络性能调优 ==="
# 优先 IPv4（避免部分 CDN IPv6 连接失败问题）
grep -qxF 'precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null || \
  echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
info "  ✓ IPv4 优先已配置 (/etc/gai.conf)"
cat > /etc/sysctl.d/99-network.conf << 'SYSEOF'
# 网络性能优化
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
# 连接跟踪
net.netfilter.nf_conntrack_max = 1048576
net.nf_conntrack_max = 1048576
# TIME_WAIT 优化
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
# 缓冲区增大（适合代理场景）
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
# 端口范围（代理需要大量连接）
net.ipv4.ip_local_port_range = 1024 65535
# 其他优化
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
SYSEOF

# 逐条应用 sysctl（set +e 避免 LXC 不可写参数导致失败）
set +e
SYSCFG=/etc/sysctl.d/99-network.conf
while IFS='= ' read -r key val _; do
  [ -z "$key" ] || [ "${key:0:1}" = "#" ] && continue
  sysctl -w "$key=$val" &>/dev/null || warn "  跳过不可写参数: $key"
done < "$SYSCFG"
set -e
info "  ✓ 网络参数已优化 (BBR + 连接跟踪 + 缓冲区)"

# =================== 6. 系统参数调优 ===================
info "=== 6/7 系统参数调优 ==="

cat > /etc/sysctl.d/99-system.conf << 'SYSEOF'
vm.swappiness = 10
vm.vfs_cache_pressure = 50
SYSEOF

set +e
while IFS='= ' read -r key val _; do
  [ -z "$key" ] || [ "${key:0:1}" = "#" ] && continue
  sysctl -w "$key=$val" &>/dev/null || warn "  跳过不可写参数: $key"
done < /etc/sysctl.d/99-system.conf
set -e

# 设置时区
timedatectl set-timezone Asia/Shanghai 2>/dev/null || true
info "  ✓ 系统参数已优化"
info "  - swappiness=10, 时区: $(timedatectl show -p Timezone --value 2>/dev/null || echo 'Asia/Shanghai')"

# =================== 7. 清理 ===================
info "=== 7/7 清理 ==="
apt autoremove --purge -y -qq 2>/dev/null || true
apt autoclean -qq 2>/dev/null || true
info "  ✓ 清理完成"

# =================== 验证 ===================
echo ""
info "========== 初始化完成 =========="
echo ""
echo "  $(grep -c processor /proc/cpuinfo) vCPU / $(free -h | awk '/^Mem:/{print $2}') RAM"
echo "  内核: $(uname -r)"
echo "  拥塞控制: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo '默认')"
echo "  防火墙: nftables（已启用，未写规则）"
echo "  时间同步: $(chronyc tracking 2>/dev/null | grep -c 'Stratum' >/dev/null && echo 'chrony ✓' || echo 'chrony')"
echo ""
info "下一步：安装具体服务"
info "  bash <(wget -qO- https://raw.githubusercontent.com/guochan2019/onekey-mosdns/main/onekey-mosdns.sh)"
info "  bash <(wget -qO- https://raw.githubusercontent.com/guochan2019/onekey-daed/main/onekey-daed.sh)"
info "  bash <(wget -qO- https://raw.githubusercontent.com/guochan2019/onekey-frpc/main/onekey-frpc.sh)"
info "  bash <(wget -qO- https://raw.githubusercontent.com/guochan2019/onekey-lucky/main/onekey-lucky.sh)"
