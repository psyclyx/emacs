;;; -*- lexical-binding: t; -*-


(use-package envrc
  :config
  (envrc-global-mode)
  (general-define-key
   :keymaps 'psyclyx-tool-map
   "e" (cons "envrc" envrc-command-map)))

(provide 'psyclyx-envrc)
