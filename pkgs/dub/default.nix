{
  callPackage,
  curl,
  dcompiler ? ldc,
  ldc,
  lib,
  libevent,
  rsync,
  stdenv,
}: let
  nvfetcher = (callPackage ../../_sources/generated.nix {}).dub;
in
  assert dcompiler != null;
    stdenv.mkDerivation rec {
      inherit (nvfetcher) pname version src;

      enableParallelBuilding = true;

      dubvar = "\\$DUB";
      postPatch = ''
        patchShebangs test

        # Can be removed with https://github.com/dlang/dub/pull/1368
        substituteInPlace test/fetchzip.sh \
          --replace "dub remove" "\"${dubvar}\" remove"
      '';

      nativeBuildInputs = [dcompiler libevent rsync];
      buildInputs = [curl];

      buildPhase = ''
        for dc_ in dmd ldmd2 gdmd; do
          echo "... check for D compiler $dc_ ..."
          dc=$(type -P $dc_ || echo "")
          if [ ! "$dc" == "" ]; then
            break
          fi
        done
        if [ "$dc" == "" ]; then
          exit "Error: could not find D compiler"
        fi
        echo "$dc_ found and used as D compiler to build $pname"
        $dc ./build.d
        ./build
      '';

      doCheck = false;

      installPhase = ''
        mkdir -p $out/bin
        cp bin/dub $out/bin
      '';

      meta = with lib; {
        description = "Package and build manager for D applications and libraries";
        homepage = "https://code.dlang.org/";
        license = licenses.mit;
        platforms = ["x86_64-linux" "i686-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      };
    }
