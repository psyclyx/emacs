;;; psyc-lsp.el --- LSP and documentation -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

;;;; Eglot

(use-package eglot
  :defer t
  :init
  (gsetq eglot-sync-connect 1
	 eglot-autoshutdown t
	 eglot-events-buffer-config '(:size 0 :format full)))

(use-package consult-eglot
  :defer t
  :after eglot
  :general
  (:keymaps
   'eglot-mode-map
   [remap xref-find-apropos] #'consult-eglot-symbols))

;;;; Eldoc

(use-package eldoc
  :defer t
  :init
  (gsetq eldoc-echo-area-use-multiline-p t
	 eldoc-echo-area-prefer-doc-buffer t
	 eldoc-documentation-strategy 'eldoc-documentation-compose-eagerly))

(provide 'psyc-lsp)
;;; psyc-lsp.el ends here
