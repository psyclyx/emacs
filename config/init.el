;;; init.el -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; Add lisp subdirectories to load-path
(let ((lisp-dir (expand-file-name "lisp" user-emacs-directory)))
  (dolist (subdir '("core" "editor" "completion" "tools" "ui" "lang" "keybinds"))
    (add-to-list 'load-path (expand-file-name subdir lisp-dir))))

;; Core
(require 'psyc-lib)

;; Editor
(require 'psyc-editor)
(require 'psyc-evil)
(require 'psyc-parens)

;; Completion
(require 'psyc-completion)

;; Tools
(require 'psyc-dired)
(require 'psyc-format)
(require 'psyc-lsp)
(require 'psyc-project)
(require 'psyc-vcs)
(require 'psyc-check)
(require 'psyc-misc)

;; UI
(require 'psyc-windows)

;; Languages
(require 'psyc-nix)
(require 'psyc-clojure)

;; Keybinds (must come after modules that define prefix maps)
(require 'psyc-keybinds)
