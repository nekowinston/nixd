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
        selections = ./dub2nix/${pname}.dub.selections.nix;
      }
      // attrs);
in {
  dcd = pkgs.stdenv.mkDerivation rec {
    inherit (nvfetcher.dcd) pname version src;

    # deal with the dubhash, set the dcd_version enum to the nix version
    patches = [./patches/dcd/dubhash.patch];
    postPatch = ''
      substituteInPlace \
        common/src/dcd/common/dcd_version.d \
        --replace '"nix_version"' '"${version}"'
    '';

    buildInputs = [dcompiler];
    buildPhase = ''
      runHook preBuild
      # the make step is called dmd/ldc/gdc
      # hoping that pname is a sufficient shortcut
      make ${dcompiler.pname}
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

  # just packaging the binary, since it can't build with dub2nix yet
  serve-d-bin = let
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
