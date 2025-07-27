(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 50 1024 1024))))

(let ((default-directory (expand-file-name "lisp" user-emacs-directory)))
  (push default-directory load-path)
  (normal-top-level-add-subdirs-to-load-path))

(require 'athame-init)

(athame-init-ui)
