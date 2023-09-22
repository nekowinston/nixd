{
  pkgs ? import <nixpkgs> {},
  dcompiler ?
    if pkgs.stdenv.hostPlatform.system == "aarch64-darwin"
    then pkgs.ldc
    else pkgs.dmd,
  dub2nix ? (let
    inherit (builtins.fromJSON (builtins.readFile ./flake.lock).nodes.dub2nix.locked) rev;
  in
    fetchTarball "https://github.com/lionello/dub2nix/archive/refs/${rev}.tar.gz"),
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
    inherit dcompiler;
    source = nvfetcher."dcd";
  };

  dfmt = mkPkg "dfmt" {};

  # TODO: not quite ready yet, another dub2nix issue
  # dscanner = pkgs.callPackage ./pkgs/dscanner {
  #   inherit dcompiler mkDubDerivation;
  #   source = nvfetcher."dscanner";
  # };

  # just packaging the binary, since it can't build with dub2nix yet
  serve-d = serve-d-bin;
  serve-d-bin = pkgs.callPackage ./pkgs/serve-d-bin {source = nvfetcher."serve-d-bin-${system}";};
}
