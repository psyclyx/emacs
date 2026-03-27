;;; psyc-snippets.el --- Snippet/template expansion -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package tempel
  :defer t
  :init
  (gsetq tempel-trigger-prefix "<")
  (defun psyc-tempel--capf ()
    (add-hook 'completion-at-point-functions #'tempel-expand -90 t))
  (psyc-add-hooks '(prog-mode-hook text-mode-hook conf-mode-hook)
                  #'psyc-tempel--capf)

  :general
  (:states '(insert normal)
   "M-+" #'tempel-complete
   "M-*" #'tempel-insert)
  (:keymaps 'tempel-map
   "M-n" #'tempel-next
   "M-p" #'tempel-previous
   "M-RET" #'tempel-done))

(use-package tempel-collection
  :after tempel)

(provide 'psyc-snippets)
;;; psyc-snippets.el ends here
