#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash jq
#shellcheck shell=bash
set -euo pipefail

jq -rc ".[] | select(.extract)" _sources/generated.json | while read -r file; do
	name=$(jq -r ".name" <<<"$file")
	file=$(jq -r ".extract[]" <<<"$file")
	dub2nix save \
		-i "$PWD/_sources/$file" \
		-d "$PWD/dub2nix/${name}.dub.selections.nix" \
		-o /dev/null \
		-C /tmp/
	rm /tmp/mkDub.nix
done
