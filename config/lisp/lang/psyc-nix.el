;;; psyc-nix.el --- Nix language support -*- lexical-binding: t; -*-
;;; Code:

(require 'psyc-lib)

(use-package nix-mode
  :defer t
  :commands (nix-format-buffer nix-repl nix-shell nix-build nix-shell-unpack))

(use-package nix-ts-mode
  :mode "\\.nix\\'"
  :init
  (add-to-list 'auto-mode-alist
               (cons "/flake\\.lock\\'"
                     'js-json-mode))
  (general-after 'tramp
    (add-to-list 'tramp-remote-path "/run/current-system/sw/bin"))

  :general-config
  (:keymaps 'nix-ts-mode-map
   :states 'normal
   :prefix "SPC m"
   "f" #'nix-format-buffer
   "r" #'nix-repl
   "s" #'nix-shell
   "b" #'nix-build
   "u" #'nix-shell-unpack))

(provide 'psyc-nix)
;;; psyc-nix.el ends here
