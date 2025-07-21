;;; athame-lsp.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

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


;;; Provide
(provide 'athame-lsp)
;;; athame-lsp.el ends here
