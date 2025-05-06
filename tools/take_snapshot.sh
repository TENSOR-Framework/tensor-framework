#!/usr/bin/env bash
# tools/take_snapshot.sh  – project-authored files (+ file list) in a tar.gz
set -euo pipefail

root=$(git rev-parse --show-toplevel); cd "$root"
ts=$(date -u +'%Y-%m-%dT%H-%M-%SZ')
bundle="snapshots/tensor-dump-${ts}.tar.gz"
tmp=$(mktemp -d); mkdir -p snapshots

# -------------------------------------------------
# 1. collect git-tracked, project-authored files
# -------------------------------------------------
skip='^(site/studio/vendor/|node_modules/|_site/)'
mapfile -t paths < <(git ls-files | grep -Ev "$skip" | sort)

# write inventory for console & tar
printf "%s\n" "${paths[@]}" | tee "$tmp/FILE-LIST.txt"

# copy text & code files; stub binaries
for p in "${paths[@]}"; do
  dest="$tmp/$p"
  mkdir -p "$(dirname "$dest")"
  if file --mime -b "$p" | grep -q text; then
    cp "$p" "$dest"
  else
    echo "[binary file — omitted]" > "$dest"
  fi
done

# -------------------------------------------------
# 2. create tarball
# -------------------------------------------------
tar -C "$tmp" -czf "$bundle" .
rm -rf "$tmp"
echo "✅  Snapshot written to $bundle"
