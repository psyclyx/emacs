;;; athame-corfu -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(defun athame-corfu-move-to-minibuffer ()
  (interactive)
  (pcase completion-in-region--data
    (`(,beg ,end ,table ,pred ,extras)
     (let ((completion-extra-properties extras)
           completion-cycle-threshold completion-cycling)
       (consult-completion-in-region beg end table pred)))))

(defun athame-corfu-smart-sep-toggle-escape ()
  "Insert `corfu-separator' or toggle escape if it's already there."
  (interactive)
  (cond ((and (char-equal (char-before) corfu-separator)
              (char-equal (char-before (1- (point))) ?\\))
         (save-excursion (delete-char -2)))
        ((char-equal (char-before) corfu-separator)
         (save-excursion (backward-char 1)
                         (insert-char ?\\)))
        (t (call-interactively #'corfu-insert-separator))))

(defun athame-corfu-dabbrev-or-next (&optional arg)
  "Trigger corfu popup and select the first candidate.

Intended to mimic `evil-complete-next', unless the popup is already open."
  (interactive "p")
  (if corfu--candidates
      (corfu-next arg)
    (require 'cape)
    (let ((cape-dabbrev-check-other-buffers
           (bound-and-true-p evil-complete-all-buffers)))
      (cape-dabbrev t)
      (when (> corfu--total 0)
        (corfu--goto (or arg 0))))))

(defun athame-corfu-dabbrev-or-last (&optional arg)
  "Trigger corfu popup and select the first candidate.

Intended to mimic `evil-complete-previous', unless the popup is already open."
  (interactive "p")
  (if corfu--candidates
      (corfu-previous arg)
    (require 'cape)
    (let ((cape-dabbrev-check-other-buffers
           (bound-and-true-p evil-complete-all-buffers)))
      (cape-dabbrev t)
      (when (> corfu--total 0)
        (corfu--goto (- corfu--total (or arg 1)))))))

(defun athame-corfu--other-completion-active-p ()
  (or (bound-and-true-p vertico--input)
      (where-is-internal 'minibuffer-complete (list (current-local-map)))))

(defun athame-corfu--enable-in-minibuffer-p ()
  (and (where-is-internal #'completion-at-point
                          (list (current-local-map)))
       (not (athame-corfu--other-completion-active-p))))

(use-package corfu
  :ghook ('emacs-startup-hook #'global-corfu-mode)
  :init
  (gsetq
   corfu-auto t
   corfu-auto-delay 0.24
   corfu-auto-prefix 2
   corfu-cycle t
   corfu-preselect 'prompt
   corfu-count 16
   corfu-max-width 120
   corfu-on-exact-match nil
   corfu-quit-at-boundary 'separator
   corfu-quit-no-match 'corfu-quit-at-boundary
   tab-always-indent 'complete
   global-corfu-minibuffer #'athame-corfu--enable-in-minibuffer-p)
  :config
  (add-to-list 'corfu-continue-commands #'athame-corfu-smart-sep-toggle-escape)
  (add-hook 'evil-insert-state-exit-hook #'corfu-quit))

(use-package corfu-history
  :hook corfu-mode
  :config
  (with-eval-after-load 'savehist
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(use-package corfu-popupinfo
  :hook corfu-mode
  :init
  (gsetq corfu-popupinfo-delay '(0.15 . 0.3)))

(use-package nerd-icons-corfu
  :defer t
  :init
  (gsetq corfu-margin-formatters (list #'nerd-icons-corfu-formatter)))

(provide 'athame-corfu)
;;; athame-corfu.el ends here
