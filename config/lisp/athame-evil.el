;;; athame-evil.el --- foo -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;;;; Evil
;;;;; Core
(use-package evil
  :preface
  (setq
   evil-want-keybinding nil
   evil-want-C-g-bindings t
   evil-want-C-i-jump t
   evil-want-C-u-scroll  t
   evil-want-C-u-delete  t
   evil-want-C-w-delete t
   evil-want-Y-yank-to-eol t
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
  :config
  (evil-collection-init))

;;;;; Quick movement
(use-package evil-snipe
  :after evil
  :config
  (evil-snipe-mode +1)
  (evil-snipe-override-mode +1)
  :custom
  (evil-snipe-scope 'buffer)        ; Search in whole buffer instead of just line
  (evil-snipe-repeat-scope 'buffer) ; Same for repeat
  (evil-snipe-smart-case t)         ; Smart case sensitivity
  )

;;;;; Evil-Easymotion
(use-package evil-easymotion
  :after (evil-snipe)
  :config
  (general-define-key
   :states '(motion)
   :prefix "C-;"
   :prefix-map 'evilem-map)

  (general-define-key
   :keymaps 'evil-snipe-parent-transient-map
   "C-;" (evilem-create
          'evil-snipe-repeat
          :bind
          ((evil-snipe-scope 'buffer)
           (evil-snipe-enable-highlight)
           (evil-snipe-enable-incremental-highlight)))))

;;;;; Text objects
;;;;;; Surround
(use-package evil-surround
  :hook ((prog-mode text-mode) . global-evil-surround-mode))


;;;;;;  Exato (xml)
(use-package exato)

;;;; Provide
(provide 'athame-evil)
;;; athame-evil.el ends here
