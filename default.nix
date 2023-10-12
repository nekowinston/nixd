{
  pkgs ? import <nixpkgs> {},
  dcompiler ?
    if pkgs.stdenv.hostPlatform.isAarch64
    then pkgs.ldc
    else pkgs.dmd,
  dub2nix ? (fetchTarball "https://github.com/nekowinston/dub2nix/archive/refs/heads/feat/patchable-deps.tar.gz"),
}: let
  nvfetcher = pkgs.callPackage ./_sources/generated.nix {};
  mkDubDerivation = (import "${dub2nix}/mkDub.nix" {inherit pkgs dcompiler;}).mkDubDerivation;
  mkPkg = pname: attrs:
    mkDubDerivation ({
        inherit (nvfetcher.${pname}) pname version src;
        selections = ./pkgs/${pname}/dub.selections.nix;
      }
      // attrs);
  system = pkgs.stdenv.hostPlatform.system;
in rec {
  dcd = pkgs.callPackage ./pkgs/dcd {
    inherit mkDubDerivation;
    source = nvfetcher."dcd";
  };

  dfmt = mkPkg "dfmt" {};

  dscanner = pkgs.callPackage ./pkgs/dscanner {
    inherit mkDubDerivation;
    source = nvfetcher."dscanner";
  };

  dub = pkgs.callPackage ./pkgs/dub {};

  # TODO: fix `staticLibrary` builds with dub2nix, this depends on it
  # serve-d = pkgs.callPackage ./pkgs/serve-d {
  #   inherit dcompiler mkDubDerivation;
  #   source = nvfetcher."serve-d";
  # };

  # just packaging the binary, since it can't build with dub2nix yet
  serve-d = serve-d-bin;
  serve-d-bin = pkgs.callPackage ./pkgs/serve-d-bin {source = nvfetcher."serve-d-bin-${system}";};
}
