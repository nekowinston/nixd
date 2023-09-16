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
        self',
        ...
      }: {
        checks = self'.packages;

        packages = import ./. {
          inherit pkgs;
          inherit (inputs) dub2nix;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            (import inputs.dub2nix {inherit pkgs;})
            pkgs.just
            pkgs.nvfetcher
          ];
        };

        formatter = pkgs.alejandra;
      };
    };
}
