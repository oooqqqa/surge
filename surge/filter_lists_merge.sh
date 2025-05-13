#!/usr/bin/env bash
set -euo pipefail

#—— 定义 URL ——#
URL1="https://big.oisd.nl/"
URL2="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.txt"
URL3="https://raw.githubusercontent.com/geekdada/surge-list/refs/heads/master/domain-set/dns-filter.txt"
URL4="https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/refs/heads/master/anti-ad-surge2.txt"

#—— 临时文件 ——#
TMP1=$(mktemp)  # raw1
TMP2=$(mktemp)  # raw2
TMP3=$(mktemp)  # raw3
TMP4=$(mktemp)  # raw4

PROC1=$(mktemp) # 处理后列表1
PROC2=$(mktemp) # 处理后列表2
PROC3=$(mktemp) # 处理后列表3
PROC4=$(mktemp) # 处理后列表4

# 脚本退出时清理
trap 'rm -f "$TMP1" "$TMP2" "$TMP3" "$TMP4" "$PROC1" "$PROC2" "$PROC3" "$PROC4"' EXIT

#—— 下载原始文件 ——#
echo "Downloading $URL1 ..."
curl -fsSL "$URL1" -o "$TMP1"

echo "Downloading $URL2 ..."
curl -fsSL "$URL2" -o "$TMP2"

echo "Downloading $URL3 ..."
curl -fsSL "$URL3" -o "$TMP3"

echo "Downloading $URL4 ..."
curl -fsSL "$URL4" -o "$TMP4"

#—— 处理 AdBlock 格式，提取 ||域名^ 并转换为 .域名 ——#
echo "Processing AdBlock lists..."
grep -E '^\|\|[^/]+\^$' "$TMP1" \
  | sed -E 's/^\|\|(.*)\^$/.\1/' > "$PROC1"

grep -E '^\|\|[^/]+\^$' "$TMP2" \
  | sed -E 's/^\|\|(.*)\^$/.\1/' > "$PROC2"

#—— 处理普通域名列表 ——#
echo "Processing plain domain lists..."
# 直接去掉可能的空行和注释
grep -vE '^\s*($|#)' "$TMP3" > "$PROC3"
grep -vE '^\s*($|#)' "$TMP4" > "$PROC4"

#—— 统计行数 ——#
L1=$(wc -l < "$PROC1")
L2=$(wc -l < "$PROC2")
L3=$(wc -l < "$PROC3")
L4=$(wc -l < "$PROC4")
TOTAL=$((L1 + L2 + L3 + L4))

#—— 合并并去重 ——#
OUTPUT="reject.txt"
awk '!seen[$0]++' "$PROC1" "$PROC2" "$PROC3" "$PROC4" > "$OUTPUT"
DEDUP=$(wc -l < "$OUTPUT")

#—— 输出结果 ——#
cat <<EOF

处理后行数：
  列表1 (AdBlock @ $URL1) 行数:   $L1
  列表2 (AdBlock @ $URL2) 行数:   $L2
  列表3 (域名 @ $URL3)    行数:   $L3
  列表4 (域名 @ $URL4)    行数:   $L4
  ————————————————————————
  合计行数:                 $TOTAL

去重合并后行数: $DEDUP
输出文件:       $OUTPUT

EOF