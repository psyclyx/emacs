;;; athame-evil.el --- foo -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;;;; Evil
;;;;; Core
(use-package evil
  :init
  (gsetq
   evil-want-keybinding nil
   evil-respect-visual-line-mode nil
   evil-want-C-i-jump t
   evil-want-C-u-scroll t
   evil-want-C-u-delete t
   evil-want-C-w-delete t
   evil-want-Y-yank-to-eol t
   evil-ex-search-persistent-highlight t
   evil-move-beyond-eol t
   evil-ex-search-vim-style-regexp t
   evil-want-abbrev-expand-on-insert-exit nil
   evil-ex-visual-char-range t
   evil-symbol-word-search t
   evil-undo-system 'undo-redo
   evil-normal-state-cursor 'box
   evil-emacs-state-cursor  'box
   evil-insert-state-cursor 'bar
   evil-visual-state-cursor 'hollow)
  :ghook
  'emacs-startup-hook
  :general-config
  (evil-select-search-module 'evil-search-module 'isearch))
(use-package evil-collection
  :defer t
  :init
  (general-after-init
    (evil-collection-init)))
;;;;; Quick movement
(use-package evil-snipe
  :defer t
  :init
  (gsetq
   evil-snipe-scope 'visible
   evil-snipe-repeat-scope 'whole-visible
   evil-snipe-smart-case t)
  (general-after-init
    (evil-snipe-mode 1)
    (evil-snipe-override-mode 1)))
;;;;; Evil-Easymotion
;; (use-package evil-easymotion
;;   :config
;;   (general-after-init
;;     (general-defs
;;       :states 'motion
;;       "C-;" 'evilem-map

;;       :keymaps 'evil-snipe-parent-transient-map
;;       "C-;" (evilem-create
;; 	     'evil-snipe-repeat
;; 	     :bind
;; 	     ((evil-snipe-scope 'buffer)
;; 	      (evil-snipe-enable-highlight)
;; 	      (evil-snipe-enable-incremental-highlight))))))
;;;;;; Surround
(use-package evil-surround
  :ghook
  ('evil-mode-hook #'global-evil-surround-mode))
;;;; Provide
(provide 'athame-evil)
;;; athame-evil.el ends here
