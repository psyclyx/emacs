;;; athame-ui.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(gsetq frame-title-format '("%b – Emacs")
       icon-title-format frame-title-format)

(gsetq split-width-threshold 160
       split-height-threshold nil)

(gsetq indicate-buffer-boundaries nil
       indicate-empty-lines nil)

(gsetq window-divider-default-right-width 1)

(when (display-graphic-p)
  (window-divider-mode 0))

(gsetq frame-resize-pixelwise t
       window-resize-pixelwise t)

(when (bound-and-true-p tooltip-mode)
  (tooltip-mode -1))

(defun athame-flash-modeline ()
  "Briefly inverts the `mode-line' face."
  (invert-face 'mode-line)
  (run-with-timer 0.1 nil 'invert-face 'mode-line))

(gsetq ring-bell-function #'athame-flash-modeline)

(general-after-init
  (blink-cursor-mode -1))

(gsetq blink-matching-paren nil
       x-stretch-cursor nil)

(gsetq x-underline-at-descent-line t)
(use-package display-line-numbers
  :hook (prog-mode-hook text-mode-hook conf-mode-hook)
  :init
  (gsetq display-line-numbers-width 3
         display-line-numbers-widen t
         display-line-numbers-type 'relative))

(provide 'athame-ui)
;;; athame-ui.el ends here
