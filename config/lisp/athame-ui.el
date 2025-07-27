;;; athame-ui.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(setq frame-title-format '("%b – Emacs")
      icon-title-format frame-title-format)

(setopt split-width-threshold 160
        split-height-threshold nil)

(setopt indicate-buffer-boundaries nil
        indicate-empty-lines nil)

(setopt window-divider-default-right-width 1)

(when (display-graphic-p)
  (window-divider-mode 0))

(setopt frame-resize-pixelwise t
        window-resize-pixelwise t)

(when (bound-and-true-p tooltip-mode)
  (tooltip-mode -1))

(defun athame-flash-modeline ()
  "Briefly inverts the `mode-line' face."
  (invert-face 'mode-line)
  (run-with-timer 0.1 nil 'invert-face 'mode-line))

(setopt ring-bell-function #'athame-flash-modeline)

(blink-cursor-mode -1)

(setopt blink-matching-paren nil
        x-stretch-cursor nil)

(setopt x-underline-at-descent-line t)

(provide 'athame-ui)
;;; athame-ui.el ends here
