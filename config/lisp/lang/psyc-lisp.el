;;; psyc-lisp.el --- Common Lisp language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package sly
  :mode ("\\.lisp\\'" . lisp-mode)
  :commands (sly sly-connect)
  :custom
  (inferior-lisp-program "sbcl")
  :config
  (general-def
    :keymaps 'lisp-mode-map
    [remap eval-last-sexp] #'sly-eval-last-expression
    [remap eval-buffer]    #'sly-eval-buffer
    [remap eval-region]    #'sly-eval-region
    [remap eval-defun]     #'sly-eval-defun)

  (when psyc-use-evil
    (general-def
      :keymaps 'lisp-mode-map
      :states 'normal
      :prefix "SPC m"

      "" '(:ignore t :which-key "common lisp")

      :infix "e"
      "" '(:ignore t :which-key "eval")
      "b" #'sly-eval-buffer
      "d" #'sly-eval-defun
      "e" #'sly-eval-last-expression
      "r" #'sly-eval-region)

    (general-def
      :keymaps 'lisp-mode-map
      :states 'normal
      :prefix "SPC m"

      :infix "c"
      "" '(:ignore t :which-key "compile")
      "c" #'sly-compile-defun
      "k" #'sly-compile-and-load-file
      "f" #'sly-compile-file
      "l" #'sly-load-file)

    (general-def
      :keymaps 'lisp-mode-map
      :states 'normal
      :prefix "SPC m"

      :infix "g"
      "" '(:ignore t :which-key "goto")
      "g" #'sly-edit-definition
      "b" #'sly-pop-find-definition-stack)

    (general-def
      :keymaps 'lisp-mode-map
      :states 'normal
      :prefix "SPC m"

      :infix "r"
      "" '(:ignore t :which-key "repl")
      "r" #'sly
      "s" #'sly-mrepl
      "q" #'sly-quit-lisp
      "p" #'sly-mrepl-sync)

    (general-def
      :keymaps 'lisp-mode-map
      :states 'normal
      :prefix "SPC m"

      :infix "h"
      "" '(:ignore t :which-key "help")
      "d" #'sly-describe-symbol
      "f" #'sly-describe-function
      "h" #'sly-documentation-lookup)))

;; Modal local-leader
(with-eval-after-load 'psyc-modal
  (psyc-modal-localleader lisp-mode-hook "Common Lisp"
    "eb" #'sly-eval-buffer
    "ed" #'sly-eval-defun
    "ee" #'sly-eval-last-expression
    "er" #'sly-eval-region
    "cc" #'sly-compile-defun
    "ck" #'sly-compile-and-load-file
    "cf" #'sly-compile-file
    "cl" #'sly-load-file
    "gg" #'sly-edit-definition
    "gb" #'sly-pop-find-definition-stack
    "rr" #'sly
    "rs" #'sly-mrepl
    "rq" #'sly-quit-lisp
    "rp" #'sly-mrepl-sync
    "hd" #'sly-describe-symbol
    "hf" #'sly-describe-function
    "hh" #'sly-documentation-lookup))

(provide 'psyc-lisp)
;;; psyc-lisp.el ends here
