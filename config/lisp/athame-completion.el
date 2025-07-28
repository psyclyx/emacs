;;; athame-completion.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

;;;; Corfu
(defun athame-corfu--move-to-minibuffer ()
  (interactive)
  (pcase completion-in-region--data
    (`(,beg ,end ,table ,pred ,extras)
     (let ((completion-extra-properties extras)
           completion-cycle-threshold completion-cycling)
       (consult-completion-in-region beg end table pred)))))

(defun athame-corfu--smart-sep-toggle-escape ()
  "Insert `corfu-separator' or toggle escape if it's already there."
  (interactive)
  (cond ((and (char-equal (char-before) corfu-separator)
              (char-equal (char-before (1- (point))) ?\\))
         (save-excursion (delete-char -2)))
        ((char-equal (char-before) corfu-separator)
         (save-excursion (backward-char 1)
                         (insert-char ?\\)))
        (t (call-interactively #'corfu-insert-separator))))

(defun athame-corfu--dabbrev-this-buffer ()
  "Like `cape-dabbrev', but only scans current buffer."
  (interactive)
  (require 'cape)
  (let ((cape-dabbrev-check-other-buffers nil))
    (cape-dabbrev t)))

(defun athame-corfu--dabbrev-or-next (&optional arg)
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

(defun athame-corfu--dabbrev-or-last (&optional arg)
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

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.24)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-count 16)
  (corfu-max-width 120)
  (corfu-on-exact-match nil)
  (corfu-quit-at-boundary 'separator)
  (corfu-quit-no-match corfu-quit-at-boundary)
  (tab-always-indent 'complete)
  :config
  (global-corfu-mode)
  (add-to-list 'corfu-continue-commands #'athame-corfu--move-to-minibuffer)
  (add-to-list 'corfu-continue-commands #'athame-corfu--smart-sep-toggle-escape)
  (add-to-list 'completion-category-overrides `(lsp-capf (styles ,@completion-styles)))
  (add-hook 'evil-insert-state-exit-hook #'corfu-quit)
  (add-to-list 'corfu-continue-commands #'athame-corfu--smart-sep-toggle-escape)

  (defun athame-corfu--other-completion-active-p ()
    (or (bound-and-true-p vertico--input)
        (where-is-internal 'minibuffer-complete (list (current-local-map)))))

  (defun athame-corfu--enable-in-minibuffer-p ()
    (and (where-is-internal #'completion-at-point
                            (list (current-local-map)))
         (not (athame-corfu--other-completion-active-p))))

  (setq global-corfu-minibuffer #'athame-corfu--enable-in-minibuffer-p))


(defvar athame-corfu-buffer-scanning-size-limit (* 1 1024 1024))

(use-package corfu-history
  :hook corfu-mode
  :config
  (with-eval-after-load 'savehist
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(use-package corfu-popupinfo
  :hook corfu-mode
  :config
  (setq corfu-popupinfo-delay '(0.24 . 0.6)))

(use-package nerd-icons-corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

;;;; Cape
(use-package cape
  :custom
  (cape-dabbrev-check-other-buffers t)
  :init
  (general-def
    :prefix "C-c p"
    "p" #'completion-at-point
    "a" #'cape-abbrev
    "b" #'cape-elisp-block
    "d" #'cape-dabbrev
    "e" #'cape-elisp-symbol
    "E" #'cape-emoji
    "D" #'cape-dict
    "h" #'cape-history
    "t" #'cape-keyword
    "l" #'cape-line
    "r" #'cape-rfc1345
    "s" #'cape-sgml
    "t" #'cape-tex)

  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  (add-to-list 'completion-at-point-functions #'cape-file)

  (defun athame-corfu-add-cape-elisp-block-h ()
    (add-hook 'completion-at-point-functions #'cape-elisp-block 0 t))
  (athame-add-hooks '(org-mode-hook markdown-mode-hook) #'athame-corfu-add-cape-elisp-block-h)

  (defun athame-corfu-dabbrev-friend-buffer-p (other-buffer)
    (< (buffer-size other-buffer) athame-corfu-buffer-scanning-size-limit))

  (setq dabbrev-friend-buffer-function #'athame-corfu-dabbrev-friend-buffer-p
        dabbrev-ignored-buffer-regexps
        '("\\` "
          "\\(?:\\(?:[EG]?\\|GR\\)TAGS\\|e?tags\\|GPATH\\)\\(<[0-9]+>\\)?")
        dabbrev-upcase-means-case-search t)

  (advice-add #'comint-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'eglot-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'pcomplete-completions-at-point :around #'cape-wrap-nonexclusive))

;;;; Vertico

(use-package vertico
  :custom
  (vertico-cycle t)
  (vertico-count 20)
  (vertico-resize t)

  :config
  (vertico-mode)
  (general-def
    :keymaps 'vertico-map
    "M-j" 'next-line
    "M-k" 'previous-line
    "M-h" 'backward-paragraph
    "M-l" 'forward-paragraph)

  ;; Prompt indicator for `completing-read-multiple'.
  (when (< emacs-major-version 31)
    (advice-add #'completing-read-multiple :filter-args
                (lambda (args)
                  (cons (format "[CRM%s] %s"
                                (string-replace "[ \t]*" "" crm-separator)
                                (car args))
                        (cdr args))))))

(require 'vertico-buffer)
(require 'vertico-grid)
(require 'vertico-directory)
(require 'vertico-reverse)
(require 'vertico-repeat)
(require 'vertico-multiform)

(add-hook 'rfn-esm-update-handlers #'vertico-directory-tidy)

(general-def
  :keymaps '(vertico-map vertico-mulltiform-map)
  "RET" 'vertico-directory-enter
  "DEL" 'vertico-directory-delete-char
  "M-DEL" 'vertico-directory-delete-word)

(setq vertico-buffer-display-action '(display-buffer-use-least-recent-window)
      vertico-multiform-categories '((embark-keybinding grid)))

(vertico-multiform-mode)

(add-hook 'minibuffer-setup-hook #'vertico-repeat-save)

(general-def
  :states '(normal insert visual motion)
  "C-M-;" 'vertico-repeat)

(advice-add #'ffap-menu-ask :around
            (lambda (&rest args)
              (cl-letf (((symbol-function #'minibuffer-completion-help)
                         #'ignore))
                (apply args))))

;;;; Orderless
(defun athame-vertico--orderless-dispatch (pattern _index _total)
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


(defun athame-vertico--orderless-disambiguation-dispatch (pattern _index _total)
  (when (char-equal (aref pattern (1- (length pattern))) ?$)
    `(orderless-regexp . ,(concat (substring pattern 0 -1) "[\x200000-\x300000]*$"))))


(use-package orderless
  :config
  (defun athame-vertico--company-capf--candidates-a (fn &rest args)
    (let ((orderless-match-faces [completions-common-part])
          (completion-styles '(basic partial-completion orderless)))
      (apply fn args)))
  (advice-add 'company-capf--candidates :around #'athame-vertico--company-capf--candidates-a)

  (setq orderless-affix-dispatch-alist
        '((?! . orderless-without-literal)
          (?& . orderless-annotation)
          (?% . char-fold-to-regexp)
          (?` . orderless-initialism)
          (?= . orderless-literal)
          (?^ . orderless-literal-prefix)
          (?~ . orderless-flex))
        orderless-style-dispatchers
        '(athame-vertico--orderless-dispatch
          athame-vertico--orderless-disambiguation-dispatch))

  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        ;; note that despite override in the name orderless can still be used in
        ;; find-file etc.
        completion-category-overrides '((file (styles orderless partial-completion)))
        orderless-component-separator #'orderless-escapable-split-on-space)
  ;; ...otherwise find-file gets different highlighting than other commands
  (set-face-attribute 'completions-first-difference nil :inherit nil))

;;;; Consult
(use-package consult
  :init
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)

  :config
  (general-def
    [remap bookmark-jump]                 #'consult-bookmark
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

  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  (consult-customize
   consult-theme :preview-key '(:debounce 0.1 any)
   consult-ripgrep consult-git-grep consult-grep consult-man
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   :preview-key '(:debounce 0.3 any))

  (setq consult-narrow-key "<"
        consult-line-numbers-width t
        consult-async-min-input 2
        consult-async-refresh-delay  0.15
        consult-async-input-throttle 0.2
        consult-async-input-debounce 0.1)

  (setq evil-jumps-cross-buffers nil)
  (evil-set-command-property 'consult-line :jump t)
  (general-def
    :keymaps 'vertico-map
    "C-x C-d" #'consult-dir
    "C-x C-j" #'consult-dir-jump-file)

  (consult-customize
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file
   consult--source-recent-file consult--source-project-recent-file consult--source-bookmark
   :preview-key "C-SPC"))

;;;; Marginalia
(use-package marginalia
  :custom
  (marginalia-max-relative-age 0)
  :config
  (marginalia-mode)
  (add-to-list 'marginalia-prompt-categories '("\\<face\\>" . face))
  (add-to-list 'marginalia-prompt-categories '("\\<var\\>" . variable)))


(use-package nerd-icons-completion
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

;;; Provide
(provide 'athame-completion)
;;; athame-completion.el ends here
