#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# 获取 Git 根目录
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "ERROR: Not inside a git repository." >&2
  exit 1
}

INPUT_DIR="$GIT_ROOT/proxy"
OUTPUT="$GIT_ROOT/proxy.list"
LIST_FILES=( "$INPUT_DIR"/*.list )

# 无输入文件则退出
(( ${#LIST_FILES[@]} > 0 )) || {
  echo "ERROR: No .list files found in $INPUT_DIR." >&2
  exit 1
}

rm -f "$OUTPUT"
echo "==> Merging ${#LIST_FILES[@]} files from $INPUT_DIR into: $OUTPUT"

for file in "${LIST_FILES[@]}"; do
  echo "  -> $file"

  # 去除末尾空行，保留中间结构
  awk 'BEGIN { blank = 0 }
       NF { print; blank = 0; next }
       !blank { print ""; blank = 1 }' "$file" |
  perl -0777 -pe 's/\n{2,}\z/\n/' >> "$OUTPUT"

done

lines=$(wc -l < "$OUTPUT" || echo 0)
echo "==> Done. Total lines: $lines"

shopt -u nullglob