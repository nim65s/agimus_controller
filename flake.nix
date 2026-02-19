{
  description = "Whole Body Model Predictive Control in the AGIMUS architecture";

  inputs = {
    gazebros2nix.url = "github:gepetto/gazebros2nix";
    flake-parts.follows = "gazebros2nix/flake-parts";
    nixpkgs.follows = "gazebros2nix/nixpkgs";
    nix-ros-overlay.follows = "gazebros2nix/nix-ros-overlay";
    systems.follows = "gazebros2nix/systems";
    treefmt-nix.follows = "gazebros2nix/treefmt-nix";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, self, ... }:
      let
        distros = [
          "humble"
          "jazzy"
          "kilted"
          "rolling"
        ];
        packages = {
          agimus-controller = _final: _ros-final: {
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                ./agimus_controller
              ];
            };
          };

          # agimus-controller-examples = _final: _ros-final: {
          #   src = lib.fileset.toSource {
          #     root = ./.;
          #     fileset = lib.fileset.unions [
          #       ./agimus_controller_examples
          #     ];
          #   };
          # };

          agimus-controller-ros = _final: _ros-final: {
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                ./agimus_controller_ros
              ];
            };
          };

        };
      in
      {
        systems = [ "x86_64-linux" ];
        imports = [
          inputs.gazebros2nix.flakeModule
          { gazebros2nix-pkgs.overlays = [ self.overlays.default ]; }
        ];
        flake.overlays.default = final: prev: {
          rosPackages =
            prev.rosPackages
            // lib.genAttrs distros (
              d:
              prev.rosPackages."${d}".overrideScope (
                ros-final: ros-prev:
                lib.mapAttrs (
                  package: override: ros-prev.${package}.overrideAttrs (override final ros-final)
                ) packages

              )
            );
        };
        perSystem =
          { pkgs, self', ... }:
          {
            packages = {
              default = self'.packages.ros-rolling-agimus-controller-ros;
            }
            // lib.listToAttrs (
              lib.mapCartesianProduct
                (
                  { distro, package }:
                  lib.nameValuePair "ros-${distro}-${package}" pkgs.rosPackages."${distro}"."${package}"
                )
                {
                  distro = distros;
                  package = lib.attrNames packages;
                }
            );
          };
      }
    );
}
