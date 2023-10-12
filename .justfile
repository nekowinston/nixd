default:
  @just --choose

update:
  nix run github:berberman/nvfetcher
  ./update.sh
