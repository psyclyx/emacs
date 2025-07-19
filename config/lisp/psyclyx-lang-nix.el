(use-package tramp
  :config
  (add-to-list 'tramp-remote-path "/run/current-system/sw/bin"))


(use-package nix-mode
  :mode "\\.nix\\'"
  :init
  (add-to-list 'auto-mode-alist
               (cons "/flake\\.lock\\'"
                     'js-json-mode)))


(use-package nix-repl
  :commands nix-repl-show)


(psyclyx-localleader-def
 :keymaps 'nix-mode-map
 :prefix psyclyx-localleader-key
 "f" #'nix-update-fetch
 "p" #'nix-format-buffer
 "r" #'nix-repl-show
 "s" #'nix-shell
 "b" #'nix-build
 "u" #'nix-unpack)


(provide 'psyclyx-lang-nix)
