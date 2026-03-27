;;; psyc-clojure.el --- Clojure language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package clojure-mode
  :mode "\\.clj\\'"
  :config
  (with-eval-after-load 'apheleia
    (setf (alist-get 'clojure-mode apheleia-mode-alist) 'cljstyle)
    (setf (alist-get 'cljstyle apheleia-formatters) '("cljstyle" "pipe"))))

(use-package cider
  :after clojure-mode
  :custom
  (cider-repl-display-help-banner nil)
  (cider-show-error-buffer t)
  (cider-auto-select-error-buffer nil)
  (cider-repl-wrap-history t)
  (cider-repl-history-size 1000)

  :config
  (general-def
    :keymaps 'clojure-mode-map
    [remap eval-last-sexp] #'cider-eval-last-sexp
    [remap eval-buffer] #'cider-eval-buffer
    [remap eval-region] #'cider-eval-region)

  (general-def
    :keymaps 'clojure-mode-map
    :states 'normal
    :prefix "SPC m"

    "" '(:ignore t :which-key "clojure")

    :infix "e"
    "" '(:ignore t :which-key "eval")
    "D" #'cider-insert-defun-in-repl
    "E" #'cider-insert-last-sexp-in-repl
    "R" #'cider-insert-region-in-repl
    "b" #'cider-eval-buffer
    "d" #'cider-eval-defun-at-point
    "e" #'cider-eval-last-sexp
    "r" #'cider-eval-region
    "u" #'cider-undef
    "i" #'cider-debug-defun-at-point)

  (general-def
    :keymaps 'clojure-mode-map
    :states 'normal
    :prefix "SPC m"

    :infix "g"
    "" '(:ignore t :which-key "goto")
    "b" #'cider-pop-back
    "g" #'cider-find-var
    "n" #'cider-find-ns))

(provide 'psyc-clojure)
;;; psyc-clojure.el ends here
