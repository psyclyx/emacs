;;; psyc-keybinds.el --- Global keybindings -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)
(require 'psyc-project)
(require 'psyc-misc)
(require 'psyc-org)
(require 'psyc-ai)

;;;; Motion keys

(general-define-key
 :states '(normal visual)
 "gt" #'tab-next
 "gT" #'tab-previous
 "gd" #'xref-find-definitions
 "gD" #'xref-find-references)

;;;; Prefix maps

(general-define-key
 :prefix-map 'psyc-buffer-prefix-map
 "b" (cons "Switch buffer" #'switch-to-buffer)
 "d" (cons "Kill current buffer" #'kill-current-buffer)
 "i" (cons "ibuffer" #'ibuffer)
 "l" (cons "Switch to last buffer" #'evil-switch-to-windows-last-buffer)
 "m" (cons "Set bookmark" #'bookmark-set)
 "M" (cons "Delete bookmark" #'bookmark-delete)
 "r" (cons "Revert buffer" #'revert-buffer))

(general-define-key
 :prefix-map 'psyc-code-prefix-map
 "l" (cons "Start LSP" #'eglot)
 "L" (cons "Reconnect LSP" #'eglot-reconnect)
 "x" (cons "Shutdown LSP" #'eglot-shutdown)
 "X" (cons "Shutdown LSP (all)" #'eglot-shutdown-all)
 "a" (cons "LSP Execute code action" #'eglot-code-actions)
 "r" (cons "LSP Rename" #'eglot-rename)
 "j" (cons "LSP Find declaration" #'eglot-find-declaration)
 "c" (cons "Compile" #'psyc-compile)
 "C" (cons "Compile" #'recompile)
 "d" (cons "Jump to definition" #'xref-find-definitions)
 "D" (cons "Jump to references" #'xref-find-references))

(general-define-key
 :prefix-map 'psyc-file-prefix-map
 "f" (cons "Find file" #'find-file)
 "s" (cons "Dirvish sidebar" #'dirvish-side)
 "d" (cons "Dirvish" #'dirvish-dwim)
 "e" (cons "Find directory" #'dirvish)
 "h" (cons "Find heading" #'consult-outline)
 "l" (cons "Locate files" #'locate)
 "r" (cons "Recent files" #'recentf-open-files))

(general-define-key
 :keymaps 'help-map
 "C-h" "")

(general-define-key
 :prefix-map 'psyc-search-prefix-map
 "l" (cons "Search buffer lines" #'consult-line)
 "S" (cons "Search all buffer lines" #'consult-line)
 "L" (cons "Jump to link" #'ffap-menu)
 "p" (cons "Search project" #'consult-ripgrep)
 "i" (cons "imenu" #'imenu)
 "j" (cons "Jump list" #'evil-show-jumps)
 "I" (cons "imenu (project buffers)" #'consult-imenu-multi))

(general-define-key
 :prefix-map 'psyc-git-find-prefix-map
 "f" (cons "Find file" #'magit-find-file)
 "g" (cons "Find gitconfig file" #'magit-find-git-config-file)
 "c" (cons "Find commit" #'magit-show-commit))

(general-define-key
 :prefix-map 'psyc-git-create-prefix-map
 "r" (cons "Initialize repo" #'magit-init)
 "R" (cons "Clone repo" #'magit-clone)
 "c" (cons "Commit" #'magit-commit-create)
 "f" (cons "Fixup" #'magit-commit-fixup)
 "b" (cons "Branch" #'magit-branch-and-checkout))

(general-define-key
 :prefix-map 'psyc-git-prefix-map
 "c" (cons "create" psyc-git-create-prefix-map)
 "f" (cons "find" psyc-git-find-prefix-map)
 "R" (cons "Revert file" #'vc-revert)
 "/" (cons "Magit dispatch" #'magit-dispatch)
 "." (cons "Magit file dispatch" #'magit-dispatch)
 "b" (cons "Magit switch branch" #'magit-branch-checkout)
 "g" (cons "Magit status" #'magit-status)
 "G" (cons "Magit status here" #'magit-status)
 "D" (cons "Magit file delete" #'magit-file-delete)
 "B" (cons "Magit blame" #'magit-blame-addition)
 "C" (cons "Magit clone" #'magit-clone)
 "F" (cons "Magit fetch" #'magit-fetch)
 "L" (cons "Magit buffer log" #'magit-log-buffer-file)
 "S" (cons "Git stage file"  #'magit-stage-file)
 "U" (cons "Git unstage file" #'magit-unstage-file))

;;;; Tool map

(general-define-key
 :prefix-map 'psyc-tool-map
 "p" (cons "profiler" (make-keymap))
 "p p" (cons "Profiler start" #'profiler-start)
 "p s" (cons "Profiler stop" #'profiler-stop)
 "p r" (cons "Profiler report" #'profile-report)
 "f" (cons "Flycheck" #'flycheck-mode))

;;;; Leader keys

(general-def
  :keymaps '(emacs insert normal)
  :prefix-map 'psyc-leader-map
  :global-prefix "C-c f"
  :non-normal-prefix "M-SPC"
  :prefix "SPC")

(general-create-definer psyc-leader-def
  :prefix-map 'psyc-leader-map)

(defvar psyc-localleader-map (make-sparse-keymap))

(general-create-definer psyc-localleader-def
  :prefix-map 'psyc-localleader-map)

(general-def
  :prefix-map 'psyc-leader-map
  "b" (cons "buffer" psyc-buffer-prefix-map)
  "c" (cons "code" psyc-code-prefix-map)
  "f" (cons "file" psyc-file-prefix-map)
  "g" (cons "git" psyc-git-prefix-map)
  "h" (cons "help" help-map)
  "p" (cons "project" psyc-project-prefix-map)
  "s" (cons "search" psyc-search-prefix-map)
  "m" (cons "local" psyc-localleader-map)
  "w" (cons "window" #'evil-window-map)
  "a" (cons "ai" psyc-ai-prefix-map)
  "n" (cons "notes" psyc-notes-prefix-map)
  "T" (cons "tool" psyc-tool-map)

  "/" (cons "Search project" #'consult-ripgrep)
  "'" (cons "Repeat last search" #'vertico-repeat)
  "u" (cons "Universal argument" #'universal-argument)
  ";" (cons "Eval expression" #'pp-eval-expression)
  ":" (cons "M-x" #'execute-extended-command)
  "," (cons "Switch buffer" #'switch-to-buffer)
  "." (cons "Find file" #'find-file)
  "RET" (cons "Jump to bookmark" #'bookmark-jump))

(provide 'psyc-keybinds)
;;; psyc-keybinds.el ends here
