{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dub2nix.url = "github:lionello/dub2nix";
    dub2nix.flake = false;
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        pkgs,
        system,
        ...
      }: let
        dub2nix = import inputs.dub2nix {inherit pkgs;};
        dcompiler =
          if system == "aarch64-darwin"
          then pkgs.ldc
          else pkgs.dmd;
        mkDubDerivation = (import "${inputs.dub2nix}/mkDub.nix" {inherit pkgs dcompiler;}).mkDubDerivation;
        nvfetcher = pkgs.callPackage ./_sources/generated.nix {};
      in {
        packages = let
          mkPkg = pname: attrs:
            mkDubDerivation ({
                inherit (nvfetcher.${pname}) pname version src;
                selections = ./dub2nix/${pname}.dub.selections.nix;
              }
              // attrs);
        in {
          containers = mkPkg "containers" {};
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
              cp -r bin/* $out/bin
              runHook postInstall
            '';
          };
          dfmt = mkPkg "dfmt" {};
          serve-d = mkPkg "serve-d" {};
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.dub
            dub2nix
            pkgs.ldc
            pkgs.nvfetcher
          ];
        };
      };
    };
}
