{
  description = "Declarative osu!stable on Nix (wine-osu-cheat + yawl stack, inspired by osu-winello)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    offset-calc-osu-stable = {
      url = "github:gaavin/offset-calc-osu-stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      offset-calc-osu-stable,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      versions = import ./versions.nix;

      packages = rec {
        wine-osu-cheat = pkgs.callPackage ./pkgs/wine-osu-cheat { inherit versions; };
        yawl-cheat = pkgs.callPackage ./pkgs/yawl-cheat { inherit versions; };
        osu-wineprefix-cheat = pkgs.callPackage ./pkgs/osu-wineprefix-cheat { inherit versions; };
        osu-mime-cheat = pkgs.callPackage ./pkgs/osu-mime-cheat { inherit versions; };
        rpc-bridge-cheat = pkgs.callPackage ./pkgs/rpc-bridge-cheat { inherit versions; };
        osu-wine-cheat = pkgs.callPackage ./pkgs/osu-wine-cheat {
          inherit
            versions
            wine-osu-cheat
            yawl-cheat
            osu-wineprefix-cheat
            osu-mime-cheat
            rpc-bridge-cheat
            ;
        };
        osu-offset = offset-calc-osu-stable.packages.${system}.default;
        default = osu-wine-cheat;
      };
    in
    {
      packages.${system} = packages;

      apps.${system} = {
        default = {
          type = "app";
          program = "${packages.osu-wine-cheat}/bin/osu-wine-cheat";
        };
        osu-offset = {
          type = "app";
          program = "${packages.osu-offset}/bin/osu-offset";
        };
      };

      homeModules.osu-stable-cheat =
        { lib, pkgs, ... }:
        {
          imports = [ ./modules/home-manager/osu-stable-cheat.nix ];
          # Default to this flake's osu-wine-cheat; users can still override.
          programs.osu-stable-cheat.package = lib.mkDefault (
            self.packages.${pkgs.stdenv.hostPlatform.system}.osu-wine-cheat
          );
          programs.osu-stable-cheat.offsetCalculator.package = lib.mkDefault (
            self.packages.${pkgs.stdenv.hostPlatform.system}.osu-offset
          );
        };
      homeModules.default = self.homeModules.osu-stable-cheat;

      overlays.default = final: _prev: {
        inherit (self.packages.${final.stdenv.hostPlatform.system} or packages)
          wine-osu-cheat
          yawl-cheat
          osu-wineprefix-cheat
          osu-mime-cheat
          rpc-bridge-cheat
          osu-wine-cheat
          osu-offset
          ;
      };
    };
}
