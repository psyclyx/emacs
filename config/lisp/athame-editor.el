;;; athame-editor.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(setopt hscroll-margin 2
        hscroll-step 1
        scroll-conservatively 10
        scroll-margin 0
        scroll-preserve-screen-position t
        mouse-wheel-scroll-amount '(2 ((shift) . hscroll))
        mouse-wheel-scroll-amount-horizontal 2)

(setq auto-window-vscroll nil)

(when (display-graphic-p)
  (pixel-scroll-precision-mode 1))

(setopt indent-tabs-mode nil
        tab-width 4)

(setopt truncate-lines t
        truncate-partial-width-windows nil
        word-wrap t
        fill-column 80)

(add-hook 'text-mode-hook #'visual-line-mode)

(setopt sentence-end-double-space nil
        require-final-newline t)

;; is this just a diff thing?
(setq whitespace-style
      '(face indentation tabs tab-mark spaces space-mark newline newline-mark
             trailing lines-tail))

(use-package ws-butler
  :hook ((prog-mode text-mode) . ws-butler-mode))

(setq kill-do-not-save-duplicates t)

(setopt enable-recursive-minibuffers t)

(minibuffer-depth-indicate-mode 1)

(setq echo-keystrokes 0.5)

(setopt minibuffer-prompt-properties
        '(read-only t
                    intangible t
                    cursor-intangible t face minibuffer-prompt))

(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

(use-package paren
  :ensure nil
  :hook ((text-mode prog-mode) . show-paren-mode)
  :custom
  (show-paren-delay 0.1)
  (show-paren-highlight-openparen t)
  (show-paren-when-point-inside-paren t)
  (show-paren-when-point-in-periphery t)
  (show-paren-context-when-offscreen 'child-frame)
  :config
  (add-to-list 'show-paren--context-child-frame-parameters
               '(border-width . 3)))

(setopt use-short-answers t)
(define-key y-or-n-p-map " " nil)

(provide 'athame-editor)
;;; athame-editor.el ends here
