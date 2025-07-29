{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, emacs-overlay, ... }:
    let
      pkgsFor =
        system:
        (import nixpkgs {
          inherit system;
          overlays = [ emacs-overlay.overlays.default ];
        });
    in
    rec {
      packages."x86_64-linux" =
        let
          pkgs = pkgsFor "x86_64-linux";
        in
        rec {
          emacs = pkgs.emacs-unstable-pgtk;
          emacsWithPackages = (pkgs.emacsPackagesFor emacs).emacsWithPackages (import ./emacsPackages.nix);
          default = pkgs.writeShellScriptBin "emacs-wrapped" ''
            ${emacsWithPackages}/bin/emacs --init-directory=${./config}
          '';
        };
      homeManagerModules = {
        default =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            options.psyclyx-emacs.enable = lib.mkEnableOption "Emacs config";
            config = lib.mkIf config.psyclyx-emacs.enable {
              programs.emacs = {
                enable = true;
                package = packages."${pkgs.system}".emacs;
                extraPackages = import ./emacsPackages.nix;
              };
              home.file = {
                ".config/emacs/init.el".source = ./config/init.el;
                ".config/emacs/early-init.el".source = ./config/early-init.el;
              };
            };
          };
      };
    };
}
