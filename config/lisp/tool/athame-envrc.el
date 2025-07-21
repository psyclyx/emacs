;;; athame-envrc.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(use-package envrc
  :config
  (envrc-global-mode)
  (general-define-key
   :keymaps 'athame-tool-map
   "e" (cons "envrc" envrc-command-map)))

;;; Provide
(provide 'athame-envrc)
;;; athame-envrc.el ends here
