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
OUTPUT_MINI_FILE="reject_mini.txt"

# 临时文件管理
temp_files=()
make_temp() {
  local tmp
  tmp=$(mktemp)
  temp_files+=("$tmp")
  echo "$tmp"
}

cleanup() {
  if [[ ${#temp_files[@]} -gt 0 ]]; then
    rm -f "${temp_files[@]}"
  fi
}
trap cleanup EXIT INT TERM

# 工具函数
download_file() {
  local url="$1" dest="$2"
  echo "    Downloading: $url"
  if ! curl -fsSL --connect-timeout 30 --max-time 120 "$url" -o "$dest"; then
    echo "ERROR: Failed to download $url" >&2
    return 1
  fi
  # 验证文件非空
  if [[ ! -s "$dest" ]]; then
    echo "ERROR: Downloaded file is empty: $url" >&2
    return 1
  fi
}

process_adblock_file() {
  local input="$1"
  # 提取 ||domain^$ 格式并转换为 .domain
  grep -E '^\|\|[^/]+\^$' "$input" | sed -E 's/^\|\|(.*)\^$/.\1/' | grep -v '^.$'
}

process_plain_domain_file() {
  local input="$1"
  # 过滤空行和注释，确保域名格式正确
  grep -vE '^\s*($|#)' "$input" | grep -E '^\.?[a-zA-Z0-9.-]+$'
}

count_lines() {
  if [[ -f "$1" && -s "$1" ]]; then
    wc -l < "$1"
  else
    echo "0"
  fi
}

# 开始处理
echo "Downloading and processing blocklists..."

# 处理自定义规则
custom_tmp=$(make_temp)
echo "$CUSTOM_RULES_LIST" | grep -vE '^\s*($|#)' > "$custom_tmp"

processed_lists=()

# 处理 Adblock 格式源
echo "  Processing Adblock format sources..."
for url in "${ADBLOCK_SOURCES[@]}"; do
  raw=$(make_temp)
  processed=$(make_temp)
  
  if download_file "$url" "$raw"; then
    if process_adblock_file "$raw" > "$processed" && [[ -s "$processed" ]]; then
      processed_lists+=("$processed")
      echo "    Processed $(count_lines "$processed") rules from Adblock source"
    else
      echo "    WARNING: No valid rules found in Adblock source: $url"
    fi
  else
    echo "    ERROR: Skipping failed Adblock source: $url"
  fi
done

# 处理纯域名格式源
echo "  Processing plain domain sources..."
for url in "${PLAIN_DOMAIN_SOURCES[@]}"; do
  raw=$(make_temp)
  processed=$(make_temp)
  
  if download_file "$url" "$raw"; then
    if process_plain_domain_file "$raw" > "$processed" && [[ -s "$processed" ]]; then
      processed_lists+=("$processed")
      echo "    Processed $(count_lines "$processed") rules from domain source"
    else
      echo "    WARNING: No valid rules found in domain source: $url"
    fi
  else
    echo "    ERROR: Skipping failed domain source: $url"
  fi
done

# 检查是否有成功处理的外部源
if [[ ${#processed_lists[@]} -eq 0 ]]; then
  echo "ERROR: No external sources were successfully processed!" >&2
  exit 1
fi

# 生成完整 reject.txt
echo "  Generating complete reject list..."
{
  cat "$custom_tmp"
  cat "${processed_lists[@]}"
} | awk '!seen[$0]++' > "$OUTPUT_FILE"

# 生成 reject_mini.txt (只包含在2个或更多外部源中出现的域名)
echo "  Generating mini reject list..."
external_combined=$(make_temp)
cat "${processed_lists[@]}" > "$external_combined"

# 修正：找出出现2次或更多的域名
external_frequent=$(make_temp)
sort "$external_combined" | uniq -c | awk '$1 >= 2 {print $2}' > "$external_frequent"

# 合并自定义规则和频繁出现的外部规则
{
  cat "$custom_tmp"
  cat "$external_frequent"
} | awk '!seen[$0]++' > "$OUTPUT_MINI_FILE"

# 统计输出
echo
echo "Processing Summary:"
echo "  =========================="
printf "  Custom Rules:           %6d\n" "$(count_lines "$custom_tmp")"

for i in "${!processed_lists[@]}"; do
  source_name=""
  case $i in
    0|1) source_name="Adblock" ;;
    *) source_name="Domain" ;;
  esac
  printf "  %s Source %d:        %6d\n" "$source_name" "$((i + 1))" "$(count_lines "${processed_lists[$i]}")"
done

# 计算总数
total=0
total=$(($(count_lines "$custom_tmp")))
for f in "${processed_lists[@]}"; do
  total=$((total + $(count_lines "$f")))
done

final_count=$(count_lines "$OUTPUT_FILE")
mini_count=$(count_lines "$OUTPUT_MINI_FILE")
frequent_count=$(count_lines "$external_frequent")

echo "  --------------------------"
printf "  Total before dedup:     %6d\n" "$total"
printf "  Final unique domains:   %6d\n" "$final_count"
if [[ $total -gt 0 ]]; then
  dedup_rate=$(awk "BEGIN {printf \"%.1f\", ($total - $final_count) / $total * 100}")
  printf "  Deduplication rate:     %6.1f%%\n" "$dedup_rate"
else
  printf "  Deduplication rate:        0.0%%\n"
fi
echo
echo "Output Files:"
printf "  Complete list:          %s (%d domains)\n" "$OUTPUT_FILE" "$final_count"
printf "  Mini list:              %s (%d domains)\n" "$OUTPUT_MINI_FILE" "$mini_count"
echo
echo "Mini List Details:"
printf "  External duplicates:    %6d\n" "$frequent_count"
printf "  Custom rules:           %6d\n" "$(count_lines "$custom_tmp")"
printf "  Total mini rules:       %6d\n" "$mini_count"
if [[ $final_count -gt 0 ]]; then
  size_reduction=$(awk "BEGIN {printf \"%.1f\", (1 - $mini_count / $final_count) * 100}")
  printf "  Size reduction:         %6.1f%%\n" "$size_reduction"
else
  printf "  Size reduction:            0.0%%\n"
fi

echo
echo "Processing completed successfully!"