{
  source,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;

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

  meta = {
    mainProgram = "serve-d";
  };
}
