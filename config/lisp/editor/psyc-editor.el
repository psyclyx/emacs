;;; psyc-editor.el --- Editor defaults and appearance -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

;;;; Savehist

(use-package savehist
  :hook (after-init . savehist-mode))

;;;; Appearance

;;;;; Frame/window titles

(gsetq frame-title-format '("%b – Emacs")
       icon-title-format frame-title-format)

;;;;; Dividers

(gsetq indicate-buffer-boundaries nil
       indicate-empty-lines nil
       window-divider-default-right-width 1)

(when (display-graphic-p)
  (window-divider-mode 0))

;;;;; Splits/boundaries

(gsetq split-width-threshold 160
       split-height-threshold nil)

;;;;; Pixelwise resizing

(gsetq frame-resize-pixelwise t
       window-resize-pixelwise t)

;;;;; Cursor

(add-hook 'after-init-hook (lambda () (blink-cursor-mode -1)))
(gsetq x-stretch-cursor nil)

;;;;; Text

;;;;;; Underline improvements

(gsetq x-underline-at-descent-line t)

;;;;;; Spaces/tabs

(gsetq indent-tabs-mode nil
       tab-width 4)

;;;;;; Line wrapping/truncation

(gsetq truncate-lines t
       truncate-partial-width-windows nil
       word-wrap t
       fill-column 80)

(add-hook 'text-mode-hook #'visual-line-mode)

;;;;;; Sentence/newline style

(gsetq sentence-end-double-space nil
       require-final-newline t)

;;;;;; ws-butler (clean up whitespace)

(use-package ws-butler
  :hook ((prog-mode text-mode) . ws-butler-mode))

;;;;; Line numbers

(use-package display-line-numbers
  :hook (prog-mode-hook text-mode-hook conf-mode-hook)
  :config
  (gsetq display-line-numbers-width 3
         display-line-numbers-widen t
         display-line-numbers-type 'relative))

;;;;; Flash mode-line (visual bell)

(defun psyc-flash-modeline (&optional type)
  "Flash the modeline."
  (let* ((face (if (eq type 'error) 'error 'success))
         (cookie (face-remap-add-relative 'mode-line face)))
    (force-mode-line-update)
    (run-with-timer 0.15 nil
                    (lambda ()
                      (face-remap-remove-relative cookie)
                      (force-mode-line-update)))))

(gsetq ring-bell-function #'psyc-flash-modeline)

;;;;; Show parens

(use-package paren
  :ensure nil
  :hook ((text-mode prog-mode conf-mode) . show-paren-mode)
  :init
  (gsetq show-paren-delay 0.1
         show-paren-highlight-openparen t
         show-paren-when-point-inside-paren t
         show-paren-when-point-in-periphery t
         show-paren-context-when-offscreen 'child-frame
	 blink-matching-paren nil)
  :config
  (add-to-list 'show-paren--context-child-frame-parameters
               '(border-width . 3)))

;;;;; Disable tooltips

(tooltip-mode -1)

;;;; Files

;;;;; Recentf

(use-package recentf
  :ghook 'emacs-startup-hook
  :config
  (gsetq recentf-max-saved-items 512
         recentf-auto-cleanup 15)
  (add-to-list 'recentf-exclude
               (concat "^" (regexp-quote (or (getenv "XDG_RUNTIME_DIR")
                                             "/run"))))
  (add-to-list 'recentf-exclude (concat "^/nix/store"))
  (add-to-list 'recentf-exclude (concat "^" (regexp-quote no-littering-var-directory)))
  (add-to-list 'recentf-exclude (concat "^" (regexp-quote no-littering-etc-directory)))
  (add-to-list 'recentf-filename-handlers #'substring-no-properties)
  (run-at-time "1 min" 60 'recentf-save-list))

;;;;; Follow symlinks

(gsetq find-file-visit-truename t
       vc-follow-symlinks t
       find-file-suppress-same-file-warnings t)

;;;;; Disable lockfiles and backup

(gsetq create-lockfiles nil make-backup-files nil)

;;;;; Create missing directories

(defun psyc-file--create-missing-directories-h ()
  "Automatically create missing directories when creating new files."
  (unless (file-remote-p buffer-file-name)
    (let ((parent-directory (file-name-directory buffer-file-name)))
      (and (not (file-directory-p parent-directory))
           (y-or-n-p (format "Directory `%s' does not exist! Create it?"
                             parent-directory))
           (progn (make-directory parent-directory 'parents)
                  t)))))

(add-hook 'find-file-not-found-functions
          #'psyc-file--create-missing-directories-h)

;;;;; Re-guess mode when saving fundamental buffers

(defun psyc-file--guess-mode-h ()
  "Guess major mode when saving a file in `fundamental-mode'.

Likely, something has changed since the buffer was opened. e.g. A shebang line
or file path may exist now."
  (when (eq major-mode 'fundamental-mode)
    (let ((buffer (or (buffer-base-buffer) (current-buffer))))
      (when (and (buffer-file-name buffer)
                 (eq buffer (window-buffer (selected-window))))
        (set-auto-mode)))))

(add-hook 'after-save-hook #'psyc-file--guess-mode-h)

;;;; Minibuffer

;;;;; Recursive

(gsetq enable-recursive-minibuffers t)

(add-hook 'after-init-hook (lambda () (minibuffer-depth-indicate-mode 1)))

;;;;; Prompt

(gsetq echo-keystrokes 0.5
       minibuffer-prompt-properties
       '(read-only t
                   cursor-intangible t
                   face minibuffer-prompt))

(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

;;;;; Keybinds

(defvar psyc-default-minibuffer-maps
  '(minibuffer-local-map
    minibuffer-local-ns-map
    minibuffer-local-completion-map
    minibuffer-local-must-match-map
    minibuffer-local-isearch-map
    read-expression-map)
  "A list of all the keymaps used for the minibuffer.")

(general-define-key
 :keymaps psyc-default-minibuffer-maps
 [escape] #'abort-recursive-edit
 "C-a"    #'move-beginning-of-line
 "C-r"    #'evil-paste-from-register
 "C-u"    #'evil-delete-back-to-indentation
 "C-v"    #'yank
 "C-w"    #'psyc-delete-backward-word
 "C-z"    (lambda () (interactive)
            (ignore-errors (call-interactively #'undo))))

(general-define-key
 :keymaps psyc-default-minibuffer-maps
 "C-j"    #'next-line
 "C-k"    #'previous-line
 "C-S-j"  #'scroll-up-command
 "C-S-k"  #'scroll-down-command)

(general-define-key
 :keymaps 'read-expression-map
 "C-j" #'next-line-or-history-element
 "C-k" #'previous-line-or-history-element)

;;;; Short y/n prompts

(gsetq use-short-answers t)
(define-key y-or-n-p-map " " nil)

;;;; Help

;;;;; Apropos

(gsetq apropos-do-all t)

;;;;; Helpful

(use-package helpful
  :general
  ([remap describe-function] #'helpful-callable
   [remap describe-command] #'helpful-command
   [remap describe-variable] #'helpful-variable
   [remap describe-key] #'helpful-key
   [remap describe-symbol] #'helpful-symbol))

;;;;; Which-key

(use-package which-key
  :ensure nil
  :init
  (gsetq
   which-key-allow-multiple-replacements t
   which-key-sort-order #'which-key-key-order-alpha
   which-key-sort-uppercase-first nil
   which-key-add-column-padding 1
   which-key-max-display-columns nil
   which-key-min-display-lines 6
   which-key-side-window-slot -10
   which-key-side-window-location 'bottom
   which-key-idle-delay 0.3
   which-key-idle-secondary-delay 0.1
   which-key-allow-evil-operators t
   which-key-show-operator-state-maps t)
  :hook (after-init . which-key-mode))

(provide 'psyc-editor)
;;; psyc-editor.el ends here
