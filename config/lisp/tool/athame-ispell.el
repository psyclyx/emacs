;;; athame-ispell.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(use-package ispell
  :defer t
  :init
  (gsetq ispell-program-name "aspell"))

(provide 'athame-ispell)
;;; athame-ispell.el ends here
