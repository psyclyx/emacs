;;; psyclyx-ui.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(tooltip-mode -1)

(setq inhibit-splash-screen t)

(defun psyclyx-flash-modeline ()
  (invert-face 'mode-line)
  (run-with-timer 0.1 nil 'invert-face 'mode-line))

(setq visible-bell nil
      ring-bell-function 'psyclyx-flash-modeline)

(setq hscroll-margin 2
      hscroll-step 1
      scroll-conservatively 10
      scroll-margin 0
      scroll-preserve-screen-position t
      auto-window-vscroll nil
      mouse-wheel-scroll-amount '(2 ((shift) . hscroll))
      mouse-wheel-scroll-amount-horizontal 2)

(blink-cursor-mode -1)
(setq blink-matching-paren nil
      x-stretch-cursor nil)

(setq indicate-buffer-boundaries nil
      indicate-empty-lines nil)

(setq frame-title-format '("%b – Emacs")
      icon-title-format frame-title-format)

(setq frame-resize-pixelwise t
      window-resize-pixelwise t)

(setq window-divider-default-places t
      window-divider-default-bottom-width 1
      window-divider-default-right-width 1)

(when (display-graphic-p)
  (window-divider-mode 0))

(setq split-width-threshold 160
      split-height-threshold nil)

(when (bound-and-true-p tooltip-mode)
  (tooltip-mode -1))

(provide 'psyclyx-ui)
