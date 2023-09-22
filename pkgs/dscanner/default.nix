{
  dcompiler,
  mkDubDerivation,
  source,
}:
mkDubDerivation rec {
  inherit (source) pname version src;
  inherit dcompiler;
  selections = ./dub.selections.nix;

  # deal with the dubhash, set the DSCANNER_VERSION enum to the nix version
  patches = [./patches/dubhash.patch];
  postPatch = ''
    substituteInPlace \
      src/dscanner/dscanner_version.d \
      --replace 'import("dubhash.txt").strip' '"${version};"' \
      --replace 'import("githash.txt").strip' '"${version};"'
  '';
}
