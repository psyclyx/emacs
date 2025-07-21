;;; athame-parens.el --- foo -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:
(use-package smartparens
  :hook (after-init . smartparens-global-mode)

  :custom
  (sp-highlight-pair-overlay nil)
  (sp-highlight-wrap-overlay nil)
  (sp-highlight-wrap-tag-overlay nil)
  (sp-show-pair-from-inside t)
  (sp-cancel-autoskip-on-backward-movement nil)
  (sp-max-prefix-length 25)
  (sp-max-pair-length 4)

  :config
  (smartparens-global-mode)
  (add-to-list 'sp-lisp-modes 'sly-mrepl-mode)
  (require 'smartparens-config)
  (setq sp-pair-overlay-keymap (make-sparse-keymap))

  ;; Silence some harmless but annoying echo-area spam
  (dolist (key '(:unmatched-expression :no-matching-tag))
    (setf (alist-get key sp-message-alist) nil))

  (add-hook 'eval-expression-minibuffer-setup-hook
            (defun athame-parens--init-smartparens-in-eval-expression-h ()
              (when smartparens-global-mode (smartparens-mode +1))))

  (add-hook 'minibuffer-setup-hook
            (defun athame-parens--init-smartparens-in-minibuffer-maybe-h ()
              (when (and smartparens-global-mode (memq this-command '(evil-ex)))
                (smartparens-mode +1))))

  (sp-local-pair '(minibuffer-mode minibuffer-inactive-mode) "'" nil :actions nil)
  (sp-local-pair '(minibuffer-mode minibuffer-inactive-mode) "`" nil :actions nil))

;;;; Provide
(provide 'athame-parens)
;;; athame-parens.el ends here
