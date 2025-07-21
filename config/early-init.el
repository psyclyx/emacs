(let ((default-directory (expand-file-name "lisp" user-emacs-directory)))
  (push default-directory load-path)
  (normal-top-level-add-subdirs-to-load-path))

(require 'athame-init)

(athame-init-ui)
