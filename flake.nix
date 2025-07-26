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
      files.config = ./config;
      packages."x86_64-linux" =
        let
          pkgs = pkgsFor "x86_64-linux";
        in
        rec {
          emacs = pkgs.callPackage ./package.nix { emacs = pkgs.emacs-unstable-pgtk; };
          emacsWrapped = pkgs.writeShellScriptBin "emacs-wrapped" ''
            ${emacs}/bin/emacs --init-directory=${files.config}
          '';
        };
    };
}
