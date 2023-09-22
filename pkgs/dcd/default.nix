{
  dcompiler,
  stdenv,
  source,
}:
stdenv.mkDerivation rec {
  inherit (source) pname version src;

  # deal with the dubhash, set the dcd_version enum to the nix version
  patches = [./patches/dubhash.patch];
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
    make SHELL="sh" ${dcompiler.pname}
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp bin/dcd-{client,server} $out/bin
    runHook postInstall
  '';
}
