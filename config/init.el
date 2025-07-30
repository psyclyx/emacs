;;; init.el -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;;; Requires
(require 'cl-lib)
(require 'dash)

;;;; Config vars

(defvar athame-cache-dir "~/.cache/emacs")
(defvar athame-state-dir "~/.local/state/emacs")

;;;; Lib

(defun athame-delete-backward-word (arg)
  "Like `backward-kill-word', but doesn't affect the kill-ring."
  (interactive "p")
  (let ((kill-ring nil) (kill-ring-yank-pointer nil))
    (ignore-errors (backward-kill-word arg))))

(defmacro athame-cmd (&rest body)
  "Returns (lambda () (interactive) ,@body)
  A factory for quickly producing interaction commands, particularly for keybinds
  or aliases."
  (declare (doc-string 1))
  `(lambda (&rest _) (interactive) ,@body))

(defun athame-add-hooks (symbols fn)
  (mapc (lambda (sym) (add-hook sym fn)) symbols))

(defun athame-dired-buffer-p (buf)
  "Returns non-nil if BUF is a dired buffer."
  (provided-mode-derived-p (buffer-local-value 'major-mode buf)
                           'dired-mode))

(defun athame-special-buffer-p (buf)
  "Returns non-nil if BUF's name starts and ends with an *."
  (char-equal ?* (aref (buffer-name buf) 0)))

(defun athame-temp-buffer-p (buf)
  "Returns non-nil if BUF is temporary."
  (char-equal ?\s (aref (buffer-name buf) 0)))

;;;; General

(use-package general
  :ensure t
  :demand t
  :config
  (general-override-mode +1)
  ;; Also includes a substantially faster `setq`
  (defalias 'gsetq #'general-setq))

;;;; Savehist

(use-package savehist
  :init
  (gsetq savehist-file (file-name-concat athame-state-dir "savehist"))
  (general-after-init
    (savehist-mode)))

;;;; Editor

;;;;; Appearance

;;;;;; Frame/window titles

(gsetq frame-title-format '("%b – Emacs")
       icon-title-format frame-title-format)

;;;;;; Dividers

(gsetq indicate-buffer-boundaries nil
       indicate-empty-lines nil
       window-divider-default-right-width 1)

(when (display-graphic-p)
  (window-divider-mode 0))

;;;;;; Splits/boundaries

(gsetq split-width-threshold 160
       split-height-threshold nil)

;;;;;; Pixelwise resizing

(gsetq frame-resize-pixelwise t
       window-resize-pixelwise t)

;;;;;; Cursor

(general-after-init (blink-cursor-mode -1))
(gsetq x-stretch-cursor nil)

;;;;;; Text

;;;;;;; Underline improvements

(gsetq x-underline-at-descent-line t)

;;;;;;; Spaces/tabs

(gsetq indent-tabs-mode nil
       tab-width 4)

;;;;;;; Line wrapping/truncation

(gsetq truncate-lines t
       truncate-partial-width-windows nil
       word-wrap t
       fill-column 80)

(add-hook 'text-mode-hook #'visual-line-mode)

;;;;;;; Sentence/newline style

(gsetq sentence-end-double-space nil
       require-final-newline t)

;;;;;;; ws-butler (clean up whitespace)

(use-package ws-butler
  :hook ((prog-mode text-mode) . ws-butler-mode))

;;;;;; Line numbers

(use-package display-line-numbers
  :hook (prog-mode-hook text-mode-hook conf-mode-hook)
  ;; TODO: is this faster as an :init?
  :config
  (gsetq display-line-numbers-width 3
         display-line-numbers-widen t
         display-line-numbers-type 'relative))

;;;;;; Flash mode-line (visual bell)

(defun athame-flash-modeline ()
  "Briefly inverts the `mode-line' face."
  (invert-face 'mode-line)
  (run-with-timer 0.1 nil 'invert-face 'mode-line))

(gsetq ring-bell-function #'athame-flash-modeline)

;;;;;; Show parens

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

;;;;;; Disable tooltips

(when (bound-and-true-p tooltip-mode)
  (tooltip-mode -1))

;;;;; Files

;;;; Recentf

(use-package recentf
  :ghook 'emacs-startup-hook
  :config
  (gsetq recentf-save-file (file-name-concat athame-state-dir "recentf")
         recentf-max-saved-items 512
         recentf-auto-cleanup 15)
  (add-to-list 'recentf-exclude
               (concat "^" (regexp-quote (or (getenv "XDG_RUNTIME_DIR")
                                             "/run"))))
  (add-to-list 'recentf-exclude (concat "^/nix/store"))
  (add-to-list 'recentf-filename-handlers #'substring-no-properties)
  (run-at-time "1 min" 60 'recentf-save-list))

;;;;;; Follow symlinks

(gsetq find-file-visit-truename t
       vc-follow-symlinks t
       find-file-suppress-same-file-warnings t)

;;;;;; Disable lockfiles and backup

(gsetq create-lockfiles nil make-backup-files nil)

;;;;;; Create missing directories

(defun athame-file--create-missing-directories-h ()
  "Automatically create missing directories when creating new files."
  (unless (file-remote-p buffer-file-name)
    (let ((parent-directory (file-name-directory buffer-file-name)))
      (and (not (file-directory-p parent-directory))
           (y-or-n-p (format "Directory `%s' does not exist! Create it?"
                             parent-directory))
           (progn (make-directory parent-directory 'parents)
                  t)))))

(add-hook 'find-file-not-found-functions
          #'athame-file--create-missing-directories-h)

;;;;;; Re-guess mode when saving fundamental buffers

(defun athame-file--guess-mode-h ()
  "Guess major mode when saving a file in `fundamental-mode'.

Likely, something has changed since the buffer was opened. e.g. A shebang line
or file path may exist now."
  (when (eq major-mode 'fundamental-mode)
    (let ((buffer (or (buffer-base-buffer) (current-buffer))))
      (and (buffer-file-name buffer)
           (eq buffer (window-buffer (selected-window)))
           (set-auto-mode)
           (not (eq major-mode 'fundamental-mode))))))

(add-hook 'after-save-hook #'athame-file--guess-mode-h)

;;;;; Minibuffer

;;;;;; Recursive

(gsetq enable-recursive-minibuffers t)

(general-after-init
  (minibuffer-depth-indicate-mode 1))

;;;;;; Prompt

(gsetq echo-keystrokes 0.5
       minibuffer-prompt-properties
       '(read-only t
                   intangible t
                   cursor-intangible t face minibuffer-prompt))

(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

;;;;;; Keybinds

(defvar athame-default-minibuffer-maps
  (append '(minibuffer-local-map
            minibuffer-local-ns-map
            minibuffer-local-completion-map
            minibuffer-local-must-match-map
            minibuffer-local-isearch-map
            read-expression-map))
  "A list of all the keymaps used for the minibuffer.")

(general-define-key
 :keymaps athame-default-minibuffer-maps
 [escape] #'abort-recursive-edit
 "C-a"    #'move-beginning-of-line
 "C-r"    #'evil-paste-from-register
 "C-u"    #'evil-delete-back-to-indentation
 "C-v"    #'yank
 "C-w"    #'athame-delete-backward-word
 "C-z"    (lambda () (interactive)
            (ignore-errors (call-interactively #'undo))))

(general-define-key
 :keymaps athame-default-minibuffer-maps
 "C-j"    #'next-line
 "C-k"    #'previous-line
 "C-S-j"  #'scroll-up-command
 "C-S-k"  #'scroll-down-command)

(general-define-key
 :keymaps 'read-expression-map
 "C-j" #'next-line-or-history-element
 "C-k" #'previous-line-or-history-element)



;;;;; Short y/n prompts

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
  :init
  (gsetq
   which-key-allow-multiple-replacements t
   which-key-sort-order #'which-key-key-order-alpha
   which-key-sort-uppercase-first nil
   which-key-add-column-padding 1
   which-key-max-display-columns nil
   which-key-min-display-lines 6
   which-key-side-window-slot -10
   which-key-idle-delay 0.3
   which-key-idle-secondary-delay 0.1
   which-key-allow-evil-operators t
   which-key-show-operator-state-maps t)
  (general-after-init
    (which-key-mode)
    (which-key-setup-side-window-bottom)))

;;;; Evil

;;;;; Evil-mode

(use-package evil
  :ghook 'emacs-startup-hook
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

  :config
  (evil-select-search-module 'evil-search-module 'isearch)

  :general-config
  (:keymaps
   '(evil-ex-completion-map evil-ex-search-keymap)
   "C-a" #'evil-beginning-of-line
   "C-b" #'evil-backward-char
   "C-f" #'evil-forward-char)

  (:keymaps
   '(evil-ex-completion-map evil-ex-search-keymap)
   :states 'insert
   "C-j" #'next-complete-history-element
   "C-k" #'previous-complete-history-element))

;;;;; Evil-collection

(use-package evil-collection
  :defer t
  :init
  (gsetq evil-collection-outline-bind-tab-p t)
  (general-after-init
    (evil-collection-init)))

;;;;; Evil-snipe + evil-easymotion

(use-package evil-snipe
  :defer 0.5
  :init
  (gsetq
   evil-snipe-scope 'visible
   evil-snipe-repeat-scope 'whole-visible
   evil-snipe-smart-case t)
  :config
  (evil-snipe-mode 1)
  (evil-snipe-override-mode 1))

(use-package evil-easymotion
  :defer 0.5
  :config
  (evilem-default-keybindings "C-;")
  (general-after 'evil-snipe
    (general-defs
      :keymaps 'evil-snipe-parent-transient-map
      "C-;" (evilem-create
 	     'evil-snipe-repeat
 	     :bind
 	     ((evil-snipe-scope 'buffer)
 	      (evil-snipe-enable-highlight)
 	      (evil-snipe-enable-incremental-highlight))))))

;;;;; Evil-surround

(use-package evil-surround
  :ghook
  ('evil-mode-hook #'global-evil-surround-mode))

;;;; Completion

;;;;; CRM indicator fix

(defun athame-completion--crm-indicator-a (args)
  (cons (format "[CRM%s] %s"
                (string-replace "[ \t]*" "" crm-separator)
                (car args))
        (cdr args)))

(when (< emacs-major-version 31)
  (advice-add #'completing-read-multiple :filter-args
              #'athame-completion--crm-indicator-a))

;;;;; Cape (capf)

(defun athame-cape--add-elisp-block-capf-h ()
  (add-hook 'completion-at-point-functions #'cape-elisp-block 0 t))

(defvar athame-cape--buffer-scan-limit (* 1 1024 1024))

(defun athame-cape--dabbrev-friendly-buffer (other-buffer)
  (< (buffer-size other-buffer) athame-cape--buffer-scan-limit))

(use-package cape
  :ghook
  ('(org-mode-hook markdown-mode-hook) #'athame-cape--add-elisp-block-capf-h)

  :init
  (gsetq
   cape-dabbrev-check-other-buffers t
   dabbrev-friend-buffer-function #'athame-cape--dabbrev-friendly-buffer
   dabbrev-ignored-buffer-regexps
   '("\\` "
     "\\(?:\\(?:[EG]?\\|GR\\)TAGS\\|e?tags\\|GPATH\\)\\(<[0-9]+>\\)?")
   dabbrev-upcase-means-case-search t)

  :config
  (general-add-hook 'completion-at-point-functions
		    (list #'cape-keyword #'cape-dabbrev #'cape-file))
  (general-advice-add (list #'comint-completion-at-point
                            #'eglot-completion-at-point
                            #'pcomplete-completions-at-point)
		      :around #'cape-wrap-nonexclusive)

  :general-config
  (:keymaps
   'override
   :states 'insert
   "C-c p" '("cape" . cape-prefix-map)))

;;;;; Corfu

;;;;;; Commands
(defun athame-corfu-move-to-minibuffer ()
  (interactive)
  (pcase completion-in-region--data
    (`(,beg ,end ,table ,pred ,extras)
     (let ((completion-extra-properties extras) completion-cycle-threshold completion-cycling)
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

;;;;;; Predicates
(defun athame-corfu--other-completion-active-p ()
  (or (bound-and-true-p vertico--input)
      (where-is-internal 'minibuffer-complete (list (current-local-map)))))

(defun athame-corfu--enable-in-minibuffer-p ()
  (and (where-is-internal #'completion-at-point
                          (list (current-local-map)))
       (not (athame-corfu--other-completion-active-p))))


;;;;;; Packages
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
   corfu-quit-no-match 'separator
   tab-always-indent 'complete
   global-corfu-minibuffer #'athame-corfu--enable-in-minibuffer-p)

  :config
  (add-to-list 'corfu-continue-commands #'athame-corfu-smart-sep-toggle-escape)
  (add-hook 'evil-insert-state-exit-hook #'corfu-quit)

  :general-config
  (:keymaps
   'corfu-mode-map
   :states 'insert
   "C-@" #'completion-at-point
   "C-SPC" #'completion-at-point
   "C-n" #'athame-corfu-dabbrev-or-next
   "C-p" #'athame-corfu-dabbrev-or-last)
  (:keymaps
   'corfu-mode-map
   :states 'normal
   "C-SPC" (lambda () (interactive)
             (call-interactively #'evil-insert-state)
             (call-interactively #'completion-at-point)))
  (:keymaps
   'corfu-mode-map
   :states '(visual)
   "C-SPC" (lambda () (interactive)
             (call-interactively #'evil-change-state)
             (call-interactively #'completion-at-point)))
  (:keymaps
   'corfu-map
   :states '(insert)
   "C-SPC" #'athame-corfu-smart-sep-toggle-escape
   "C-S-s" #'athame-corfu-move-to-minibuffer
   "DEL" #'corfu-reset)
  (:keymaps
   'corfu-map
   "TAB" #'corfu-next
   "C-j" 'corfu-next
   "S-TAB" #'corfu-previous
   [backtab] #'corfu-previous
   "C-k" 'corfu-previous
   "C-u" (lambda () (interactive)
           (let (curfu-cycle)
             (funcall-interactively #'corfu-next (- corfu-count))))
   "C-d" (lambda () (interactive)
           (let (curfu-cycle)
             (funcall-interactively #'corfu-next corfu-count)))))



(use-package corfu-history
  :hook corfu-mode
  :config
  (with-eval-after-load 'savehist
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(use-package corfu-popupinfo
  :hook corfu-mode
  :init
  (gsetq corfu-popupinfo-delay '(0.15 . 0.3))
  :general-config
  (:keymaps
   'corfu-popupinfo-map
   "C-h" 'corfu-popupinfo-toggle
   "C-S-k" #'corfu-popupinfo-scroll-down
   "C-S-j" #'corfu-popupinfo-scroll-up
   "C-<up>" #'corfu-popupinfo-scroll-down
   "C-<down>" #'corfu-popupinfo-scroll-up
   "C-S-p" #'corfu-popupinfo-scroll-down
   "C-S-n" #'corfu-popupinfo-scroll-up
   "C-S-u" (lambda () (interactive)
             (corfu-popupinfo-scroll-down nil corfu-popupinfo-min-height))
   "C-S-d" (lambda () (interactive)
             (corfu-popupinfo-scroll-up nil corfu-popupinfo-min-height))))

(use-package nerd-icons-corfu
  :defer t
  :init
  (gsetq corfu-margin-formatters (list #'nerd-icons-corfu-formatter)))

;;;;; Vertico

;;;;;; Advice

(defun athame-vertico--ffap-menu-ignore-comp-help-a (&rest args)
  (cl-letf (((symbol-function #'minibuffer-completion-help)
             #'ignore))
    (apply args)))

;;;;; Packages

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
  (gsetq vertico-multiform-categories '((embark-keybinding grid)))
  :general
  (:keymaps '(vertico-map vertico-multiform-map)
            "RET" #'vertico-directory-enter
            "DEL" #'vertico-directory-delete-char
            "M-DEL" #'vertico-directory-delete-word))

(use-package vertico-repeat
  :defer t
  :hook (minibuffer-setup . vertico-repeat-save)
  :general-config
  (:states '(normal insert visual motion)
           "C-M-;" #'vertico-repeat))

;;;;; Orderless

;;;;;; Dispatchers

(defun athame-orderless--dispatch (pattern _index _total)
  (let ((len (length pattern))
        (alist orderless-affix-dispatch-alist))
    (when (> len 0)
      (cond
       ;; Ignore single dispatcher character
       ((and (= len 1) (alist-get (aref pattern 0) alist)) #'ignore)
       ;; Prefix
       ((when-let ((style (alist-get (aref pattern 0) alist))
                   ((not (char-equal (aref pattern (max (1- len) 1)) ?\\))))
          (cons style (substring pattern 1))))
       ;; Suffix
       ((when-let ((style (alist-get (aref pattern (1- len)) alist))
                   ((not (char-equal (aref pattern (max 0 (- len 2))) ?\\))))
          (cons style (substring pattern 0 -1))))))))


(defun athame-orderless--disambiguation-dispatch (pattern _index _total)
  (when (char-equal (aref pattern (1- (length pattern))) ?$)
    `(orderless-regexp . ,(concat (substring pattern 0 -1)
				  "[\x200000-\x300000]*$"))))


;;;;;; Advice

(defun athame-orderless--company-capf-candidates-a (fn &rest args)
  (let ((orderless-match-faces [completions-common-part])
        (completion-styles '(basic partial-completion orderless)))
    (apply fn args)))



;;;;;; Package
(use-package orderless
  :defer t
  :init
  (gsetq orderless-affix-dispatch-alist
         '((?! . orderless-without-literal)
           (?& . orderless-annotation)
           (?% . char-fold-to-regexp)
           (?` . orderless-initialism)
           (?= . orderless-literal)
           (?^ . orderless-literal-prefix)
           (?~ . orderless-flex))
         orderless-style-dispatchers
         '(athame-orderless--dispatch
           athame-orderless--disambiguation-dispatch))

  (gsetq completion-styles '(orderless basic)
         completion-category-defaults nil
         completion-category-overrides '((file (styles orderless partial-completion))))

  :config
  (gsetq orderless-component-separator #'orderless-escapable-split-on-space)
  (advice-add 'company-capf--candidates :around #'athame-orderless--company-capf-candidates-a)
  (set-face-attribute 'completions-first-difference nil :inherit nil))

;;;;; Consult

(use-package consult
  :init
  (gsetq
   consult-narrow-key "<"
   consult-line-numbers-width t
   consult-async-min-input 2
   consult-async-refresh-delay  0.15
   consult-async-input-throttle 0.2
   consult-async-input-debounce 0.1
   register-preview-delay 0.5)
  (advice-add #'register-preview :override #'consult-register-window)

  :general
  ([remap bookmark-jump]                 #'consult-bookmark
   [remap evil-show-marks]               #'consult-mark
   [remap evil-show-registers]           #'consult-register
   [remap goto-line]                     #'consult-goto-line
   [remap imenu]                         #'consult-imenu
   [remap Info-search]                   #'consult-info
   [remap list-dir]                      #'consult-dir
   [remap locate]                        #'consult-locate
   [remap load-theme]                    #'consult-theme
   [remap recentf-open-files]            #'consult-recent-file
   [remap switch-to-buffer]              #'consult-buffer
   [remap switch-to-buffer-other-window] #'consult-buffer-other-window
   [remap switch-to-buffer-other-frame]  #'consult-buffer-other-frame
   [remap yank-pop]                      #'consult-yank-pop)

  :config
  (gsetq xref-show-xrefs-function #'consult-xref
	 xref-show-definitions-function #'consult-xref)

  (consult-customize
   consult-theme
   :preview-key '(:debounce 0.1 any)

   consult-ripgrep consult-git-grep consult-grep consult-man
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   :preview-key '(:debounce 0.3 any)

   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file
   consult--source-recent-file consult--source-project-recent-file consult--source-bookmark
   :preview-key "C-SPC")

  (general-with-eval-after-load 'evil
    (gsetq evil-jumps-cross-buffers nil)
    (evil-set-command-property 'consult-line :jump t))

  (general-with-eval-after-load 'vertico
    (general-def
      :keymaps 'vertico-map
      "C-x C-d" #'consult-dir
      "C-x C-j" #'consult-dir-jump-file)))

;;;;; Marginalia

(use-package marginalia
  :after vertico
  :ghook 'vertico-mode-hook
  :init
  (gsetq marginalia-max-relative-age 0)
  :config
  (add-to-list 'marginalia-prompt-categories '("\\<face\\>" . face))
  (add-to-list 'marginalia-prompt-categories '("\\<var\\>" . variable)))

(use-package nerd-icons-completion
  :after marginalia
  :ghook ('marginalia-mode-hook #'nerd-icons-completion-marginalia-setup)
  :config
  (general-after-gui
    (nerd-icons-completion-marginalia-setup)))

;;;; Tools

;;;;; Smartparens/cleverparens

(use-package smartparens
  :defer t
  :hook ((prog-mode . smartparens-mode)
         (emacs-lisp-mode . smartparens-strict-mode))
  :init
  (gsetq sp-show-pair-delay 0.125
	 sp-show-pair-from-inside t))

(use-package evil-cleverparens
  :defer t
  :hook (emacs-lisp-mode . evil-cleverparens-mode)
  :init
  (gsetq evil-cleverparens-swap-move-by-word-and-symbol t))

;;;;; Ispell

(use-package ispell
  :defer t
  :init
  (gsetq ispell-program-name "aspell"))

;;;;; Compile

(defun athame-compile (arg)
  "Runs `compile' from the root of the current project.

If a compilation window is already open, recompile that instead.

If ARG (universal argument), runs `compile' from the current directory."
  (interactive "P")
  (if (and (bound-and-true-p compilation-in-progress)
           (buffer-live-p compilation-last-buffer))
      (recompile)
    (call-interactively
     (if arg
         #'project-compile
       #'compile))))

;;;;; Formatting

(defcustom athame-format-on-save-disabled-modes
  '(org-msg-edit-mode) "Don't format on these modes"
  :type '(list symbol))

(defun athame-format--inhibit-p ()
  (or (eq major-mode 'fundamental-mode)
      (string-blank-p (buffer-name))
      (eq athame-format-on-save-disabled-modes t)
      (not (null (memq major-mode athame-format-on-save-disabled-modes)))))

(defun athame-format--update-web-mode-h ()
  (when (eq major-mode 'web-mode)
    (setq web-mode-fontification-off nil)
    (when (and web-mode-scan-beg web-mode-scan-end global-font-lock-mode)
      (save-excursion
        (font-lock-fontify-region web-mode-scan-beg web-mode-scan-end)))))

(use-package apheleia
  :defer t
  :ghook
  'prog-mode-hook 'text-mode-hook 'conf-mode-hook
  ('apheleia-inhibit-functions #'athame-format--inhibit-p)
  ('apheleia-post-format-hook #'athame-format--update-web-mode-h)

  :config
  (add-to-list 'apheleia-mode-alist '(sh-mode . shfmt))
  (add-to-list 'apheleia-formatters '(lsp . eglot-format-buffer))

  (setf (alist-get 'nix-mode apheleia-formatters) '("nixfmt" "-s"))

  (add-to-list 'apheleia-mode-alist '(cuda-mode . clang-format))
  (add-to-list 'apheleia-mode-alist '(protobuf-mode . clang-format))
  (add-to-list 'apheleia-formatters-mode-extension-assoc '(cuda-mode . ".cu"))
  (add-to-list 'apheleia-formatters-mode-extension-assoc '(protobuf-mode . ".proto"))

  (setf (alist-get 'clang-format apheleia-formatters)
        `("clang-format"
          "-assume-filename"
          (or (apheleia-formatters-local-buffer-file-name)
              (apheleia-formatters-mode-extension)
              ".c")
          (when apheleia-formatters-respect-indent-level
            (unless (locate-dominating-file default-directory ".clang-format")
              (format "--style={IndentWidth: %d}" c-basic-offset)))))

  ;; Respect prettier settings (from doom)
  (dolist (formatter '(prettier prettier-css prettier-html prettier-javascript
                                prettier-json prettier-scss prettier-svelte
                                prettier-typescript prettier-yaml))
    (setf (alist-get formatter apheleia-formatters)
          (append (delete '(apheleia-formatters-js-indent "--use-tabs" "--tab-width")
                          (alist-get formatter apheleia-formatters))
                  '((when apheleia-formatters-respect-indent-level
                      (unless (or (cl-loop for file
                                           in '(".prettierrc"
                                                ".prettierrc.json"
                                                ".prettierrc.yml"
                                                ".prettierrc.yaml"
                                                ".prettierrc.json5"
                                                ".prettierrc.js" "prettier.config.js"
                                                ".prettierrc.mjs" "prettier.config.mjs"
                                                ".prettierrc.cjs" "prettier.config.cjs"
                                                ".prettierrc.toml")
                                           if (locate-dominating-file default-directory file)
                                           return t)
                                  (when-let ((pkg (locate-dominating-file default-directory "package.json")))
                                    (require 'json)
                                    (let ((json-key-type 'alist))
                                      (assq 'prettier
                                            (json-read-file (expand-file-name "package.json" pkg))))))
                        (apheleia-formatters-indent "--use-tabs" "--tab-width"))))))))

;;;;; LSP (eglot)

(use-package eglot
  :defer t
  :init
  (gsetq eglot-sync-connect 1
	 eglot-autoshutdown t
	 eglot-events-buffer-config '(:size 0 :format full)))

(use-package consult-eglot
  :defer t
  :after eglot
  :general
  (:keymaps
   'eglot-mode-map
   [remap xref-find-apropos] #'consult-eglot-symbols))

;;;;; Eldoc

(use-package eldoc
  :defer t
  :init
  (gsetq eldoc-echo-area-use-multiline-p t
	 eldoc-echo-area-prefer-doc-buffer t
	 eldoc-documentation-strategy 'eldoc-documentation-compose-eagerly))

;;;;; Project

(defvar athame-project-marker ".project")

(use-package project
  :defer t
  :init
  (gsetq project-list-file (file-name-concat athame-state-dir "projects")
         project-vc-merge-submodules nil)
  :config
  (when athame-project-marker
    (add-to-list 'project-vc-extra-root-markers athame-project-marker)))

(defun athame--dir-locals-file ()
  (if (eq system-type 'ms-dos)
      (dosified-file-name dir-locals-file)
    dir-locals-file))

(defun athame--dir-locals-2-file ()
  (let ((dir-locals (athame--dir-locals-file)))
    (when (string-match "\\.el\\'" dir-locals)
      (replace-match "-2.el" t nil dir-locals))))

(defun athame-project-edit-dir-locals (&optional local)
  (interactive "P")
  (let* ((dir-locals-file (if local
                              (athame--dir-locals-2-file)
                            (athame--dir-locals-file)))
         (root (project-root (project-current t)))
         (expanded-file (expand-file-name dir-locals-file root)))
    (find-file expanded-file)))

(defun athame-project-find-file-in-other-project (project &optional include-all)
  (interactive (list (funcall project-prompter)) "P")
  (project--remember-dir project)
  (let ((project-current-directory-override project))
    (project-find-file include-all)))

(defun athame-project-create-marker (dir)
  "Create an empty file in `dir' so `project.el' can see it as a project."
  (interactive "D")
  (let ((marker-file (expand-file-name athame-project-marker dir)))
    (make-empty-file marker-file)))

(defun athame-consult-switch-project ()
  (interactive)
  (consult-buffer '(consult--source-project-root)))

(general-define-key
 :prefix-map 'athame-project-prefix-map
 "." (cons "Browse project" #'project-dired)
 "!" (cons "Run cmd in project root" #'project-shell-command)
 "&" (cons "Async cmd in project root" #'project-async-shell-command)
 "a" (cons "Discover projects in dir" #'project-remember-projects-under)
 "A" (cons "Create .project in dir" #'athame-project-create-marker)
 "b" (cons "Switch to project buffer" #'project-switch-to-buffer)
 "c" (cons "Compile in project" #'project-compile)
 "d" (cons "Forget project" #'project-forget-project)
 "D" (cons "Forget projects in dir" #'project-forget-projects-under)
 "e" (cons "Edit project .dir-locals" #'athame-project-edit-dir-locals)
 "p" (cons "Switch project" #'athame-consult-switch-project)
 "Z" (cons "Forget zombie projects" #'project-forget-zombie-projects)
 "f" (cons "Find file in project" #'project-find-file)
 "F" (cons "Find file in other project" #'athame-project-find-file-in-other-project))

;;;; Version control

(use-package magit
  :defer t
  :config
  (gsetq
   magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1
   magit-bury-buffer-function #'magit-restore-window-configuration
   magit-save-repository-buffers 'dontask
   magit-no-confirm '(stage-all-changes unstage-all-changes)))

;;;; Envrc

(use-package envrc
  :ghook ('emacs-startup-hook #'envrc-global-mode))

;;;; Tramp

(use-package tramp
  :defer t)

;;;; Flycheck

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
  (gsetq flycheck-posframe-warning-prefix "  "
         flycheck-posframe-info-prefix " "
         flycheck-posframe-error-prefix " "))


;;;; Window management

(gsetq display-buffer-alist
       '(("\\*eldoc\\*"
          (display-buffer-reuse-mode-window
           display-buffer-in-side-window)
          (side . right)
          (slot . 0)
          (width . 0.3))
         ("\\*[hH]elp\\(ful.*\\)?\\*"
          (display-buffer-reuse-mode-window
           display-buffer-in-side-window)
          (side . right)
          (slot . -1)
          (width . 0.3))
         ("\\*info\\*"
          (display-buffer-reuse-mode-window
           display-buffer-in-side-window)
          (side . right)
          (slot . 1)
          (width . 0.3))))

;;;; Languages

;;;;; Nix

(use-package nix-mode
  :defer t
  :mode "\\.nix\\'"
  :init
  (add-to-list 'auto-mode-alist
               (cons "/flake\\.lock\\'"
                     'js-json-mode))
  (general-after 'tramp
    (add-to-list 'tramp-remote-path "/run/current-system/sw/bin"))

  :general-config
  (:keymaps
   'nix-mode
   "f" #'nix-update-fetch
   "p" #'nix-format-buffer
   "r" #'nix-repl
   "s" #'nix-shell
   "b" #'nix-build
   "u" #'nix-unpack))

;;;;; Emacs lisp

;; (use-package elisp-mode
;;   :config
;;   (let ((modes '(emacs-lisp-mode lisp-interaction-mode lisp-data-mode)))))

;;;; Bindings

(general-define-key
 :states '(normal visual)
 "gt" #'tab-next
 "gT" #'tab-previous
 "gd" #'xref-find-definitions
 "gD" #'xref-find-references)

(general-define-key
 :prefix-map 'athame-buffer-prefix-map
 "b" (cons "Switch buffer" #'switch-to-buffer)
 "d" (cons "Kill current buffer" #'kill-current-buffer)
 "i" (cons "ibuffer" #'ibuffer)
 "l" (cons "Switch to last buffer" #'evil-switch-to-windows-last-buffer)
 "m" (cons "Set bookmark" #'bookmark-set)
 "M" (cons "Delete bookmark" #'bookmark-delete)
 "r" (cons "Revert buffer" #'revert-buffer))

(general-define-key
 :prefix-map 'athame-code-prefix-map
 "l" (cons "Start LSP" #'eglot)
 "L" (cons "Reconnect LSP" #'eglot-reconnect)
 "x" (cons "Shutdown LSP" #'eglot-shutdown)
 "X" (cons "Shutdown LSP (all)" #'eglot-shutdown-all)
 "a" (cons "LSP Execute code action" #'eglot-code-actions)
 "r" (cons "LSP Rename" #'eglot-rename)
 "j" (cons "LSP Find declaration" #'eglot-find-declaration)
 "c" (cons "Compile" #'athame-compile)
 "C" (cons "Compile" #'recompile)
 "d" (cons "Jump to definition" #'xref-find-definitions)
 "D" (cons "Jump to references" #'xref-find-references))

(general-define-key
 :prefix-map 'athame-file-prefix-map
 "f" (cons "Find file" #'find-file)
 "d" (cons "Find directory" #'dired)
 "h" (cons "Find heading" #'consult-outline)
 "l" (cons "Locate files" #'locate)
 "r" (cons "Recent files" #'recentf-open-files))

(general-define-key
 :keymaps 'help-map
 "C-h" "")

(general-define-key
 :prefix-map 'athame-search-prefix-map
 "l" (cons "Search buffer lines" #'consult-line)
 "S" (cons "Search all buffer lines" #'consult-line)
 "L" (cons "Jump to link" #'ffap-menu)
 "p" (cons "Search project" #'consult-ripgrep)
 "i" (cons "imenu" #'imenu)
 "j" (cons "Jump list" #'evil-show-jumps)
 "I" (cons "imenu (project buffers)" #'consult-imenu-multi))

(general-define-key
 :prefix-map 'athame-git-find-prefix-map
 "f" (cons "Find file" #'magit-find-file)
 "g" (cons "Find gitconfig file" #'magit-find-git-config-file)
 "c" (cons "Find commit" #'magit-show-commit))

(general-define-key
 :prefix-map 'athame-git-create-prefix-map
 "r" (cons "Initialize repo" #'magit-init)
 "R" (cons "Clone repo" #'magit-clone)
 "c" (cons "Commit" #'magit-commit-create)
 "f" (cons "Fixup" #'magit-commit-fixup)
 "b" (cons "Branch" #'magit-branch-and-checkout))

(general-define-key
 :prefix-map 'athame-git-prefix-map
 "c" (cons "create" athame-git-create-prefix-map)
 "f" (cons "find" athame-git-find-prefix-map)
 "R" (cons "Revert file" #'vc-revert)
 "/" (cons "Magit dispatch" #'magit-dispatch)
 "." (cons "Magit file dispatch" #'magit-dispatch)
 "b" (cons "Magit switch branch" #'magit-branch-checkout)
 "g" (cons "Magit status" #'magit-status)
 "G" (cons "Magit status here" #'magit-status)
 "D" (cons "Magit file delete" #'magit-file-delete)
 "B" (cons "Magit blame" #'magit-blame-addition)
 "C" (cons "Magit clone" #'magit-clone)
 "F" (cons "Magit fetch" #'magit-fetch)
 "L" (cons "Magit buffer log" #'magit-log-buffer-file)
 "S" (cons "Git stage file"  #'magit-stage-file)
 "U" (cons "Git unstage file" #'magit-unstage-file))


;;;;; Leader keys

(general-def
  :keymaps '(emacs insert normal)
  :prefix-map 'athame-leader-map
  :global-prefix "C-c f"
  :non-normal-prefix "M-SPC"
  :prefix "SPC")

(general-def
  :keymaps '(emacs insert normal)
  :prefix-map 'athame-localleader-map
  :global-prefix "C-c f m"
  :non-normal-prefix "M-SPC m"
  :prefix "SPC m")

(general-define-key ; TODO: fill this out
 :prefix-map 'athame-tool-map
 "p" (cons "profiler" (make-keymap))
 "p p" (cons "Profiler start" #'profiler-start)
 "p s" (cons "Profiler stop" #'profiler-stop)
 "p r" (cons "Profiler report" #'profile-report)

 "f" (cons "Flycheck" #'flycheck-mode))

(general-def
  :prefix-map 'athame-leader-map
  "b" (cons "buffer" athame-buffer-prefix-map)
  "c" (cons "code" athame-code-prefix-map)
  "f" (cons "file" athame-file-prefix-map)
  "g" (cons "git" athame-git-prefix-map)
  "h" (cons "help" help-map)
  "p" (cons "project" athame-project-prefix-map)
  "s" (cons "search" athame-search-prefix-map)
  "w" (cons "window" #'evil-window-map)
  "T" (cons "tool" athame-tool-map)

  "'" (cons "Repeat last search" #'vertico-repeat)
  "u" (cons "Universal argument" #'universal-argument)
  ";" (cons "Eval expression" #'pp-eval-expression)
  ":" (cons "M-x" #'execute-extended-command)
  "," (cons "Switch buffer" #'switch-to-buffer)
  "." (cons "Find file" #'find-file)
  "RET" (cons "Jump to bookmark" #'bookmark-jump))
