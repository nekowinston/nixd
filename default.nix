{
  pkgs ? import <nixpkgs> {},
  dcompiler ? pkgs.ldc,
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
  dcd = pkgs.stdenv.mkDerivation rec {
    inherit (nvfetcher.dcd) pname version src;
    patches = [./patches/dcd/dubhash.patch];
    postPatch = ''
      substituteInPlace common/src/dcd/common/dcd_version.d \
        --replace '"nix_version"' '"${version}"'
    '';
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

  # dfmt = mkPkg "dfmt" {};

  serve-d = let
    sources = nvfetcher."serve-d-bin-${pkgs.stdenv.hostPlatform.system}";
  in
    pkgs.stdenvNoCC.mkDerivation {
      inherit (sources) pname version src;

      dontConfigure = true;
      dontBuild = true;
      unpackPhase = ''
        runHook preUnpack

        tar xf $src

        runHook postUnpack
      '';
      installPhase = ''
        runHook preInstall

        mkdir -p $out/bin
        cp serve-d $out/bin

        runHook postInstall
      '';
    };
}
