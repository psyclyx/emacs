;;; athame-theme.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

;;;; Modus theme
(setq modus-themes-italic-constructs t
      modus-themes-bold-constructs t
      modus-themes-mixed-fonts t
      modus-themes-variable-pitch-ui t
      modus-themes-disable-other-themes t
      modus-themes-prompts '(extrabold italic)
      modus-themes-headings '((1 . (variable-pitch 1.5))
                              (2 . (background 1.4))
                              (3 . (background 1.3))
                              (4 . (background 1.2))
                              (t . (background 1.1)))
      x-underline-at-descent-line t)

(require-theme 'modus-themes)
(defun athame-theme--modus-themes-custom-faces (&rest _)
    (modus-themes-with-colors
     (custom-set-faces
      `(mode-line ((,c :box (:line-width (16 . 10)  :style flat-button))))
      `(mode-line-inactive ((,c :box (:line-width (16 . 10) :style flat-button)))))))

(add-hook 'modus-themes-after-load-theme-hook #'athame-theme--modus-themes-custom-faces)

(modus-themes-load-theme 'modus-vivendi-tinted)

;;;; Fonts
(use-package faces
  :ensure nil
  :custom
  (face-font-family-alternatives
   '(("Berkeley Mono" "Aporetic Sans Mono" "Noto Sans Mono" "SF Mono" "Menlo" "Monospace")
     ("Aporetic Sans" "Noto Sans" "Noto Sans" "SF Pro" "Helvetica" "Arial")))
  :config
  (set-face-attribute 'default nil
                      :family "Berkeley Mono"
                      :height 180
                      :weight 'extra-light
                      :width 'condensed)

  (set-face-attribute 'fixed-pitch nil
                      :family "Berkeley Mono")

  (set-face-attribute 'variable-pitch nil
                      :family "Aporetic Sans"))

;;;; Icons
(use-package nerd-icons)

;;; Provide
(provide 'athame-theme)
;;; athame-theme.el ends here
