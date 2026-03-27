;;; psyc-check.el --- Syntax checking -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package flycheck
  :defer t
  :ghook ('evil-mode-hook #'global-flycheck-mode)
  :config
  (delq 'new-line flycheck-check-syntax-automatically)
  (gsetq flycheck-emacs-lisp-load-path 'inherit
         flycheck-idle-change-delay 1.0
         flycheck-buffer-switch-check-intermediate-buffers t
         flycheck-display-errors-delay 0.25)
  :general-config
  (:keymaps
   'flycheck-error-list-mode-map
   :states 'normal
   "C-n" #'flycheck-error-list-next-error
   "C-p" #'flycheck-error-list-previous-error
   "j" #'flycheck-error-list-next-error
   "k" #'flycheck-error-list-previous-error
   "RET" #'flycheck-error-list-goto-error
   [return] #'flycheck-error-list-goto-error))

(use-package flycheck-posframe
  :defer t
  :ghook 'flycheck-mode-hook
  :gfhook ('flycheck-posframe-inhibit-functions (list #'evil-insert-state-p #'evil-replace-state-p))
  :config
  (gsetq flycheck-posframe-warning-prefix "  "
         flycheck-posframe-info-prefix " "
         flycheck-posframe-error-prefix " "))

(provide 'psyc-check)
;;; psyc-check.el ends here
