;;; psyc-evil.el --- Evil mode configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

;;;; Evil-mode

(use-package evil
  :ghook 'emacs-startup-hook
  :init
  (gsetq
   evil-want-keybinding nil
   evil-want-C-u-scroll t
   evil-want-C-u-delete t
   evil-want-Y-yank-to-eol t
   evil-move-beyond-eol t
   evil-ex-search-vim-style-regexp t
   evil-want-abbrev-expand-on-insert-exit nil
   evil-ex-visual-char-range t
   evil-symbol-word-search t
   evil-undo-system 'undo-redo
   evil-insert-state-cursor 'bar
   evil-visual-state-cursor 'hollow)

  :general-config
  (:keymaps
   '(evil-ex-completion-map evil-ex-search-keymap)
   "C-a" #'evil-beginning-of-line
   "C-b" #'evil-backward-char
   "C-f" #'evil-forward-char)

  (:keymaps
   '(evil-ex-completion-map evil-ex-search-keymap)
   :states 'insert
   "C-j" #'next-complete-history-element
   "C-k" #'previous-complete-history-element))

;;;; Evil-collection

(use-package evil-collection
  :defer t
  :init
  (gsetq evil-collection-outline-bind-tab-p t)
  (general-after-init
    (evil-collection-init)))

;;;; Evil-snipe

(use-package evil-snipe
  :defer 0.5
  :init
  (gsetq
   evil-snipe-scope 'visible
   evil-snipe-repeat-scope 'whole-visible
   evil-snipe-smart-case t)
  :config
  (evil-snipe-mode 1)
  (evil-snipe-override-mode 1))

;;;; Evil-surround

(use-package evil-surround
  :ghook
  ('evil-mode-hook #'global-evil-surround-mode))

(provide 'psyc-evil)
;;; psyc-evil.el ends here
