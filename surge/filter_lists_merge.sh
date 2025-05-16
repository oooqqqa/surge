#!/usr/bin/env bash
set -euo pipefail

#—— 定义 URL ——#
URL1="https://big.oisd.nl/"
URL2="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt"
# URL3="https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
# URL4="https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/refs/heads/master/anti-ad-surge2.txt"

#—— 临时文件 ——#
TMP1=$(mktemp)  # raw1
TMP2=$(mktemp)  # raw2

PROC1=$(mktemp) # 处理后列表1
PROC2=$(mktemp) # 处理后列表2

# 脚本退出时清理
trap 'rm -f "$TMP1" "$TMP2" "$PROC1" "$PROC2"' EXIT

#—— 下载原始文件 ——#
echo "Downloading $URL1 ..."
curl -fsSL "$URL1" -o "$TMP1"

echo "Downloading $URL2 ..."
curl -fsSL "$URL2" -o "$TMP2"

#—— 处理 AdBlock 格式，提取 ||域名^ 并转换为 .域名 ——#
echo "Processing AdBlock lists..."
grep -E '^\|\|[^/]+\^$' "$TMP1" \
  | sed -E 's/^\|\|(.*)\^$/.\1/' > "$PROC1"

grep -E '^\|\|[^/]+\^$' "$TMP2" \
  | sed -E 's/^\|\|(.*)\^$/.\1/' > "$PROC2"

#—— 统计行数 ——#
L1=$(wc -l < "$PROC1")
L2=$(wc -l < "$PROC2")
TOTAL=$((L1 + L2))

#—— 合并并去重 ——#
OUTPUT="surge/reject.txt"
awk '!seen[$0]++' "$PROC1" "$PROC2" > "$OUTPUT"
DEDUP=$(wc -l < "$OUTPUT")

#—— 输出结果 ——#
cat <<EOF

处理后行数：
  列表1 (AdBlock @ $URL1) 行数:   $L1
  列表2 (AdBlock @ $URL2) 行数:   $L2
  ————————————————————————
  合计行数:      $TOTAL

去重合并后行数:  $DEDUP
输出文件:       $OUTPUT

EOF