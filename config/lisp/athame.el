;;; athame.el --- foo -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;;;; Custom
(defgroup athame nil
  "Configuration for athame's emacs config."
  :prefix "athame-")

;;;;; Data directories
(defcustom athame-cache-dir "~/.cache/emacs"
  "Location for cache files."
  :type '(directory))

(defcustom athame-state-dir "~/.local/state/emacs"
  "Location for state diles"
  :type '(directory))

;;;;; Leader binds
(defcustom athame-leader-key "SPC"
  "Leader key"
  :type '(key))

(defcustom athame-leader-alt-key "M-SPC"
  "Alternate leader key"
  :type '(key))

(defcustom athame-localleader-key "SPC m"
  "Localleader key"
  :type '(key))

(defcustom athame-localleader-alt-key "M-SPC m"
  "Alternate localleader key"
  :type '(key))

;;;; Key definers
(defvar athame-leader-key-states '(normal visual motion))
(defvar athame-leader-alt-key-states '(emacs insert))

(use-package general
  :config
  (general-create-definer defleader
    :keymaps 'override
    :states athame-leader-key-states
    :prefix athame-leader-key
    :non-normal-prefix athame-leader-alt-key)

  (general-create-definer deflocalleader
    :keymaps 'override
    :states athame-leader-key-states
    :prefix athame-localleader-key
    :non-normal-prefix athame-localleader-key)

  (general-override-mode +1))

;;;; Save variables
(use-package savehist
  :custom
  (savehist-file (file-name-concat athame-state-dir)))

;;;; Requires
(require 'athame-lib)
(require 'athame-ui)
(require 'athame-file)
(require 'athame-editor)
(require 'athame-help)
(require 'athame-evil)
(require 'athame-completion)

(require 'athame-compile)
(require 'athame-format)
(require 'athame-lsp)
(require 'athame-parens)
(require 'athame-project)
(require 'athame-treesit)
(require 'athame-vc)

(require 'athame-lang-nix)

(require 'athame-bindings)

;;;; Provide
(provide 'athame)
;;; athame.el ends here
