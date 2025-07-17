;;; psyclyx-editor.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(setq find-file-visit-truename t
      vc-follow-symlinks t)

(setq find-file-suppress-same-file-warnings t)

(setq create-lockfiles nil
      make-backup-files nil)

(defun psyclyx-create-missing-directories-h ()
  "Automatically create missing directories when creating new files."
  (unless (file-remote-p buffer-file-name)
    (let ((parent-directory (file-name-directory buffer-file-name)))
      (and (not (file-directory-p parent-directory))
           (y-or-n-p (format "Directory `%s' does not exist! Create it?"
                             parent-directory))
           (progn (make-directory parent-directory 'parents)
                  t)))))
(add-hook 'find-file-not-found-functions #'psyclyx-create-missing-directories-h)

(defun psyclyx-guess-mode-h ()
  "Guess major mode when saving a file in `fundamental-mode'.

Likely, something has changed since the buffer was opened. e.g. A shebang line
or file path may exist now."
  (when (eq major-mode 'fundamental-mode)
    (let ((buffer (or (buffer-base-buffer) (current-buffer))))
      (and (buffer-file-name buffer)
           (eq buffer (window-buffer (selected-window)))
           (set-auto-mode)
           (not (eq major-mode 'fundamental-mode))))))
(add-hook 'after-save-hook #'psyclyx-guess-mode-h)

(setq-default indent-tabs-mode nil
              tab-width 4
              tab-always-indent nil
              tabify-regexp "^\t* [ \t]+")

(setq-default truncate-lines t
              truncate-partial-width-windows nil
              word-wrap t)

(add-hook 'text-mode-hook #'visual-line-mode)

(setq sentence-end-double-space nil)

(setq-default fill-column 80)

(setq require-final-newline t)

(setq whitespace-line-column nil
      whitespace-style
      '(face indentation tabs tab-mark spaces space-mark newline newline-mark
        trailing lines-tail))

(use-package ws-butler
  :hook ((prog-mode text-mode) . ws-butler-mode))

(use-package paren
  :hook ((text-mode prog-mode) . show-paren-mode)
  :config
  (setq show-paren-delay 0.1
        show-paren-highlight-openparen t
        show-paren-when-point-inside-paren t
        show-paren-when-point-in-periphery t))

(setq-default display-line-numbers-width 3
              display-line-numbers-widen t
              display-line-numbers-type 'relative)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)
(add-hook 'conf-mode-hook #'display-line-numbers-mode)

(use-package recentf
  :custom
  (recentf-max-saved-items 512)
  :init
  (recentf-mode))

(use-package savehist)

(setq enable-recursive-minibuffers t)
(setq echo-keystrokes 0.02)

(setq minibuffer-prompt-properties '(read-only t intangible t cursor-intangible t face minibuffer-prompt))
(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

(use-package which-key
  :hook (after-init . which-key-mode)
  :custom
  (which-key-sort-order #'which-key-key-order-alpha)
  (which-key-sort-uppercase-first nil)
  (which-key-add-column-padding 1)
  (which-key-max-display-columns nil)
  (which-key-min-display-lines 6)
  (which-key-side-window-slot -10)
  (which-key-idle-delay 0.3)
  (which-key-idle-secondary-delay 0.1))

(use-package smartparens
    :hook (after-init . smartparens-global-mode)
    :commands
    sp-pair sp-local-pair sp-with-modes sp-point-in-comment sp-point-in-string

    :custom
    (sp-highlight-pair-overlay nil)
    (sp-highlight-wrap-overlay nil)
    (sp-highlight-wrap-tag-overlay nil)
    (sp-show-pair-from-inside t)
    (sp-cancel-autoskip-on-backward-movement nil)
    (sp-max-prefix-length 25)
    (sp-max-pair-length 4)

    :config
    (add-to-list 'sp-lisp-modes 'sly-mrepl-mode)
    (require 'smartparens-config)
    (setq sp-pair-overlay-keymap (make-sparse-keymap))

    ;; Silence some harmless but annoying echo-area spam
    (dolist (key '(:unmatched-expression :no-matching-tag))
      (setf (alist-get key sp-message-alist) nil))



    (add-hook 'eval-expression-minibuffer-setup-hook
              (defun my/init-smartparens-in-eval-expression-h ()
                (when smartparens-global-mode (smartparens-mode +1))))


    (add-hook 'minibuffer-setup-hook
              (defun my/init-smartparens-in-minibuffer-maybe-h ()
                (when (and smartparens-global-mode (memq this-command '(evil-ex)))
                  (smartparens-mode +1))))

    (sp-local-pair '(minibuffer-mode minibuffer-inactive-mode) "'" nil :actions nil)
    (sp-local-pair '(minibuffer-mode minibuffer-inactive-mode) "`" nil :actions nil))


(setq use-short-answers t)
(define-key y-or-n-p-map " " nil)


(setq kill-do-not-save-duplicates t)


(use-package general
  :demand t
  :after (evil)
  :config
  (general-evil-setup))

(defvar evil-want-keybinding nil)
(defvar evil-want-C-g-bindings t)
(defvar evil-want-C-i-jump t)
(defvar evil-want-C-u-scroll t)  ; moved the universal arg to <leader> u
(defvar evil-want-C-u-delete t)
(defvar evil-want-C-w-delete t)
(defvar evil-want-Y-yank-to-eol t)
(defvar evil-want-abbrev-expand-on-insert-exit nil)
(defvar evil-respect-visual-line-mode nil)
(use-package evil
  :preface
  (setq evil-ex-search-vim-style-regexp t
        evil-ex-visual-char-range t
        evil-symbol-word-search t
        evil-normal-state-cursor 'box
        evil-emacs-state-cursor  'box
        evil-insert-state-cursor 'bar
        evil-visual-state-cursor 'hollow
        evil-ex-interactive-search-highlight 'selected-window
        evil-kbd-macro-suppress-motion-error t)

  :config
  (evil-mode 1)
  (evil-select-search-module 'evil-search-module 'evil-search))


(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))


(use-package evil-snipe
  :after evil
  :defer 0.1
  :config
  (evil-snipe-mode +1)
  (evil-snipe-override-mode +1)
  :custom
  (evil-snipe-scope 'buffer)        ; Search in whole buffer instead of just line
  (evil-snipe-repeat-scope 'buffer) ; Same for repeat
  (evil-snipe-smart-case t)         ; Smart case sensitivity
  )

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

(use-package evil-surround
  :hook ((prog-mode text-mode) . global-evil-surround-mode)
  :commands (global-evil-surround-mode
             evil-surround-edit
             evil-Surround-edit
             evil-surround-region))


(use-package evil-textobj-anyblock
  :after evil
  :config
  (setq evil-textobj-anyblock-blocks
        '(("(" . ")")
          ("{" . "}")
          ("\\[" . "\\]")
          ("<" . ">"))))

(use-package exato
  :after evil
  :commands evil-outer-xml-attr evil-inner-xml-attr)

(use-package better-jumper
  :commands my/set-jump-a my/set-jump-maybe-a my/set-jump-h
  :preface
  ;; REVIEW Suppress byte-compiler warning spawning a *Compile-Log* buffer at
  ;; startup. This can be removed once gilbertw1/better-jumper#2 is merged.
  (defvar better-jumper-local-mode nil)
  ;; REVIEW: Remove if/when gilbertw1/better-jumper#26 is addressed.
  (defvaralias 'evil--jumps-jump-command 'evil--jumps-jumping-backward)
  :init
  (global-set-key [remap evil-jump-forward]  #'better-jumper-jump-forward)
  (global-set-key [remap evil-jump-backward] #'better-jumper-jump-backward)
  (global-set-key [remap xref-pop-marker-stack] #'better-jumper-jump-backward)
  (global-set-key [remap xref-go-back] #'better-jumper-jump-backward)
  (global-set-key [remap xref-go-forward] #'better-jumper-jump-forward)
  :config
  (better-jumper-mode)
  (defun my/set-jump-a (fn &rest args)
    "Set a jump point and ensure fn doesn't set any new jump points."
    (better-jumper-set-jump (if (markerp (car args)) (car args)))
    (let ((evil--jumps-jumping t)
          (better-jumper--jumping t))
      (apply fn args)))

  (defun my/set-jump-maybe-a (fn &rest args)
    "Set a jump point if fn actually moves the point."
    (let ((origin (point-marker))
          (result
           (let* ((evil--jumps-jumping t)
                  (better-jumper--jumping t))
             (apply fn args)))
          (dest (point-marker)))
      (unless (equal origin dest)
        (with-current-buffer (marker-buffer origin)
          (better-jumper-set-jump
           (if (markerp (car args))
               (car args)
             origin))))
      (set-marker origin nil)
      (set-marker dest nil)
      result))

  (defun my/set-jump-h ()
    "Run `better-jumper-set-jump' but return nil, for short-circuiting hooks."
    (when (get-buffer-window)
      (better-jumper-set-jump))
    nil)

  (add-hook 'kill-buffer-hook #'my/set-jump-h)
  (advice-add #'imenu :around #'my/set-jump-a))


(provide 'psyclyx-editor)
