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

(setopt display-buffer-alist
        '(("\\*eldoc\\*"
           (display-buffer-in-side-window)
           (side . right)
           (slot . 0)
           (width . 0.3))
          ("\\*[Hh]elp\\*"
           (display-buffer-in-side-window)
           (side . right)
           (slot . -1)
           (width . 0.3))))

(setq eldoc-echo-area-use-multiline-p t
      eldoc-documentation-strategy 'eldoc-documentation-compose-eagerly
      eldoc-echo-area-prefer-doc-buffer t)

;;; Provide
(provide 'athame-lsp)
;;; athame-lsp.el ends here
