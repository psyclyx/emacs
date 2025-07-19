;;; psyclyx-bindings.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code
(defvar psyclyx-leader-key-states '(normal visual motion))
(defvar psyclyx-leader-alt-key-states '(emacs insert))

(defvar psyclyx-default-minibuffer-maps
  '(minibuffer-local-map
    minibuffer-local-ns-map
    minibuffer-local-completion-map
    minibuffer-local-must-match-map
    minibuffer-local-isearch-map
    read-expression-map))


(general-create-definer psyclyx-leader-def
   :keymaps 'override
   :states psyclyx-leader-key-states
   :prefix psyclyx-leader-key
   :non-normal-prefix psyclyx-leader-alt-key)

(general-create-definer psyclyx-localleader-def
  :keymaps 'override
  :states psyclyx-leader-key-states
  :prefix psyclyx-localleader-key
  :non-normal-prefix psyclyx-localleader-key)

(general-override-mode +1)

(general-define-key
 :keymaps 'corfu-mode-map
 :states '(insert)
 "C-@" #'completion-at-point
 "C-SPC" #'completion-at-point
 "C-n" #'psyclyx-corfu--dabbrev-or-next
 "C-p" #'psyclyx-corfu--dabbrev-or-last)
(general-define-key
 :keymaps 'corfu-mode-map
 :states '(normal)
 "C-SPC" (lambda () (interactive)
           (call-interactively #'evil-insert-state)
           (call-interactively #'completion-at-point)))
(general-define-key
 :keymaps 'corfu-mode-map
 :states '(visual)
 "C-SPC" (lambda () (interactive)
           (call-interactively #'evil-change-state)
           (call-interactively #'completion-at-point)))
(general-define-key
 :keymaps 'corfu-map
 :states '(insert)
 "C-SPC" #'psyclyx-corfu--smart-sep-toggle-escape
 "C-S-s" #'psyclyx-corfu--move-to-minibuffer
 "DEL" #'corfu-reset)
(general-define-key
 :keymaps 'corfu-map
 "TAB" #'corfu-next
 "C-j" 'corfu-next
 "S-TAB" #'corfu-previous
 [backtab] #'corfu-previous
 "C-k" 'corfu-previous
 "C-u" (lambda () (interactive)
         (let (curfu-cycle)
           (funcall-interactively #'corfu-next (- corfu-count))))
 "C-d" (lambda () (interactive)
         (let (curfu-cycle)
           (funcall-interactively #'corfu-next corfu-count))))

(general-define-key
 :keymaps 'corfu-popupinfo-map
 "C-h" 'corfu-popupinfo-toggle
 "C-S-k" #'corfu-popupinfo-scroll-down
 "C-S-j" #'corfu-popupinfo-scroll-up
 "C-<up>" #'corfu-popupinfo-scroll-down
 "C-<down>" #'corfu-popupinfo-scroll-up
 "C-S-p" #'corfu-popupinfo-scroll-down
 "C-S-n" #'corfu-popupinfo-scroll-up
 "C-S-u" (lambda () (interactive)
           (corfu-popupinfo-scroll-down nil corfu-popupinfo-min-height))
 "C-S-d" (lambda () (interactive)
           (corfu-popupinfo-scroll-up nil corfu-popupinfo-min-height)))

(general-define-key
 :keymaps '(evil-ex-completion-map evil-ex-search-keymap)
 "C-a" #'evil-beginning-of-line
 "C-b" #'evil-backward-char
 "C-f" #'evil-forward-char)

(general-define-key
 :keymaps '(evil-ex-completion-map evil-ex-search-keymap)
 :states '(insert)
 "C-j" #'next-complete-history-element
 "C-k" #'previous-complete-history-element)


(general-define-key
 :states 'motion
 "]d" #'git-gutter:next-hunk
 "[d" #'git-gutter:previous-hunk)


(general-define-key
 :keymaps psyclyx-default-minibuffer-maps
 [escape] #'abort-recursive-edit
 "C-a"    #'move-beginning-of-line
 "C-r"    #'evil-paste-from-register
 "C-u"    #'evil-delete-back-to-indentation
 "C-v"    #'yank
 "C-w"    #'psyclyx-delete-backward-word
 "C-z"    (lambda () (interactive)
            (ignore-errors (call-interactively #'undo))))

(general-define-key
 :keymaps psyclyx-default-minibuffer-maps
 "C-j"    #'next-line
 "C-k"    #'previous-line
 "C-S-j"  #'scroll-up-command
 "C-S-k"  #'scroll-down-command)

(general-define-key
 :keymaps 'read-expression-map
 "C-j" #'next-line-or-history-element
 "C-k" #'previous-line-or-history-element)


(general-define-key
 :states '(normal visual)
 "gt" #'psyclyx-tab-next-or-goto
 "gT" #'psyclyx-tab-previous-or-goto
 "gd" #'xref-find-definitions
 "gD" #'xref-find-references)


(general-define-key
 :prefix-map 'psyclyx-buffer-prefix-map
 "b" (cons "Switch buffer" #'switch-to-buffer)
 "d" (cons "Kill current buffer" #'kill-current-buffer)
 "i" (cons "ibuffer" #'ibuffer)
 "l" (cons "Switch to last buffer" #'evil-switch-to-windows-last-buffer)
 "m" (cons "Set bookmark" #'bookmark-set)
 "M" (cons "Delete bookmark" #'bookmark-delete)
 "r" (cons "Revert buffer" #'revert-buffer))

(general-define-key
 :prefix-map 'psyclyx-code-prefix-map
 "a" (cons "LSP Execute code action" #'eglot-code-actions)
 "r" (cons "LSP Rename" #'eglot-rename)
 "j" (cons "LSP Find declaration" #'eglot-find-declaration)
 "c" (cons "Compile" #'compile)
 "C" (cons "Compile" #'recompile)
 "d" (cons "Jump to definition" #'xref-find-definitions)
 "D" (cons "Jump to references" #'xref-find-references))


(general-define-key
 :prefix-map 'psyclyx-file-prefix-map
 "f" (cons "Find file" #'find-file)
 "d" (cons "Find directory" #'dired)
 "l" (cons "Locate files" #'locate)
 "r" (cons "Recent files" #'recentf-open-files))


(general-define-key
 :keymaps 'help-map
 "C-h" "")


(general-define-key
 :prefix-map 'psyclyx-search-prefix-map
 "s" (cons "Search buffer" #'consult-line)
 "L" (cons "Jump to link" #'ffap-menu)
 "p" (cons "Search project" #'consult-ripgrep)
 "i" (cons "imenu" #'imenu))


(general-define-key
 :prefix-map 'psyclyx-git-find-prefix-map
 "f" (cons "Find file" #'magit-find-file)
 "g" (cons "Find gitconfig file" #'magit-find-git-config-file)
 "c" (cons "Find commit" #'magit-show-commit))

(general-define-key
 :prefix-map 'psyclyx-git-create-prefix-map
 "r" (cons "Initialize repo" #'magit-init)
 "R" (cons "Clone repo" #'magit-clone)
 "c" (cons "Commit" #'magit-commit-create)
 "f" (cons "Fixup" #'magit-commit-fixup)
 "b" (cons "Branch" #'magit-branch-and-checkout))

(general-define-key
 :prefix-map 'psyclyx-git-prefix-map
 "c" (cons "create" psyclyx-git-create-prefix-map)
 "f" (cons "find" psyclyx-git-find-prefix-map)

 "R" (cons "Revert file" #'vc-revert)
 "r" (cons "Revert hunk at point" #'git-gutter:revert-hunk)
 "s" (cons "Stage hunk at point" #'git-gutter:stage-hunk)
 "]" (cons "Jump to next hunk" #'git-gutter:next-hunk)
 "[" (cons "Jump to previous hunk" #'git-gutter:previous-hunk)
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


(psyclyx-leader-def
  "b" (cons "buffer" psyclyx-buffer-prefix-map)
  "c" (cons "code" psyclyx-code-prefix-map)
 "f" (cons "file" psyclyx-file-prefix-map)
 "g" (cons "git" psyclyx-git-prefix-map)
 "h" (cons "help" help-map)
 "s" (cons "search" psyclyx-search-prefix-map)
 "w" (cons "window" #'evil-window-map))


(psyclyx-leader-def
 "'" (cons "Repeat last search" #'vertico-repeat)
 "u" (cons "Universal argument" #'universal-argument)
 ";" (cons "Eval expression" #'pp-eval-expression)
 ":" (cons "M-x" #'execute-extended-command)
 "," (cons "Switch buffer" #'switch-to-buffer)
 "." (cons "Find file" #'find-file)
 "RET" (cons "Jump to bookmark" #'bookmark-jump))


(provide 'psyclyx-bindings)
