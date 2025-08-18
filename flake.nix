{
  description = "A decentralized DNS and mesh network protocol";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    naersk.url = "github:nmattia/naersk";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, naersk }:
    let
      systems = [
        "aarch64-linux"
        "aarch64-darwin"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
        "i686-windows"
        "x86_64-windows"
      ];

    in flake-utils.lib.eachSystem systems (system:
      let

        pkgs = nixpkgs.legacyPackages.${system};

        naersk-lib = naersk.lib.${system};

        ruvname = { webgui ? true, doh ? true, edge ? false }:
          let
            features = builtins.concatStringsSep " " (builtins.concatMap
              ({ option, features }: pkgs.lib.optionals option features) [
                {
                  option = webgui;
                  features = [ "webgui" ];
                }
                {
                  option = doh;
                  features = [ "doh" ];
                }
                {
                  option = edge;
                  features = [ "edge" ];
                }
              ]);
          in naersk-lib.buildPackage {
            pname = "ruvname";
            nativeBuildInputs = with pkgs; [ pkg-config webkitgtk kdialog ];
            dontWrapQtApps = true;
            cargoBuildOptions = opts:
              opts ++ [ "--no-default-features" ]
              ++ [ "--features" ''"${features}"'' ];
            root = ./.;
          };

        isWindows = builtins.elem system [ "i686-windows" "x86_64-windows" ];
      in rec {

        packages = {
          ruvname = ruvname {
            webgui = true;
            doh = true;
            edge = false;
          };
          ruvnameWithoutGUI = ruvname {
            webgui = false;
            doh = true;
            edge = false;
          };
        } // pkgs.lib.optionalAttrs isWindows {
          ruvnameEdge = ruvname {
            webgui = false;
            doh = true;
            edge = true;
          };
        };

        defaultPackage = packages.ruvname;

        apps = with flake-utils.lib;
          {
            ruvname = mkApp { drv = packages.ruvname; };
            ruvnameWithoutGUI = mkApp { drv = packages.ruvnameWithoutGUI; };
          } // pkgs.lib.optionalAttrs isWindows {
            ruvnameEdge = mkApp { drv = packages.ruvnameEdge; };
          };
        defaultApp = apps.ruvname;

        devShell = import ./shell.nix { inherit pkgs; };

      });
}
