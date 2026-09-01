#!/usr/bin/env bash
# 漱玉 Shuyu —— 本地部署脚本
#
# 将仓库中的 rime 方案与墨玉主题部署到 fcitx5 用户目录（全部为用户级文件，无需 root）。
# 部署前请先安装系统依赖（需要 root 权限）：
#   fcitx5（≥ 5.1.13）、fcitx5-rime、rime-double-pinyin
#
# 用法:
#   ./deploy.sh          # 部署（install）
#   ./deploy.sh remove   # 撤销部署
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RIME_USER="$HOME/.local/share/fcitx5/rime"
THEMES_DIR="$HOME/.local/share/fcitx5/themes"
FCITX_CONF="$HOME/.config/fcitx5"

RIME_FILES=(
  shuyu.schema.yaml
  shuyu_pinyin.schema.yaml
  shuyu.dict.yaml
  default.custom.yaml
)

profile_content() {
  cat <<'EOF'
[Groups/0]
# Group Name
Name=Default
# Layout
Default Layout=us
# Default Input Method
DefaultIM=rime

[Groups/0/Items/0]
# Name
Name=keyboard-us
# Layout
Layout=

[Groups/0/Items/1]
# Name
Name=rime
# Layout
Layout=

[GroupOrder]
0=Default
EOF
}

install() {
  echo "漱玉 Shuyu —— 部署到 fcitx5 用户目录"

  # 先停止 fcitx5：否则它退出时会用内存状态覆盖刚写入的 profile
  if command -v systemctl >/dev/null && systemctl --user is-active --quiet omarchy-fcitx5.service 2>/dev/null; then
    systemctl --user stop omarchy-fcitx5.service
    echo "  → 已停止 omarchy-fcitx5.service"
  fi
  # SIGKILL 杀死游离实例（如桌面会话自行启动的 fcitx5）：
  # 不给它优雅退出存盘的机会，避免用内存状态覆盖刚写入的 profile
  pkill -9 -x fcitx5 2>/dev/null || true
  sleep 1

  mkdir -p "$RIME_USER" "$THEMES_DIR" "$FCITX_CONF/conf"

  for f in "${RIME_FILES[@]}"; do
    ln -sfn "$REPO_DIR/rime/$f" "$RIME_USER/$f"
    echo "  → $RIME_USER/$f"
  done

  ln -sfn "$REPO_DIR/themes/shuyu" "$THEMES_DIR/shuyu"
  echo "  → $THEMES_DIR/shuyu"

  # profile:先备份再写入
  if [[ -f "$FCITX_CONF/profile" ]]; then
    cp -f "$FCITX_CONF/profile" "$FCITX_CONF/profile.bak.$(date +%s)"
    echo "  → 已备份原 profile"
  fi
  profile_content > "$FCITX_CONF/profile"
  echo "  → $FCITX_CONF/profile（keyboard-us + rime）"

  printf 'Theme=shuyu\n' > "$FCITX_CONF/conf/classicui.conf"
  echo "  → $FCITX_CONF/conf/classicui.conf"

  echo
  echo "完成。重启输入法生效："
  echo "  omarchy restart xcompose   # Omarchy 环境"
  echo "  # 其他发行版请自行重启 fcitx5"
  echo "  首次切换到 rime 会触发方案编译（数秒）。"
}

remove() {
  echo "漱玉 Shuyu —— 撤销部署"
  for f in "${RIME_FILES[@]}"; do
    rm -f "$RIME_USER/$f"
    echo "  × $RIME_USER/$f"
  done
  rm -f "$THEMES_DIR/shuyu"
  echo "  × $THEMES_DIR/shuyu"
  rm -f "$FCITX_CONF/conf/classicui.conf"
  echo "  × $FCITX_CONF/conf/classicui.conf"
  if [[ -f "$FCITX_CONF/profile" ]]; then
    rm -f "$FCITX_CONF/profile"
    echo "  × $FCITX_CONF/profile（备份仍在同目录 *.bak.* 文件中，可手动恢复）"
  fi
  echo
  echo "完成后重启输入法：omarchy restart xcompose"
}

case "${1:-install}" in
  install) install ;;
  remove) remove ;;
  *) echo "用法: $0 [install|remove]" >&2; exit 1 ;;
esac
