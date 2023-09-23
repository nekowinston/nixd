#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash jq
#shellcheck shell=bash
set -euo pipefail

jq -rc ".[] | select(.extract)" _sources/generated.json | while read -r file; do
	name=$(jq -r ".name" <<<"$file")
	file=$(jq -r ".extract[]" <<<"$file")
	dest_dir="$PWD/pkgs/${name}"
	mkdir -p "$dest_dir"
	dub2nix save \
		-i "$PWD/_sources/$file" \
		-d "$dest_dir/dub.selections.nix" \
		-o /dev/null \
		-C /tmp/
	rm /tmp/mkDub.nix
done
