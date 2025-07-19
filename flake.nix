{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
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
    {
      packages."x86_64-linux" =
        let
          pkgs = pkgsFor "x86_64-linux";
        in
        {
          default = {
            emacs = pkgs.callPackage ./package.nix { emacs = pkgs.emacs-unstable-pgtk; };
            config = ./config;
          };
        };
    };
}
