;;; -*- lexical-binding: t; -*-

(use-package eglot
  :init
  (setq eglot-sync-connect 1
        eglot-autoshutdown t)
  :config
  (cl-callf plist-put eglot-events-buffer-config :size 0))


(use-package consult-eglot
  :commands consult-eglot-symbols)

(general-def
 :keymap 'eglot-mode-map
 [remap xref-find-apropos] #'consult-eglot-symbols)

(provide 'psyclyx-lsp)
