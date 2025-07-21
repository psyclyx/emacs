;;; athame-ui.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;;;; Visual bell
(defun athame-flash-modeline ()
  "Briefly inverts the `mode-line' face."
  (invert-face 'mode-line)
  (run-with-timer 0.1 nil 'invert-face 'mode-line))

(setq ring-bell-function #'athame-flash-modeline)

;;;; Scroll
(setq hscroll-margin 2
      hscroll-step 1
      scroll-conservatively 10
      scroll-margin 0
      scroll-preserve-screen-position t
      auto-window-vscroll nil
      mouse-wheel-scroll-amount '(2 ((shift) . hscroll))
      mouse-wheel-scroll-amount-horizontal 2)

;;;; Cursor
(blink-cursor-mode -1)
(setq blink-matching-paren nil
      x-stretch-cursor nil)

;;;; Buffer
(setq indicate-buffer-boundaries t
      indicate-empty-lines nil)

;;;; Frames
(setq frame-title-format '("%b – Emacs")
      icon-title-format frame-title-format)

;;;; Resize
(setq frame-resize-pixelwise t
      window-resize-pixelwise t)

;;;; Window dividers
(setq window-divider-default-places t
      window-divider-default-bottom-width 0
      window-divider-default-right-width 0)

(when (display-graphic-p)
  (window-divider-mode 0))

;;;; Splits
(setq split-width-threshold 160
      split-height-threshold nil)

;;;; Disable tooltimes
(when (bound-and-true-p tooltip-mode)
  (tooltip-mode -1))


;;;; Provide
(provide 'athame-ui)
;;; athame.el ends here
