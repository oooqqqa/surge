#!/usr/bin/env bash
set -euo pipefail

# 定义下载链接（支持多格式域名拦截列表）
URL1="https://big.oisd.nl/"
URL2="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/multi.txt"
URL3="https://raw.githubusercontent.com/geekdada/surge-list/refs/heads/master/domain-set/dns-filter.txt"
URL4="https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/refs/heads/master/anti-ad-surge2.txt"

# 创建临时文件用于保存原始下载内容
TMP1=$(mktemp)  # AdBlock 格式列表 1
TMP2=$(mktemp)  # AdBlock 格式列表 2
TMP3=$(mktemp)  # 普通域名列表 1
TMP4=$(mktemp)  # 普通域名列表 2

# 创建临时文件用于保存处理后的内容
PROC1=$(mktemp)
PROC2=$(mktemp)
PROC3=$(mktemp)
PROC4=$(mktemp)

# 在脚本退出时自动清理所有临时文件
trap 'rm -f "$TMP1" "$TMP2" "$TMP3" "$TMP4" "$PROC1" "$PROC2" "$PROC3" "$PROC4"' EXIT

# 下载各个列表
echo "Downloading from $URL1 ..."
curl -fsSL "$URL1" -o "$TMP1"

echo "Downloading from $URL2 ..."
curl -fsSL "$URL2" -o "$TMP2"

echo "Downloading from $URL3 ..."
curl -fsSL "$URL3" -o "$TMP3"

echo "Downloading from $URL4 ..."
curl -fsSL "$URL4" -o "$TMP4"

# 处理 AdBlock 格式（形如 ||example.com^），转为 .example.com
echo "Processing AdBlock format lists..."
grep -E '^\|\|[^/]+\^$' "$TMP1" | sed -E 's/^\|\|(.*)\^$/.\1/' > "$PROC1"
grep -E '^\|\|[^/]+\^$' "$TMP2" | sed -E 's/^\|\|(.*)\^$/.\1/' > "$PROC2"

# 处理普通域名列表（去除空行和注释）
echo "Processing plain domain lists..."
grep -vE '^\s*($|#)' "$TMP3" > "$PROC3"
grep -vE '^\s*($|#)' "$TMP4" > "$PROC4"

# 分别统计各文件处理后的行数
L1=$(wc -l < "$PROC1")
L2=$(wc -l < "$PROC2")
L3=$(wc -l < "$PROC3")
L4=$(wc -l < "$PROC4")
TOTAL=$((L1 + L2 + L3 + L4))

# 合并所有列表并去重
OUTPUT="surge/reject.txt"
mkdir -p "$(dirname "$OUTPUT")"
awk '!seen[$0]++' "$PROC1" "$PROC2" "$PROC3" "$PROC4" > "$OUTPUT"
DEDUP=$(wc -l < "$OUTPUT")

# 输出处理统计信息
cat <<EOF

Processed line counts:
  List 1 (AdBlock @ $URL1):  $L1
  List 2 (AdBlock @ $URL2):  $L2
  List 3 (Domains @ $URL3): $L3
  List 4 (Domains @ $URL4): $L4
  ---------------------------------
  Total before deduplication: $TOTAL

Final merged unique lines:    $DEDUP
Output file:                  $OUTPUT

EOF