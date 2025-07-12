#!/usr/bin/env bash
set -euo pipefail

# 配置
CUSTOM_RULES_LIST=".jddebug.com
ntp.nasa.gov
av.samsungiotcloud.cn
safebrowsing.urlsec.qq.com
safebrowsing.googleapis.com
safebrowsing.googleapis-cn.com"

ADBLOCK_SOURCES=(
  "https://big.oisd.nl/"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt"
)

PLAIN_DOMAIN_SOURCES=(
  "https://raw.githubusercontent.com/geekdada/surge-list/refs/heads/master/domain-set/dns-filter.txt"
  "https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/refs/heads/master/anti-ad-surge2.txt"
)

OUTPUT_FILE="reject.txt"

# 临时文件管理
temp_files=()
make_temp() {
  local tmp
  tmp=$(mktemp)
  temp_files+=("$tmp")
  echo "$tmp"
}
trap 'rm -f "${temp_files[@]:-}"' EXIT

# 工具函数
download_file() {
  local url="$1" dest="$2"
  if ! curl -fsSL "$url" -o "$dest"; then
    echo "Failed to download $url" >&2
    exit 1
  fi
}

process_adblock_file() {
  grep -E '^\|\|[^/]+\^$' "$1" | sed -E 's/^\|\|(.*)\^$/.\1/'
}

process_plain_domain_file() {
  grep -vE '^\s*($|#)' "$1"
}

# 主逻辑
echo "Downloading and processing blocklists..."

custom_tmp=$(make_temp)
echo "$CUSTOM_RULES_LIST" | grep -vE '^\s*($|#)' > "$custom_tmp"

processed_lists=()

for url in "${ADBLOCK_SOURCES[@]}"; do
  raw=$(make_temp)
  processed=$(make_temp)
  download_file "$url" "$raw"
  process_adblock_file "$raw" > "$processed"
  processed_lists+=("$processed")
done

for url in "${PLAIN_DOMAIN_SOURCES[@]}"; do
  raw=$(make_temp)
  processed=$(make_temp)
  download_file "$url" "$raw"
  process_plain_domain_file "$raw" > "$processed"
  processed_lists+=("$processed")
done

cat "$custom_tmp" "${processed_lists[@]}" | awk '!seen[$0]++' > "$OUTPUT_FILE"

# 统计信息
count_lines() {
  wc -l < "$1"
}

echo
echo "Processed line counts:"
printf "  Custom Rules:           %5d\n" "$(count_lines "$custom_tmp")"

for i in "${!processed_lists[@]}"; do
  printf "  Source %d:               %5d\n" "$((i + 1))" "$(count_lines "${processed_lists[$i]}")"
done

total=0
for f in "${processed_lists[@]}" "$custom_tmp"; do
  total=$((total + $(count_lines "$f")))
done

final_count=$(count_lines "$OUTPUT_FILE")

echo "  ------------------------------"
printf "  Total before dedup:     %5d\n" "$total"
printf "  Final unique domains:   %5d\n" "$final_count"
echo "  Output file:            $OUTPUT_FILE"