#!/usr/bin/env bash
set -euo pipefail

# Script to merge all .list files into proxy.list
OUTPUT="../proxy.list"

# Remove existing proxy.list if it exists
rm -f "$OUTPUT"

# Find all .list files and merge them
for file in *.list; do
  if [[ -f "$file" ]]; then
    echo "Adding contents from $file"
    cat "$file" >> $OUTPUT
    echo "" >> $OUTPUT
  fi
done

echo "Merged all .list files into proxy.list"
echo "Total lines in proxy.list: $(wc -l < $OUTPUT)"