;;; psyclyx-ui.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(tooltip-mode -1)
(setq initial-buffer-choice t)

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
  (add-hook 'after-init #'window-divider-mode))

(setq split-width-threshold 160
      split-height-threshold nil)

(when (bound-and-true-p tooltip-mode)
  (tooltip-mode -1))

(use-package mood-line
  :ensure t
  :custom
  (mood-line-glyph-alist mood-line-glyphs-unicode)
  (mood-line-format mood-line-format-default-extended)
  :config
  (mood-line-mode))


(use-package centaur-tabs
  :defer t
  :init
  (setq centaur-tabs-set-icons t
        centaur-tabs-gray-out-icons 'buffer
        centaur-tabs-set-bar 'left
        centaur-tabs-set-modified-marker t
        centaur-tabs-close-button "✕"
        centaur-tabs-modified-marker "•"
        centaur-tabs-icon-type 'nerd-icons
        centaur-tabs-cycle-scope 'tabs)
  (if (daemonp)
      (add-hook 'server-after-make-frame-hook #'centaur-tabs-mode)
    (add-hook 'after-init-hook #'centaur-tabs-mode))

  :config
  (defun psyclyx-tabs-buffer-list ()
    (seq-filter (lambda (b)
                  (when (buffer-live-p b)
                    (or (eq (current-buffer) b)
                        (not (psyclyx-temp-buffer-p b)))))
                (if (bound-and-true-p persp-mode)
                    (persp-buffer-list)
                  (buffer-list))))
  (setq centaur-tabs-buffer-list-function #'psyclyx-tabs-buffer-list)

  (require 'evil)
  (evil-define-command psyclyx-tab-next-or-goto (index)
    "Switch to the next tab, or to INDEXth tab if a count is given."
    (interactive "<c>")
    (if index
        (centaur-tabs-select-visible-nth-tab index)
      (centaur-tabs-forward)))

  (evil-define-command psyclyx-tab-previous-or-goto (index)
    "Switch to the previous tab, or to INDEXth tab if a count is given."
    (interactive "<c>")
    (if index
        (centaur-tabs-select-visible-nth-tab index)
      (centaur-tabs-backward))))

(provide 'psyclyx-ui)
