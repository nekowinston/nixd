{
  lib,
  mkDubDerivation,
  source,
}:
mkDubDerivation {
  inherit (source) pname version src;
  selections = ./dub.selections.nix;
  # deal with the dubhash, set the dcd_version enum to the nix version
  patches = [./patches/dubhash.patch];
  postPatch = ''
    substituteInPlace \
      common/src/dcd/common/dcd_version.d \
      --replace '"nix_version"' '"${source.version}"'
  '';

  extraDubFlags = "--config=client";
  postBuild = ''
    dub build --build=release --config=server --combined
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp bin/dcd-{client,server} $out/bin
    runHook postInstall
  '';

  meta = {
    mainProgram = "dcd-server";
  };
}
