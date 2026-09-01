#!/usr/bin/env bash
# 漱玉 E2E 测试(焦点安全版):每步键入前校验焦点
set -u
OUT=/tmp/shuyu-e2e.txt
rm -f "$OUT"

hyprctl dispatch "hl.dsp.focus({workspace='8'})" >/dev/null 2>&1
sleep 1

foot -T shuyu-test sh -c 'cat > "$0"' "$OUT" 2>/dev/null &
FOOT_PID=$!
sleep 2.5

hyprctl dispatch "hl.dsp.focus({window='title:shuyu-test'})" >/dev/null 2>&1
sleep 1

TITLE=$(hyprctl activewindow 2>/dev/null | grep -oP '(?<=title: ).*' | head -1)
if [[ "$TITLE" != *"shuyu-test"* ]]; then
  echo "焦点校验失败,中止(当前焦点: $TITLE)"; kill $FOOT_PID 2>/dev/null
  hyprctl dispatch "hl.dsp.focus({workspace='1'})" >/dev/null 2>&1
  exit 1
fi
echo "焦点 OK: $TITLE"

# 对照组:关闭 IME 直接裸输入
fcitx5-remote -t >/dev/null 2>&1  # 确保关闭
sleep 0.5
wtype 'abc'; wtype -k Return; sleep 1
echo "--- [对照] 裸输入 abc+回车 → [$(cat "$OUT")]"

# 全拼
fcitx5-remote -s rime >/dev/null 2>&1
dbus-send --session --type=method_call --dest=org.fcitx.Fcitx5 /rime org.fcitx.Fcitx.Rime1.SetSchema string:shuyu_pinyin >/dev/null 2>&1
sleep 1
echo "--- 全拼: 键入 shuyu + 空格 + 回车"
wtype 'shuyu'; sleep 1.5; wtype -k space; sleep 1.5; wtype -k Return; sleep 1.5
echo "全拼输出: [$(cat "$OUT")]"

# 双拼
dbus-send --session --type=method_call --dest=org.fcitx.Fcitx5 /rime org.fcitx.Fcitx.Rime1.SetSchema string:shuyu >/dev/null 2>&1
sleep 1
echo "--- 双拼: 键入 uuyu + 空格 + 回车"
wtype 'uuyu'; sleep 1.5; wtype -k space; sleep 1.5; wtype -k Return; sleep 1.5
echo "双拼输出: [$(cat "$OUT")]"

kill $FOOT_PID 2>/dev/null
hyprctl dispatch "hl.dsp.focus({workspace='1'})" >/dev/null 2>&1
echo "测试结束"
