#!/usr/bin/env bash
set -euo pipefail

# 自定义规则（优先插入，参与去重）
CUSTOM_RULES_LIST=".jddebug.com
ntp.nasa.gov
av.samsungiotcloud.cn
safebrowsing.urlsec.qq.com
safebrowsing.googleapis.com"

# 第三方规则源
URL1="https://big.oisd.nl/"
URL2="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt"
URL3="https://raw.githubusercontent.com/geekdada/surge-list/refs/heads/master/domain-set/dns-filter.txt"
URL4="https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/refs/heads/master/anti-ad-surge2.txt"

# 输出路径
OUTPUT="surge/reject.txt"

# 创建临时文件
TMP1=$(mktemp)
TMP2=$(mktemp)
TMP3=$(mktemp)
TMP4=$(mktemp)
CUSTOM_TMP=$(mktemp)
PROC1=$(mktemp)
PROC2=$(mktemp)
PROC3=$(mktemp)
PROC4=$(mktemp)

# 清理函数：脚本退出时删除所有临时文件
trap 'rm -f "$TMP1" "$TMP2" "$TMP3" "$TMP4" "$CUSTOM_TMP" "$PROC1" "$PROC2" "$PROC3" "$PROC4"' EXIT

# 下载远程列表
echo "Downloading remote lists..."
curl -fsSL "$URL1" -o "$TMP1"
curl -fsSL "$URL2" -o "$TMP2"
curl -fsSL "$URL3" -o "$TMP3"
curl -fsSL "$URL4" -o "$TMP4"

# 处理 AdBlock 格式（形如 ||example.com^）
grep -E '^\|\|[^/]+\^$' "$TMP1" | sed -E 's/^\|\|(.*)\^$/.\1/' > "$PROC1"
grep -E '^\|\|[^/]+\^$' "$TMP2" | sed -E 's/^\|\|(.*)\^$/.\1/' > "$PROC2"

# 清理普通域名列表（去掉注释与空行）
grep -vE '^\s*($|#)' "$TMP3" > "$PROC3"
grep -vE '^\s*($|#)' "$TMP4" > "$PROC4"

# 写入自定义规则
echo "$CUSTOM_RULES_LIST" | grep -vE '^\s*($|#)' > "$CUSTOM_TMP"

# 合并去重，优先保留自定义规则
mkdir -p "$(dirname "$OUTPUT")"
cat "$CUSTOM_TMP" "$PROC1" "$PROC2" "$PROC3" "$PROC4" | awk '!seen[$0]++' > "$OUTPUT"

# 统计信息
count_lines() { wc -l < "$1"; }

L0=$(count_lines "$CUSTOM_TMP")
L1=$(count_lines "$PROC1")
L2=$(count_lines "$PROC2")
L3=$(count_lines "$PROC3")
L4=$(count_lines "$PROC4")
TOTAL=$((L0 + L1 + L2 + L3 + L4))
DEDUP=$(count_lines "$OUTPUT")

cat <<EOF

Processed line counts:
  Custom Rules:           $L0
  AdBlock List 1:         $L1
  AdBlock List 2:         $L2
  Domain List 1:          $L3
  Domain List 2:          $L4
  ------------------------------
  Total before dedup:     $TOTAL
  Final unique domains:   $DEDUP
  Output file:            $OUTPUT

EOF