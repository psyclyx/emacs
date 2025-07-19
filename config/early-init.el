(setq package-enable-at-startup nil)

(push (expand-file-name "lisp" user-emacs-directory) load-path)

(require 'psyclyx-init)
