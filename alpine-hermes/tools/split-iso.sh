#!/bin/sh -eu

iso="${1:-dist/alpine-v86-260722-x86.iso}"
output_dir="${2:-assets}"
chunk_size=16777216
stem="alpine-v86-260722-x86"

if [ ! -f "$iso" ]; then
	echo "ISO not found: $iso" >&2
	exit 1
fi

mkdir -p "$output_dir"
size="$(wc -c < "$iso")"
offset=0
index=0

while [ "$offset" -lt "$size" ]; do
	end=$((offset + chunk_size))
	part="$output_dir/$stem-$offset-$end.iso"
	dd if="$iso" of="$part" bs="$chunk_size" skip="$index" count=1 status=none
	echo "Wrote $part"
	offset="$end"
	index=$((index + 1))
done

sha256sum "$output_dir"/$stem-*-*.iso > "$output_dir/SHA256SUMS"
