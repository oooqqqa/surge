#!/bin/bash

# Script to merge all .list files into proxy.list
# Remove existing proxy.list if it exists
rm -f proxy.list

# Find all .list files and merge them
for file in *.list; do
    if [[ -f "$file" ]]; then
        echo "Adding contents from $file"
        cat "$file" >> proxy.list
        echo "" >> proxy.list
    fi
done

echo "Merged all .list files into proxy.list"
echo "Total lines in proxy.list: $(wc -l < proxy.list)"