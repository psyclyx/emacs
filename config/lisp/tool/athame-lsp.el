;;; athame-lsp.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

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
  (:keymap
   'eglot-mode-map
   [remap xref-find-apropos] #'consult-eglot-symbols))


(gsetq display-buffer-alist
       '(("\\*eldoc\\*"
          (display-buffer-reuse-mode-window
           display-buffer-in-side-window)
          (side . right)
          (slot . 0)
          (width . 0.3))
         ("\\*[Hh]elp\\*"
          (display-buffer-reuse-mode-window
           display-buffer-in-side-window)
          (side . right)
          (slot . -1)
          (width . 0.3))))

(use-package eldoc
  :defer t
  :init
  (gsetq eldoc-echo-area-use-multiline-p t
	 eldoc-echo-area-prefer-doc-buffer t
	 eldoc-documentation-strategy 'eldoc-documentation-compose-eagerly))

;;; Provide
(provide 'athame-lsp)
;;; athame-lsp.el ends here
