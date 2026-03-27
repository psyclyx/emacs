;;; psyc-completion.el --- Completion framework -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

;;;; CRM indicator fix

(defun psyc-completion--crm-indicator-a (args)
  (cons (format "[CRM%s] %s"
                (string-replace "[ \t]*" "" crm-separator)
                (car args))
        (cdr args)))

(when (< emacs-major-version 31)
  (advice-add #'completing-read-multiple :filter-args
              #'psyc-completion--crm-indicator-a))

;;;; Cape (capf)

(defun psyc-cape--add-elisp-block-capf-h ()
  (add-hook 'completion-at-point-functions #'cape-elisp-block 0 t))

(defvar psyc-cape--buffer-scan-limit (* 1 1024 1024))

(defun psyc-cape--dabbrev-friendly-buffer (other-buffer)
  (< (buffer-size other-buffer) psyc-cape--buffer-scan-limit))

(use-package cape
  :defer 0.5
  :ghook
  ('(org-mode-hook markdown-mode-hook) #'psyc-cape--add-elisp-block-capf-h)

  :init
  (gsetq
   cape-dabbrev-check-other-buffers t
   dabbrev-friend-buffer-function #'psyc-cape--dabbrev-friendly-buffer
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

;;;; Corfu

;;;;; Commands

(defun psyc-corfu-move-to-minibuffer ()
  (interactive)
  (pcase completion-in-region--data
    (`(,beg ,end ,table ,pred ,extras)
     (let ((completion-extra-properties extras) completion-cycle-threshold completion-cycling)
       (consult-completion-in-region beg end table pred)))))

(defun psyc-corfu-smart-sep-toggle-escape ()
  "Insert `corfu-separator' or toggle escape if it's already there."
  (interactive)
  (cond ((and (char-equal (char-before) corfu-separator)
              (char-equal (char-before (1- (point))) ?\\))
         (save-excursion (delete-char -2)))
        ((char-equal (char-before) corfu-separator)
         (save-excursion (backward-char 1)
                         (insert-char ?\\)))
        (t (call-interactively #'corfu-insert-separator))))

(defun psyc-corfu-dabbrev-or-next (&optional arg)
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

(defun psyc-corfu-dabbrev-or-last (&optional arg)
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

;;;;; Predicates

(defun psyc-corfu--other-completion-active-p ()
  (or (bound-and-true-p vertico--input)
      (where-is-internal 'minibuffer-complete (list (current-local-map)))))

(defun psyc-corfu--enable-in-minibuffer-p ()
  (and (where-is-internal #'completion-at-point
                          (list (current-local-map)))
       (not (psyc-corfu--other-completion-active-p))))

;;;;; Packages

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
   global-corfu-minibuffer #'psyc-corfu--enable-in-minibuffer-p)

  :config
  (add-to-list 'corfu-continue-commands #'psyc-corfu-smart-sep-toggle-escape)
  (general-add-hook 'evil-insert-state-exit-hook (list #'corfu-quit #'corfu-popupinfo--hide))

  :general-config
  (:keymaps
   'corfu-mode-map
   :states 'insert
   "C-@" #'completion-at-point
   "C-SPC" #'completion-at-point
   "C-n" #'psyc-corfu-dabbrev-or-next
   "C-p" #'psyc-corfu-dabbrev-or-last)
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
   "C-SPC" #'psyc-corfu-smart-sep-toggle-escape
   "C-S-s" #'psyc-corfu-move-to-minibuffer
   "<deletechar>" #'corfu-reset)
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

;;;; Vertico

;;;;; Advice

(defun psyc-vertico--ffap-menu-ignore-comp-help-a (&rest args)
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
	      #'psyc-vertico--ffap-menu-ignore-comp-help-a)
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

;;;; Orderless

;;;;; Dispatchers

(defun psyc-orderless--dispatch (pattern _index _total)
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

(defun psyc-orderless--disambiguation-dispatch (pattern _index _total)
  (when (char-equal (aref pattern (1- (length pattern))) ?$)
    `(orderless-regexp . ,(concat (substring pattern 0 -1)
				  "[\x200000-\x300000]*$"))))

;;;;; Advice

(defun psyc-orderless--company-capf-candidates-a (fn &rest args)
  (let ((orderless-match-faces [completions-common-part])
        (completion-styles '(basic partial-completion orderless)))
    (apply fn args)))

;;;;; Package

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
         '(psyc-orderless--dispatch
           psyc-orderless--disambiguation-dispatch))

  (gsetq completion-styles '(orderless basic)
         completion-category-defaults nil
         completion-category-overrides '((file (styles orderless partial-completion))))

  :config
  (gsetq orderless-component-separator #'orderless-escapable-split-on-space)
  (advice-add 'company-capf--candidates :around #'psyc-orderless--company-capf-candidates-a)
  (set-face-attribute 'completions-first-difference nil :inherit nil))

;;;; Consult

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

;;;; Marginalia

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

(provide 'psyc-completion)
;;; psyc-completion.el ends here
