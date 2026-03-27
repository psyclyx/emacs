;;; psyc-parens.el --- Structural editing -*- lexical-binding: t; -*-
;;; Code:

(require 'psyc-lib)

;;;; Electric pair (auto-pairing for non-lisp modes)

(use-package elec-pair
  :ensure nil
  :hook (emacs-startup . electric-pair-mode))

;;;; Expand-region (incremental selection expansion)

(use-package expreg
  :general
  (:states 'visual
   "v" #'expreg-expand
   "V" #'expreg-contract))

;;;; Combobulate (tree-sitter structural editing)

(use-package combobulate
  :hook ((python-ts-mode . combobulate-mode)
         (js-ts-mode . combobulate-mode)
         (typescript-ts-mode . combobulate-mode)
         (tsx-ts-mode . combobulate-mode)
         (css-ts-mode . combobulate-mode)
         (bash-ts-mode . combobulate-mode)))

;;;; Smartparens + evil-cleverparens (structural editing for lisps)

(defvar psyc-lisp-mode-hooks
  '(emacs-lisp-mode-hook
    clojure-mode-hook
    clojurescript-mode-hook
    clojurec-mode-hook
    cider-repl-mode-hook
    janet-mode-hook
    lisp-mode-hook
    scheme-mode-hook
    ielm-mode-hook
    lisp-interaction-mode-hook)
  "Mode hooks where structural editing should be enabled.")

(use-package smartparens
  :commands (smartparens-strict-mode)
  :init
  (psyc-add-hooks psyc-lisp-mode-hooks #'smartparens-strict-mode)
  :config
  (require 'smartparens-config)
  (general-def
    :keymaps 'smartparens-strict-mode-map
    :states 'insert
    [remap delete-backward-char] #'sp-backward-delete-char
    [remap backward-delete-char-untabify] #'sp-backward-delete-char
    [remap delete-forward-char] #'sp-delete-char)
  ;; Avoid double-pairing with electric-pair-mode
  (add-hook 'smartparens-enabled-hook
            (lambda () (electric-pair-local-mode -1))))

(use-package evil-cleverparens
  :commands (evil-cleverparens-mode)
  :init
  (psyc-add-hooks psyc-lisp-mode-hooks #'evil-cleverparens-mode)
  (gsetq evil-cleverparens-swap-move-by-word-and-symbol t))

(provide 'psyc-parens)
;;; psyc-parens.el ends here
