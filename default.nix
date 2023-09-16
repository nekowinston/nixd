{
  pkgs ? import <nixpkgs> {},
  dcompiler ?
    if pkgs.stdenv.hostPlatform.system == "aarch64-darwin"
    then pkgs.ldc
    else pkgs.dmd,
  dub2nix ? (fetchTarball "https://github.com/lionello/dub2nix/archive/refs/heads/${(builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.dub2nix.locked.rev}.zip"),
}: let
  nvfetcher = pkgs.callPackage ./_sources/generated.nix {};
  mkDubDerivation = (import "${dub2nix}/mkDub.nix" {inherit pkgs dcompiler;}).mkDubDerivation;
  mkPkg = pname: attrs:
    mkDubDerivation ({
        inherit (nvfetcher.${pname}) pname version src;
        selections = ./dub2nix/${pname}.dub.selections.nix;
      }
      // attrs);
in {
  dcd = pkgs.stdenv.mkDerivation {
    inherit (nvfetcher.dcd) pname version src;
    patches = [./patches/dcd/dubhash.patch];
    buildInputs = [dcompiler];
    buildPhase = ''
      runHook preBuild
      make ldc
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp bin/dcd-{client,server} $out/bin
      runHook postInstall
    '';
  };

  dfmt = mkPkg "dfmt" {};

  # FIXME: broken :(
  # serve-d = mkPkg "serve-d" {};
}
