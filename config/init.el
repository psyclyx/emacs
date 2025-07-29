(dolist (it '("lisp" "lisp/core" "lisp/lang" "lisp/completion" "lisp/tool"))
  (push (expand-file-name it user-emacs-directory) load-path))

(require 'athame)
