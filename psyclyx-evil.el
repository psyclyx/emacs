;;; psyclyx-evil.el -*- lexical-binding: t -*-
(defvar evil-want-keybinding nil)
(defvar evil-want-C-g-bindings t)
(defvar evil-want-C-i-jump t)
(defvar evil-want-C-u-scroll t)  ; moved the universal arg to <leader> u
(defvar evil-want-C-u-delete t)
(defvar evil-want-C-w-delete t)
(defvar evil-want-Y-yank-to-eol t)
(defvar evil-want-abbrev-expand-on-insert-exit nil)
(defvar evil-respect-visual-line-mode nil)
(use-package evil
  :preface
  (setq evil-ex-search-vim-style-regexp t
        evil-ex-visual-char-range t
        evil-symbol-word-search t
        evil-normal-state-cursor 'box
        evil-emacs-state-cursor  'box
        evil-insert-state-cursor 'bar
        evil-visual-state-cursor 'hollow
        evil-ex-interactive-search-highlight 'selected-window
        evil-kbd-macro-suppress-motion-error t)

  :config
  (evil-mode 1)
  (evil-select-search-module 'evil-search-module 'evil-search))


(provide 'psyclyx-evil)
