{
  mkDubDerivation,
  source,
}:
mkDubDerivation {
  inherit (source) pname version src;
  selections = ./dub.selections.nix;
}
