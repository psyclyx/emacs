;;; athame-editor.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

;;;; Scrolling
(setq hscroll-margin 2
      hscroll-step 1
      scroll-conservatively 10
      scroll-margin 0
      scroll-preserve-screen-position t
      auto-window-vscroll nil
      mouse-wheel-scroll-amount '(2 ((shift) . hscroll))
      mouse-wheel-scroll-amount-horizontal 2)

;;;; Text
;;;;; Indentation
(setq-default indent-tabs-mode nil
              tab-width 4
              tab-always-indent nil
              tabify-regexp "^\t* [ \t]+")

;;;;; Wrapping/truncation
(setq-default truncate-lines t
              truncate-partial-width-windows nil
              word-wrap t
              fill-column 80)

(add-hook 'text-mode-hook #'visual-line-mode)

;;;;; Sentences
(setq sentence-end-double-space nil)

;;;;; EOF newlines
(setq require-final-newline t)

;;;;; Whitespace
(setq whitespace-line-column nil
      whitespace-style
      '(face indentation tabs tab-mark spaces space-mark newline newline-mark
             trailing lines-tail))

(use-package ws-butler
  :hook ((prog-mode text-mode) . ws-butler-mode))

;;;;; Kill ring
(setq kill-do-not-save-duplicates t)


;;;; UI
;;;;; Line numbers
(setq-default display-line-numbers-width 3
              display-line-numbers-widen t
              display-line-numbers-type 'relative)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)
(add-hook 'conf-mode-hook #'display-line-numbers-mode)

;;;;; Minibuffer
(setq enable-recursive-minibuffers t)
(setq echo-keystrokes 0.02)

(setq minibuffer-prompt-properties '(read-only t intangible t cursor-intangible t face minibuffer-prompt))
(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

;;;; Highlight parens
(use-package paren
  :ensure nil
  :hook ((text-mode prog-mode) . show-paren-mode)
  :custom
  (show-paren-delay 0.1)
  (show-paren-highlight-openparen t)
  (show-paren-when-point-inside-paren t)
  (show-paren-when-point-in-periphery t))

;;; Prompts
(setq use-short-answers t)
(define-key y-or-n-p-map " " nil)

;;; Provide
(provide 'athame-editor)
;;; athame-editor.el ends here
