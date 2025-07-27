;;; athame-help.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(require 'cl-lib)

(use-package apropos
  :ensure nil
  :custom
  (apropos-do-all t))

(use-package helpful
  :defer t)

(general-def
  [remap describe-function] #'helpful-callable
  [remap describe-command]  #'helpful-command
  [remap describe-variable] #'helpful-variable
  [remap describe-key]      #'helpful-key
  [remap describe-symbol]   #'helpful-symbol)

;;;; Which-key
(use-package which-key
  :custom
  (which-key-allow-multiple-replacements t)
  (which-key-sort-order #'which-key-key-order-alpha)
  (which-key-sort-uppercase-first nil)
  (which-key-add-column-padding 1)
  (which-key-max-display-columns nil)
  (which-key-min-display-lines 6)
  (which-key-side-window-slot -10)
  (which-key-idle-delay 0.3)
  (which-key-idle-secondary-delay 0.1)
  (which-key-allow-evil-operators t)
  (which-key-ashow-operator-state-maps t)
  :config
  (which-key-mode)
  (which-key-setup-side-window-bottom))

;;; Provide
(provide 'athame-help)
;;; athame-help.el ends here
