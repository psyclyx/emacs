;;; athame-vertico -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(defun athame-vertico--ffap-menu-ignore-comp-help-a (&rest args)
  (cl-letf (((symbol-function #'minibuffer-completion-help)
             #'ignore))
    (apply args)))


(use-package vertico
  :ghook 'emacs-startup-hook
  :init
  (gsetq vertico-cycle t
	 vertico-count 20
	 vertico-resize t)
  :config
  (advice-add #'ffap-menu-ask :around
	      #'athame-vertico--ffap-menu-ignore-comp-help-a)
  :general-config
  (:keymaps
   'vertico-map
   "M-j" #'next-line
   "M-k" #'previous-line
   "M-h" #'backward-paragraph
   "M-l" #'forward-paragraph))


(use-package vertico-directory
  :defer t
  :after vertico
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))


(use-package vertico-buffer
  :defer t
  :after vertico)


(use-package vertico-multiform
  :ghook 'vertico-mode-hook
  :init
  (gsetq vertico-multiform-categories '((embark-keybinding grid))))


(use-package vertico-repeat
  :defer t
  :hook (minibuffer-setup . vertico-repeat-save))


(general-defs
  :keymaps '(vertico-map vertico-multiform-map)
  "RET" #'vertico-directory-enter
  "DEL" #'vertico-directory-delete-char
  "M-DEL" #'vertico-directory-delete-word

  :states '(normal insert visual motion)
  "C-M-;" #'vertico-repeat)

(provide 'athame-vertico)
;;; athame-vertico.el ends here
