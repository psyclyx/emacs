;;; athame-evil.el --- foo -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;;;; Evil
;;;;; Core
(use-package evil
  :init
  (setq
   evil-want-keybinding nil
   evil-want-C-g-bindings t
   evil-want-C-i-jump t
   evil-want-C-u-scroll  t
   evil-want-C-u-delete  t
   evil-want-C-w-delete t
   evil-want-Y-yank-to-eol t
   evil-move-beyond-eol t
   evil-ex-search-vim-style-regexp t
   evil-want-abbrev-expand-on-insert-exit  nil
   evil-respect-visual-line-mode nil
   evil-ex-visual-char-range t
   evil-symbol-word-search t
   evil-normal-state-cursor 'box
   evil-emacs-state-cursor  'box
   evil-insert-state-cursor 'bar
   evil-visual-state-cursor 'hollow
   evil-undo-system 'undo-redo)
  :config
  (evil-mode 1)
  (evil-select-search-module 'evil-search-module 'isearch))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;;;;; Quick movement
(use-package evil-snipe
  :custom
  (evil-snipe-scope 'visible)
  (evil-snipe-repeat-scope 'visible)
  (evil-snipe-smart-case t)
  :config
  (evil-snipe-mode +1)
  (evil-snipe-override-mode +1))

;;;;; Evil-Easymotion
(use-package evil-easymotion
  :defer t
  :config
  (general-define-key
   :keymaps 'evil-snipe-parent-transient-map
   "C-;" (evilem-create
          'evil-snipe-repeat
          :bind
          ((evil-snipe-scope 'buffer)
           (evil-snipe-enable-highlight)
           (evil-snipe-enable-incremental-highlight)))))

(general-define-key
 :states '(motion)
 :prefix "C-;"
 :prefix-map 'evilem-map)
;;;;;; Surround
(use-package evil-surround
  :after evil)

;;;; Provide
(provide 'athame-evil)
;;; athame-evil.el ends here
