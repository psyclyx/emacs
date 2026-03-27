;;; psyc-nix.el --- Nix language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package nix-mode
  :defer t
  :mode "\\.nix\\'"
  :init
  (add-to-list 'auto-mode-alist
               (cons "/flake\\.lock\\'"
                     'js-json-mode))
  (general-after 'tramp
    (add-to-list 'tramp-remote-path "/run/current-system/sw/bin"))

  :general-config
  (:keymaps 'nix-mode-map
   :states 'normal
   :prefix "SPC m"
   "f" #'nix-update-fetch
   "p" #'nix-format-buffer
   "r" #'nix-repl
   "s" #'nix-shell
   "b" #'nix-build
   "u" #'nix-unpack))

(provide 'psyc-nix)
;;; psyc-nix.el ends here
