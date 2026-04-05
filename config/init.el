;;; init.el -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; Add lisp subdirectories to load-path
(let ((lisp-dir (expand-file-name "lisp" user-emacs-directory)))
  (dolist (subdir '("core" "editor" "completion" "tools" "lang" "keybinds"))
    (add-to-list 'load-path (expand-file-name subdir lisp-dir))))

;; Core
(require 'psyc-lib)

;; Editor
(require 'psyc-editor)
(if psyc-vanilla-mode
    (progn
      (require 'psyc-modal)
      (add-hook 'emacs-startup-hook #'psyc-modal-global-mode))
  (require 'psyc-evil))
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
(require 'psyc-org)
(require 'psyc-ai)
(require 'psyc-snippets)
(require 'psyc-debug)

;; Languages
(require 'psyc-nix)
(require 'psyc-clojure)
(require 'psyc-rust)
(require 'psyc-janet)
(require 'psyc-zig)
(require 'psyc-python)
(require 'psyc-java)
(require 'psyc-shell)
(require 'psyc-web)
(require 'psyc-data)

;; Keybinds (must come after modules that define prefix maps)
(unless psyc-vanilla-mode
  (require 'psyc-keybinds))
