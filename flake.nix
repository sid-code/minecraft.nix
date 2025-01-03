{
  description = "Command line Minecraft launcher managed by nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.metadata = {
    url = "github:Ninlives/minecraft.json";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    metadata,
  }:
    with flake-utils.lib;
      eachDefaultSystem (system: let
        inherit (pkgs) lib;
        pkgs = nixpkgs.legacyPackages.${system};
        OS = with pkgs.stdenv;
          if isLinux
          then "linux"
          else if isDarwin
          then "osx"
          else builtins.throw "Unsupported system ${system}";
        py = pkgs.python3.withPackages (p: [p.requests]);
      in {
        legacyPackages = lib.makeOverridable (import ./all-packages.nix) {
          inherit pkgs lib metadata OS;
          # Users may override this with their own application id
          authClientID = "7e6f5a7f-17fb-420e-81f2-96ee1a11615b";
        };
        devShells.auth = pkgs.mkShell {
          nativeBuildInputs = [
            (pkgs.python3.withPackages (p: (import ./module/auth-libs.nix {python3Packages = p;})))
          ];
        };
        apps.update = mkApp {
          drv = let
            snippet = dir: ''
              pushd ./${dir}
              ${py}/bin/python update.py
              popd
            '';
          in
            pkgs.writeShellScriptBin "update" ''
              ${snippet "fabric"}
              ${snippet "vanilla"}
            '';
        };
      });
}
