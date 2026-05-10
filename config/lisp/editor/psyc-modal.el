;;; psyc-modal.el --- Helix-inspired modal editing -*- lexical-binding: t -*-

;;; Commentary:
;;
;; Selection-first modal editing inspired by Helix, with a god-mode escape
;; hatch for modifier-free access to all of Emacs.
;;
;; Paradigm: select first, then act.  Movements create selections (Emacs
;; regions); actions like `d', `c', `y' consume them.  This is the opposite
;; of Vim's verb-object model and matches Helix/Kakoune.
;;
;; States:
;;   Normal  [N] — movements create fresh selections, keys run commands
;;   Select  [S] — movements extend the existing selection (toggle with v)
;;   Insert  [I] — regular Emacs editing, escape returns to normal
;;
;; God-mode: press `,` in normal mode to type Emacs key sequences without
;; holding modifiers.  `g` prefix means Meta, `G` means C-M-, SPC sends
;; the next key literally.

;;; Code:

(require 'cl-lib)

(autoload 'psyc-tutor "psyc-tutor" "Interactive psyc-modal trainer." t)
(autoload 'psyc-tutor-quick-reference "psyc-tutor"
  "Quick reference for psyc-modal editing patterns." t)

;;;; --- Customization ---

(defgroup psyc-modal nil
  "Helix-inspired modal editing."
  :group 'editing)

(defvar psyc-modal-excluded-modes
  '(special-mode dired-mode term-mode vterm-mode eshell-mode)
  "Major modes where `psyc-modal-mode' should not activate.
`special-mode' covers magit, help, compilation, org-agenda, info, etc.")

;;;; --- State ---

(defvar-local psyc-modal--state 'normal)
(defvar-local psyc-modal--normal-p nil)
(defvar-local psyc-modal--insert-p nil)
(defvar psyc-modal--last-search nil "Cons (STRING . REGEXP-P) of last search.")

;;;; --- Keymaps ---

(defvar psyc-modal-normal-map (make-sparse-keymap) "Normal/select state keymap.")
(defvar psyc-modal-insert-map (make-sparse-keymap) "Insert state keymap.")
(defvar psyc-modal-goto-map   (make-sparse-keymap "Goto"))
(defvar psyc-modal-match-map  (make-sparse-keymap "Match"))
(defvar psyc-modal-space-map  (make-sparse-keymap "Space"))
(defvar psyc-modal-help-map   (make-sparse-keymap "Help"))
(defvar psyc-modal-window-map (make-sparse-keymap "Window"))
(defvar psyc-modal-view-map   (make-sparse-keymap "View"))

(defvar psyc-modal--emu-alist nil)

;;;; --- Mode ---

(defun psyc-modal--lighter ()
  (pcase psyc-modal--state
    ('normal " [N]") ('select " [S]") ('insert " [I]")))

(define-minor-mode psyc-modal-mode
  "Helix-inspired modal editing."
  :lighter (:eval (psyc-modal--lighter))
  (if psyc-modal-mode
      (progn
        (setq psyc-modal--emu-alist
              `((psyc-modal--normal-p . ,psyc-modal-normal-map)
                (psyc-modal--insert-p . ,psyc-modal-insert-map)))
        (cl-pushnew 'psyc-modal--emu-alist emulation-mode-map-alists)
        (psyc-modal-enter-normal))
    (setq psyc-modal--normal-p nil psyc-modal--insert-p nil
          psyc-modal--emu-alist nil cursor-type 'box)
    (deactivate-mark)))

(define-globalized-minor-mode psyc-modal-global-mode psyc-modal-mode
  (lambda ()
    (unless (or (minibufferp)
                (apply #'derived-mode-p psyc-modal-excluded-modes))
      (psyc-modal-mode 1))))

;;;; --- State transitions ---

(defvar psyc-modal-state-change-hook nil
  "Hook run after state changes, called with the new state symbol.")

(defun psyc-modal-enter-normal ()
  "Enter normal state."
  (interactive)
  (when (and (eq psyc-modal--state 'insert) (not (bolp)))
    (backward-char))
  (setq psyc-modal--state 'normal
        psyc-modal--normal-p t
        psyc-modal--insert-p nil
        cursor-type 'box)
  (deactivate-mark)
  (run-hook-with-args 'psyc-modal-state-change-hook 'normal))

(defun psyc-modal-enter-insert ()
  "Enter insert state."
  (interactive)
  (setq psyc-modal--state 'insert
        psyc-modal--normal-p nil
        psyc-modal--insert-p t
        cursor-type '(bar . 2))
  (deactivate-mark)
  (run-hook-with-args 'psyc-modal-state-change-hook 'insert))

(defun psyc-modal-enter-select ()
  "Toggle select state.  Movements extend rather than replace selection."
  (interactive)
  (if (eq psyc-modal--state 'select)
      (progn (setq psyc-modal--state 'normal cursor-type 'box)
             (deactivate-mark))
    (setq psyc-modal--state 'select cursor-type 'hollow)
    (unless (region-active-p) (set-mark (point))))
  (run-hook-with-args 'psyc-modal-state-change-hook psyc-modal--state))

;;;; --- Movement core ---

(defun psyc-modal--move (fn &rest args)
  "Execute FN as a movement.  Normal: fresh selection.  Select: extend."
  (if (eq psyc-modal--state 'select)
      (unless (region-active-p) (set-mark (point)))
    (set-mark (point)))
  (apply fn args))

(defmacro psyc-modal--defmove (name doc &rest body)
  "Define a movement command that creates/extends selection."
  (declare (indent 2) (doc-string 2))
  `(defun ,name ()
     ,doc
     (interactive)
     (psyc-modal--move (lambda () ,@body))))

;;;; --- Basic movements ---

(psyc-modal--defmove psyc-modal-left  "Move left (h)."
  (backward-char (prefix-numeric-value current-prefix-arg)))
(psyc-modal--defmove psyc-modal-down  "Move down (j)."
  (forward-line (prefix-numeric-value current-prefix-arg)))
(psyc-modal--defmove psyc-modal-up    "Move up (k)."
  (forward-line (- (prefix-numeric-value current-prefix-arg))))
(psyc-modal--defmove psyc-modal-right "Move right (l)."
  (forward-char (prefix-numeric-value current-prefix-arg)))

;;;; --- Word movements ---

(psyc-modal--defmove psyc-modal-word-next "Next word start (w)."
  (dotimes (_ (prefix-numeric-value current-prefix-arg))
    (cond
     ((looking-at-p "\\sw\\|\\s_") (skip-syntax-forward "w_"))
     ((not (looking-at-p "\\s-\\|\n")) (skip-syntax-forward "^w_ \t\n")))
    (skip-chars-forward " \t\n")))

(psyc-modal--defmove psyc-modal-word-end "Word end (e)."
  (dotimes (_ (prefix-numeric-value current-prefix-arg))
    (forward-char)
    (skip-chars-forward " \t\n")
    (if (looking-at-p "\\sw\\|\\s_")
        (progn (skip-syntax-forward "w_") (backward-char))
      (when (not (eobp))
        (skip-syntax-forward "^w_ \t\n") (backward-char)))))

(psyc-modal--defmove psyc-modal-word-back "Previous word start (b)."
  (dotimes (_ (prefix-numeric-value current-prefix-arg))
    (skip-chars-backward " \t\n")
    (when (> (point) (point-min))
      (backward-char)
      (if (looking-at-p "\\sw\\|\\s_")
          (skip-syntax-backward "w_")
        (skip-syntax-backward "^w_ \t\n")))))

(psyc-modal--defmove psyc-modal-WORD-next "Next WORD start (W)."
  (dotimes (_ (prefix-numeric-value current-prefix-arg))
    (skip-chars-forward "^ \t\n")
    (skip-chars-forward " \t\n")))

(psyc-modal--defmove psyc-modal-WORD-end "WORD end (E)."
  (dotimes (_ (prefix-numeric-value current-prefix-arg))
    (forward-char)
    (skip-chars-forward " \t\n")
    (skip-chars-forward "^ \t\n")
    (unless (eobp) (backward-char))))

(psyc-modal--defmove psyc-modal-WORD-back "Previous WORD start (B)."
  (dotimes (_ (prefix-numeric-value current-prefix-arg))
    (skip-chars-backward " \t\n")
    (skip-chars-backward "^ \t\n")))

;;;; --- Find / till ---

(defun psyc-modal-find-forward ()
  "Find character forward, inclusive (f)."
  (interactive)
  (let ((ch (read-char "f>")))
    (psyc-modal--move
     (lambda ()
       (let ((pos (save-excursion
                    (forward-char)
                    (search-forward (char-to-string ch) (line-end-position) t))))
         (if pos (goto-char (1- pos))
           (message "No %c on line" ch)))))))

(defun psyc-modal-till-forward ()
  "Find character forward, exclusive (t)."
  (interactive)
  (let ((ch (read-char "t>")))
    (psyc-modal--move
     (lambda ()
       (let ((pos (save-excursion
                    (forward-char)
                    (search-forward (char-to-string ch) (line-end-position) t))))
         (if pos (goto-char (- pos 2))
           (message "No %c on line" ch)))))))

(defun psyc-modal-find-backward ()
  "Find character backward, inclusive (F)."
  (interactive)
  (let ((ch (read-char "F>")))
    (psyc-modal--move
     (lambda ()
       (let ((pos (save-excursion
                    (search-backward (char-to-string ch) (line-beginning-position) t))))
         (if pos (goto-char pos)
           (message "No %c on line" ch)))))))

(defun psyc-modal-till-backward ()
  "Find character backward, exclusive (T)."
  (interactive)
  (let ((ch (read-char "T>")))
    (psyc-modal--move
     (lambda ()
       (let ((pos (save-excursion
                    (search-backward (char-to-string ch) (line-beginning-position) t))))
         (if pos (goto-char (1+ pos))
           (message "No %c on line" ch)))))))

;;;; --- Line operations ---

(defun psyc-modal-select-line ()
  "Select current line; repeat to extend downward (x)."
  (interactive)
  (if (and (eq last-command 'psyc-modal-select-line) (region-active-p))
      (forward-line)
    (set-mark (line-beginning-position))
    (forward-line)))

(defun psyc-modal-select-line-above ()
  "Extend line selection upward (X)."
  (interactive)
  (unless (region-active-p)
    (set-mark (line-beginning-position 2)))
  (forward-line -1))

(defun psyc-modal-join-lines ()
  "Join lines in selection, or current and next line (J)."
  (interactive)
  (if (use-region-p)
      (let ((count (count-lines (region-beginning) (region-end))))
        (goto-char (region-beginning))
        (deactivate-mark)
        (dotimes (_ (max 1 (1- count)))
          (delete-indentation 1)))
    (delete-indentation 1)))

;;;; --- Actions ---

(defun psyc-modal-delete ()
  "Delete selection, or char at point (d).  Saves to kill ring."
  (interactive)
  (if (use-region-p)
      (let ((len (- (region-end) (region-beginning))))
        (kill-region (region-beginning) (region-end))
        (message "Deleted %d chars" len))
    (delete-char 1)))

(defun psyc-modal-change ()
  "Delete selection and enter insert (c)."
  (interactive)
  (if (use-region-p)
      (kill-region (region-beginning) (region-end))
    (delete-char 1))
  (psyc-modal-enter-insert))

(defun psyc-modal-yank ()
  "Copy selection to kill ring (y)."
  (interactive)
  (when (use-region-p)
    (let ((len (- (region-end) (region-beginning))))
      (kill-ring-save (region-beginning) (region-end))
      (deactivate-mark)
      (message "Yanked %d chars" len))))

(defun psyc-modal-paste-after ()
  "Paste after cursor/selection (p)."
  (interactive)
  (when (use-region-p) (goto-char (region-end)))
  (deactivate-mark)
  (unless (eolp) (forward-char))
  (yank))

(defun psyc-modal-paste-before ()
  "Paste before cursor/selection (P)."
  (interactive)
  (when (use-region-p) (goto-char (region-beginning)))
  (deactivate-mark)
  (yank))

(defun psyc-modal-replace-paste ()
  "Replace selection with yanked text (R)."
  (interactive)
  (if (use-region-p)
      (progn (delete-region (region-beginning) (region-end)) (yank))
    (yank)))

(defun psyc-modal-replace-char ()
  "Replace char at point (or each char in selection) with prompted char (r)."
  (interactive)
  (let ((ch (read-char "r>")))
    (if (use-region-p)
        (let ((beg (region-beginning)) (end (region-end)))
          (deactivate-mark)
          (save-excursion
            (goto-char beg)
            (while (< (point) end)
              (if (eolp) (forward-char)
                (delete-char 1)
                (insert-char ch)))))
      (delete-char 1)
      (insert-char ch)
      (backward-char))))

(defun psyc-modal-toggle-case ()
  "Toggle case of selection or char at point (~)."
  (interactive)
  (let ((beg (if (use-region-p) (region-beginning) (point)))
        (end (if (use-region-p) (region-end) (1+ (point)))))
    (save-excursion
      (goto-char beg)
      (while (< (point) end)
        (let ((ch (char-after)))
          (delete-char 1)
          (insert-char (if (eq (upcase ch) ch) (downcase ch) (upcase ch))))))
    (deactivate-mark)))

(defun psyc-modal-indent ()
  "Indent selection or line (>)."
  (interactive)
  (let ((beg (if (use-region-p) (region-beginning) (line-beginning-position)))
        (end (if (use-region-p) (region-end) (line-end-position))))
    (indent-rigidly beg end tab-width)
    (deactivate-mark)))

(defun psyc-modal-dedent ()
  "Dedent selection or line (<)."
  (interactive)
  (let ((beg (if (use-region-p) (region-beginning) (line-beginning-position)))
        (end (if (use-region-p) (region-end) (line-end-position))))
    (indent-rigidly beg end (- tab-width))
    (deactivate-mark)))

(defun psyc-modal-reindent ()
  "Reindent selection or line (=)."
  (interactive)
  (if (use-region-p)
      (progn (indent-region (region-beginning) (region-end))
             (deactivate-mark))
    (indent-according-to-mode)))

;;;; --- Insert entry ---

(defun psyc-modal-insert-before ()
  "Insert before selection/cursor (i)."
  (interactive)
  (when (use-region-p) (goto-char (region-beginning)))
  (psyc-modal-enter-insert))

(defun psyc-modal-insert-after ()
  "Insert after selection/cursor (a)."
  (interactive)
  (if (use-region-p)
      (goto-char (region-end))
    (unless (eolp) (forward-char)))
  (psyc-modal-enter-insert))

(defun psyc-modal-insert-bol ()
  "Insert at first non-blank (I)."
  (interactive)
  (back-to-indentation)
  (psyc-modal-enter-insert))

(defun psyc-modal-insert-eol ()
  "Insert at end of line (A)."
  (interactive)
  (end-of-line)
  (psyc-modal-enter-insert))

(defun psyc-modal-open-below ()
  "Open line below (o)."
  (interactive)
  (end-of-line)
  (newline-and-indent)
  (psyc-modal-enter-insert))

(defun psyc-modal-open-above ()
  "Open line above (O)."
  (interactive)
  (beginning-of-line)
  (open-line 1)
  (indent-according-to-mode)
  (psyc-modal-enter-insert))

;;;; --- Search ---

(defun psyc-modal--after-isearch ()
  "Save last isearch string for n/N repeat."
  (when (and isearch-string (not (string-empty-p isearch-string)))
    (setq psyc-modal--last-search (cons isearch-string isearch-regexp))))

(add-hook 'isearch-mode-end-hook #'psyc-modal--after-isearch)

(defun psyc-modal-search-next ()
  "Go to next search match, selecting it (n)."
  (interactive)
  (pcase psyc-modal--last-search
    (`(,str . ,re-p)
     (let ((fn (if re-p #'re-search-forward #'search-forward)))
       (forward-char)
       (unless (funcall fn str nil t)
         (goto-char (point-min))
         (funcall fn str nil t))
       (when (match-beginning 0)
         (set-mark (match-beginning 0))
         (goto-char (match-end 0)))))
    (_ (message "No previous search"))))

(defun psyc-modal-search-prev ()
  "Go to previous search match, selecting it (N)."
  (interactive)
  (pcase psyc-modal--last-search
    (`(,str . ,re-p)
     (let ((fn (if re-p #'re-search-backward #'search-backward)))
       (unless (funcall fn str nil t)
         (goto-char (point-max))
         (funcall fn str nil t))
       (when (match-beginning 0)
         (set-mark (match-end 0))
         (goto-char (match-beginning 0)))))
    (_ (message "No previous search"))))

(defun psyc-modal-select-regex ()
  "Select regex matches within selection/buffer (s)."
  (interactive)
  (let* ((str (read-string "select: "))
         (beg (if (use-region-p) (region-beginning) (point-min)))
         (end (if (use-region-p) (region-end) (point-max))))
    (deactivate-mark)
    (goto-char beg)
    (when (re-search-forward str end t)
      (set-mark (match-beginning 0))
      (goto-char (match-end 0))
      (setq psyc-modal--last-search (cons str t)))))

;;;; --- Selection ---

(defun psyc-modal-collapse ()
  "Collapse selection to cursor (;)."
  (interactive)
  (deactivate-mark))

(defun psyc-modal-select-all ()
  "Select entire buffer (%)."
  (interactive)
  (push-mark (point-min) t t)
  (goto-char (point-max)))

(defun psyc-modal-flip-selection ()
  "Swap cursor and anchor of selection (Alt-;)."
  (interactive)
  (when (region-active-p)
    (exchange-point-and-mark)))

(defun psyc-modal-escape ()
  "Cancel selection, prefix arg, or escape."
  (interactive)
  (cond
   ((eq psyc-modal--state 'select) (psyc-modal-enter-normal))
   ((region-active-p) (deactivate-mark))
   (t (keyboard-quit))))

;;;; --- Sexp movements ---

(psyc-modal--defmove psyc-modal-forward-sexp "Forward sexp ()."
  (forward-sexp (prefix-numeric-value current-prefix-arg)))

(psyc-modal--defmove psyc-modal-backward-sexp "Backward sexp ((."
  (backward-sexp (prefix-numeric-value current-prefix-arg)))

;;;; --- Text objects (mi / ma) ---

(defun psyc-modal-select-inside ()
  "Select inside text object — brackets, quotes, words (mi)."
  (interactive)
  (let ((ch (read-char "inside:")))
    (psyc-modal--select-textobj ch nil)))

(defun psyc-modal-select-around ()
  "Select around text object — brackets, quotes, words (ma)."
  (interactive)
  (let ((ch (read-char "around:")))
    (psyc-modal--select-textobj ch t)))

(defun psyc-modal--select-textobj (ch around)
  "Dispatch text object selection based on CH."
  (pcase ch
    (?w                (psyc-modal--select-thing 'word around))
    (?W                (psyc-modal--select-thing 'symbol around))
    (?p                (psyc-modal--select-thing 'paragraph around))
    ((or ?\( ?\) ?b)   (psyc-modal--select-delimited ?\( around))
    ((or ?\[ ?\])      (psyc-modal--select-delimited ?\[ around))
    ((or ?{ ?} ?B)     (psyc-modal--select-delimited ?{ around))
    ((or ?< ?>)        (psyc-modal--select-delimited ?< around))
    (?\"               (psyc-modal--select-quotes ?\" around))
    (?\'               (psyc-modal--select-quotes ?\' around))
    (?`                (psyc-modal--select-quotes ?` around))
    (?m                (psyc-modal--select-nearest-pair around))
    (?f                (if around (psyc-modal-select-around-function)
                         (psyc-modal-select-inside-function)))
    (_                 (message "Unknown text object: %c" ch))))

(defun psyc-modal--select-thing (thing around)
  "Select THING at point.  If AROUND, include trailing whitespace."
  (when-let ((bounds (bounds-of-thing-at-point thing)))
    (let ((beg (car bounds)) (end (cdr bounds)))
      (when around
        (save-excursion (goto-char end) (skip-chars-forward " \t\n")
                        (setq end (point))))
      (set-mark beg)
      (goto-char end))))

(defun psyc-modal--select-delimited (open-ch around)
  "Select inside/around matching OPEN-CH pair, searching outward."
  (condition-case nil
      (let (beg end)
        (save-excursion
          (cl-loop
           (up-list -1 t t)
           (when (= (char-after) open-ch)
             (setq beg (point)) (cl-return))
           (when (bobp) (cl-return))))
        (when beg
          (save-excursion (goto-char beg) (forward-sexp) (setq end (point))))
        (when (and beg end)
          (if around
              (progn (set-mark beg) (goto-char end))
            (set-mark (1+ beg)) (goto-char (1- end)))))
    (scan-error nil)))

(defun psyc-modal--select-nearest-pair (around)
  "Select inside/around the nearest enclosing bracket pair of any type."
  (condition-case nil
      (let (beg end)
        (save-excursion
          (up-list -1 t t) (setq beg (point))
          (forward-sexp) (setq end (point)))
        (if around
            (progn (set-mark beg) (goto-char end))
          (set-mark (1+ beg)) (goto-char (1- end))))
    (scan-error nil)))

(defun psyc-modal--select-quotes (delim-ch around)
  "Select inside/around DELIM-CH quoted string."
  (let ((delim (char-to-string delim-ch))
        (pt (point)) beg end)
    (save-excursion
      (when (search-backward delim (line-beginning-position 0) t)
        (setq beg (point))))
    (save-excursion
      (goto-char (1+ pt))
      (when (search-forward delim (line-end-position 2) t)
        (setq end (point))))
    (when (and beg end)
      (if around
          (progn (set-mark beg) (goto-char end))
        (set-mark (1+ beg)) (goto-char (1- end))))))

;;;; --- Local leader ---

(defvar-local psyc-modal-local-map nil
  "Buffer-local keymap for mode-specific commands (SPC m).")

(defun psyc-modal-local-leader ()
  "Activate the buffer-local mode-specific keymap."
  (interactive)
  (if psyc-modal-local-map
      (set-transient-map psyc-modal-local-map)
    (message "No local commands for this mode")))

(defmacro psyc-modal-localleader (mode-hook desc &rest bindings)
  "Set up local leader for MODE-HOOK.
DESC is the keymap name.  BINDINGS are KEY CMD pairs."
  (declare (indent 2))
  (let ((fn-name (intern (format "psyc-modal--localleader-%s"
                                 (replace-regexp-in-string "-hook\\'" "" (symbol-name mode-hook))))))
    `(progn
       (defun ,fn-name ()
         (setq psyc-modal-local-map (make-sparse-keymap ,desc))
         ,@(cl-loop for (key cmd) on bindings by #'cddr
                    collect `(define-key psyc-modal-local-map ,key ,cmd))
         (psyc-modal--which-key-register-local-map))
       (add-hook ',mode-hook #',fn-name))))

;;;; --- Goto mode ---

(psyc-modal--defmove psyc-modal-goto-file-start "Go to file start (gg)."
  (goto-char (point-min)))

(psyc-modal--defmove psyc-modal-goto-file-end "Go to file end (ge)."
  (goto-char (point-max)))

(psyc-modal--defmove psyc-modal-goto-line-start "Go to line start (gh)."
  (beginning-of-line))

(psyc-modal--defmove psyc-modal-goto-line-end "Go to line end (gl)."
  (end-of-line))

(psyc-modal--defmove psyc-modal-goto-first-nonblank "Go to first non-blank (gs)."
  (back-to-indentation))

(psyc-modal--defmove psyc-modal-goto-window-top "Go to window top (gt)."
  (move-to-window-line 0))

(psyc-modal--defmove psyc-modal-goto-window-center "Go to window center (gc)."
  (move-to-window-line nil))

(psyc-modal--defmove psyc-modal-goto-window-bottom "Go to window bottom (gb)."
  (move-to-window-line -1))

(let ((m psyc-modal-goto-map))
  (define-key m "g" #'psyc-modal-goto-file-start)
  (define-key m "e" #'psyc-modal-goto-file-end)
  (define-key m "h" #'psyc-modal-goto-line-start)
  (define-key m "l" #'psyc-modal-goto-line-end)
  (define-key m "s" #'psyc-modal-goto-first-nonblank)
  (define-key m "t" #'psyc-modal-goto-window-top)
  (define-key m "c" #'psyc-modal-goto-window-center)
  (define-key m "b" #'psyc-modal-goto-window-bottom)
  (define-key m "d" #'xref-find-definitions)
  (define-key m "r" #'xref-find-references)
  (define-key m "n" #'next-buffer)
  (define-key m "p" #'previous-buffer))

;;;; --- Match mode (brackets + surround + structural editing) ---

(defun psyc-modal--char-pair (ch)
  "Return (OPEN . CLOSE) for CH."
  (pcase ch
    ((or ?\( ?\)) '("(" . ")"))
    ((or ?\[ ?\]) '("[" . "]"))
    ((or ?{ ?})   '("{" . "}"))
    ((or ?< ?>)   '("<" . ">"))
    (_ (let ((s (char-to-string ch))) (cons s s)))))

(defun psyc-modal-match-bracket ()
  "Jump to matching bracket (mm)."
  (interactive)
  (cond
   ((looking-at "\\s(")  (forward-sexp))
   ((looking-back "\\s)" 1) (backward-sexp))
   (t (when-let ((pos (save-excursion
                         (ignore-errors (up-list) (backward-sexp) (point)))))
        (goto-char pos)))))

(defun psyc-modal-surround-add ()
  "Surround selection with char pair (ms)."
  (interactive)
  (when (use-region-p)
    (let* ((ch (read-char "surround:"))
           (pair (psyc-modal--char-pair ch))
           (beg (region-beginning))
           (end (region-end)))
      (deactivate-mark)
      (goto-char end) (insert (cdr pair))
      (goto-char beg) (insert (car pair))
      (message "Surrounded with %s…%s" (car pair) (cdr pair)))))

(defun psyc-modal-surround-delete ()
  "Delete nearest surrounding pair (md)."
  (interactive)
  (let* ((ch (read-char "delete surround:"))
         (pair (psyc-modal--char-pair ch)))
    (save-excursion
      (when-let ((end-pos (save-excursion
                            (search-forward (cdr pair) nil t))))
        (when-let ((beg-pos (save-excursion
                              (search-backward (car pair) nil t))))
          (goto-char (1- end-pos)) (delete-char (length (cdr pair)))
          (goto-char beg-pos) (delete-char (length (car pair)))
          (message "Deleted %s…%s" (car pair) (cdr pair)))))))

(defun psyc-modal-surround-replace ()
  "Replace surrounding pair (mr)."
  (interactive)
  (let* ((from (read-char "replace surround:"))
         (to   (read-char (format "with:")))
         (old  (psyc-modal--char-pair from))
         (new  (psyc-modal--char-pair to)))
    (save-excursion
      (when-let ((end-pos (save-excursion
                            (search-forward (cdr old) nil t))))
        (when-let ((beg-pos (save-excursion
                              (search-backward (car old) nil t))))
          (goto-char (1- end-pos))
          (delete-char (length (cdr old))) (insert (cdr new))
          (goto-char beg-pos)
          (delete-char (length (car old))) (insert (car new))
          (message "Replaced %s…%s with %s…%s"
                   (car old) (cdr old) (car new) (cdr new)))))))

;;;;; Structural editing (built-in, no smartparens needed)

(defun psyc-modal-slurp-forward ()
  "Grow the closing delimiter to include the next sexp (m))."
  (interactive)
  (save-excursion
    (up-list) (let ((close (char-before)))
      (delete-char -1)
      (forward-sexp)
      (insert close))))

(defun psyc-modal-barf-forward ()
  "Shrink the closing delimiter, pushing last sexp out (m})."
  (interactive)
  (save-excursion
    (up-list) (let ((close (char-before)))
      (delete-char -1)
      (backward-sexp)
      (skip-chars-backward " \t\n")
      (insert close))))

(defun psyc-modal-slurp-backward ()
  "Grow the opening delimiter to include the preceding sexp (m()."
  (interactive)
  (save-excursion
    (up-list -1) (let ((open (char-after)))
      (delete-char 1)
      (backward-sexp)
      (insert open))))

(defun psyc-modal-barf-backward ()
  "Shrink the opening delimiter, pushing first sexp out (m{)."
  (interactive)
  (save-excursion
    (up-list -1) (let ((open (char-after)))
      (delete-char 1)
      (forward-sexp)
      (skip-chars-forward " \t\n")
      (insert open))))

(defun psyc-modal-splice ()
  "Remove enclosing delimiters, keeping contents (mS)."
  (interactive)
  (let (beg end)
    (save-excursion
      (up-list -1) (setq beg (point))
      (forward-sexp) (setq end (point)))
    (save-excursion
      (goto-char (1- end)) (delete-char 1)
      (goto-char beg) (delete-char 1))))

(defun psyc-modal-raise ()
  "Replace parent sexp with sexp at point (mR)."
  (interactive)
  (let ((sexp (buffer-substring-no-properties
               (save-excursion (backward-sexp) (point)) (point)))
        beg end)
    (save-excursion
      (up-list -1) (setq beg (point))
      (forward-sexp) (setq end (point)))
    (delete-region beg end)
    (goto-char beg)
    (insert sexp)))

(defun psyc-modal-transpose-sexp ()
  "Swap sexp at point with the next one (mT)."
  (interactive)
  (transpose-sexps 1))

(defun psyc-modal-wrap ()
  "Wrap sexp at point with prompted pair (mw)."
  (interactive)
  (let* ((ch (read-char "wrap:"))
         (pair (psyc-modal--char-pair ch)))
    (if (use-region-p)
        (let ((beg (region-beginning)) (end (region-end)))
          (deactivate-mark)
          (goto-char end) (insert (cdr pair))
          (goto-char beg) (insert (car pair)))
      (save-excursion
        (insert (car pair))
        (forward-sexp)
        (insert (cdr pair))))))

(let ((m psyc-modal-match-map))
  ;; Bracket matching
  (define-key m "m" #'psyc-modal-match-bracket)
  ;; Surround
  (define-key m "s" #'psyc-modal-surround-add)
  (define-key m "d" #'psyc-modal-surround-delete)
  (define-key m "r" #'psyc-modal-surround-replace)
  (define-key m "w" #'psyc-modal-wrap)
  ;; Text objects
  (define-key m "i" #'psyc-modal-select-inside)
  (define-key m "a" #'psyc-modal-select-around)
  ;; Structural editing (slurp/barf/splice/raise)
  (define-key m ")" #'psyc-modal-slurp-forward)
  (define-key m "(" #'psyc-modal-slurp-backward)
  (define-key m "}" #'psyc-modal-barf-forward)
  (define-key m "{" #'psyc-modal-barf-backward)
  (define-key m "S" #'psyc-modal-splice)
  (define-key m "R" #'psyc-modal-raise)
  (define-key m "T" #'psyc-modal-transpose-sexp))

;;;; --- Window mode ---

(let ((m psyc-modal-window-map))
  (define-key m "s" #'split-window-below)
  (define-key m "v" #'split-window-right)
  (define-key m "h" #'windmove-left)
  (define-key m "j" #'windmove-down)
  (define-key m "k" #'windmove-up)
  (define-key m "l" #'windmove-right)
  (define-key m "H" #'windmove-swap-states-left)
  (define-key m "J" #'windmove-swap-states-down)
  (define-key m "K" #'windmove-swap-states-up)
  (define-key m "L" #'windmove-swap-states-right)
  (define-key m "q" #'delete-window)
  (define-key m "o" #'delete-other-windows)
  (define-key m "=" #'balance-windows)
  (define-key m "w" #'other-window)
  (define-key m "f" #'find-file-other-window))

;;;; --- View mode ---

(defvar psyc-modal-view-sticky-map (make-sparse-keymap "View (sticky)")
  "Sticky view mode: stays active until escape.")

(let ((m psyc-modal-view-map))
  (define-key m "z" #'recenter-top-bottom)
  (define-key m "c" #'recenter-top-bottom)
  (define-key m "t" (lambda () (interactive) (recenter 0)))
  (define-key m "b" (lambda () (interactive) (recenter -1)))
  (define-key m "j" #'scroll-up-line)
  (define-key m "k" #'scroll-down-line)
  (define-key m "\C-f" #'scroll-up-command)
  (define-key m "\C-b" #'scroll-down-command)
  (define-key m "\C-d" #'scroll-up-command)
  (define-key m "\C-u" #'scroll-down-command))

;; Sticky view (Z) — same keys but stays active until escape
(let ((m psyc-modal-view-sticky-map))
  (define-key m "z" #'recenter-top-bottom)
  (define-key m "c" #'recenter-top-bottom)
  (define-key m "t" (lambda () (interactive) (recenter 0)))
  (define-key m "b" (lambda () (interactive) (recenter -1)))
  (define-key m "j" #'scroll-up-line)
  (define-key m "k" #'scroll-down-line)
  (define-key m [escape] #'ignore))

(defun psyc-modal-view-sticky ()
  "Enter sticky view mode (Z).  Stays active until escape."
  (interactive)
  (set-transient-map psyc-modal-view-sticky-map t)
  (message "view (sticky): z/c/t/b/j/k — ESC to exit"))

;;;; --- Frame / client management ---

(defun psyc-modal-quit-frame ()
  "Quit the current frame.  Calls `server-edit' for emacsclient
frames, `delete-frame' otherwise (or `save-buffers-kill-emacs' if
this is the last frame)."
  (interactive)
  (cond
   ((frame-parameter nil 'client) (server-edit))
   ((< 1 (length (frame-list))) (delete-frame))
   (t (save-buffers-kill-emacs))))

;;;; --- Space mode (leader) ---

(let ((m psyc-modal-space-map))
  (define-key m "f"   #'find-file)
  (define-key m "b"   #'switch-to-buffer)
  (define-key m "s"   #'save-buffer)
  (define-key m "w"   psyc-modal-window-map)
  (define-key m "/"   #'consult-ripgrep)
  (define-key m " "   #'execute-extended-command)
  (define-key m "?"   #'execute-extended-command)
  (define-key m "q"   #'quit-window)
  (define-key m "Q"   #'psyc-modal-quit-frame)
  (define-key m "d"   #'kill-current-buffer)
  (define-key m "c"   #'comment-dwim)
  (define-key m "k"   #'eldoc-doc-buffer)
  (define-key m "y"   #'clipboard-kill-ring-save)
  (define-key m "p"   #'clipboard-yank)
  (define-key m "R"   #'rename-visited-file)
  (define-key m "'"   #'vertico-repeat)
  (define-key m ";"   #'pp-eval-expression)
  (define-key m "i"   #'consult-imenu)
  (define-key m "l"   #'consult-line)
  (define-key m "a"   #'eglot-code-actions)
  (define-key m "r"   #'eglot-rename)
  (define-key m "e"   #'flymake-show-buffer-diagnostics)
  (define-key m "E"   #'flymake-show-project-diagnostics)
  (define-key m "h"   help-map)
  (define-key m "m"   #'psyc-modal-local-leader)
  ;; Helix space keys we were missing
  (define-key m "F"   #'project-find-file)
  (define-key m "j"   #'consult-mark)
  (define-key m "S"   #'consult-imenu-multi)
  (define-key m "D"   #'flymake-show-project-diagnostics)
  (define-key m "C"   #'comment-region)
  ;; Git (basic; enriched by psyc-vcs if loaded)
  (define-key m "gg"  #'magit-status)
  (define-key m "gb"  #'magit-blame-addition)
  (define-key m "gl"  #'magit-log-buffer-file)
  (define-key m "gf"  #'magit-find-file))

;;;; --- Help mode ---

(let ((m psyc-modal-help-map))
  (define-key m "?" #'psyc-tutor-quick-reference)
  (define-key m "t" #'psyc-tutor)
  (define-key m "k" #'psyc-modal-show-keys)
  (define-key m "m" #'which-key-show-major-mode))

;;;; --- God mode ---

(defun psyc-modal--god-modify (event mod)
  "Apply MOD (ctrl/meta/ctrl-meta) to EVENT."
  (event-convert-list
   (append (pcase mod
             ('ctrl '(control))
             ('meta '(meta))
             ('ctrl-meta '(control meta)))
           (list (event-basic-type event)))))

(defun psyc-modal--god-show-which-key (keymap desc)
  "Show which-key popup for KEYMAP with DESC as header, if available."
  (when (and (keymapp keymap) (fboundp 'which-key--show-keymap))
    (which-key--show-keymap desc keymap nil nil t)))

(defun psyc-modal--god-hide-which-key ()
  "Hide which-key popup if visible."
  (when (fboundp 'which-key--hide-popup)
    (which-key--hide-popup)))

(defun psyc-modal-god-execute ()
  "Execute a key sequence with implicit Control modifier.
Prefixes: `g' for Meta, `G' for C-M-, SPC for literal next key.
Shows which-key popup at prefix boundaries."
  (interactive)
  (let ((keys [])
        (mod 'ctrl)
        (literal nil))
    (unwind-protect
        (cl-block god
          (while t
            (let* ((desc (concat "god: "
                                 (pcase mod
                                   ('ctrl "C-") ('meta "M-") ('ctrl-meta "C-M-"))
                                 (key-description keys)))
                   (raw (read-event desc)))
              (cond
               ;; g/G prefix — switch modifier (only at start of sequence)
               ((and (zerop (length keys)) (not literal) (eq raw ?g) (eq mod 'ctrl))
                (setq mod 'meta))
               ((and (zerop (length keys)) (not literal) (eq raw ?G) (eq mod 'ctrl))
                (setq mod 'ctrl-meta))
               ;; SPC — send next key literally
               ((and (eq raw ?\s) (not literal))
                (setq literal t))
               ;; Escape — cancel
               ((eq raw 'escape)
                (message "god: cancelled")
                (cl-return-from god))
               ;; Regular key
               (t
                (let ((event (if literal raw (psyc-modal--god-modify raw mod))))
                  (setq literal nil
                        keys (vconcat keys (vector event)))
                  (let ((binding (key-binding keys)))
                    (cond
                     ((commandp binding)
                      (call-interactively binding)
                      (cl-return-from god))
                     ((keymapp binding)
                      (psyc-modal--god-show-which-key
                       binding (key-description keys)))
                     (t
                      (message "god: %s is undefined" (key-description keys))
                      (cl-return-from god))))))))))
      (psyc-modal--god-hide-which-key))))

;;;; --- Normal mode bindings ---

(let ((m psyc-modal-normal-map))
  ;; Escape
  (define-key m [escape] #'psyc-modal-escape)

  ;; Movement
  (define-key m "h" #'psyc-modal-left)
  (define-key m "j" #'psyc-modal-down)
  (define-key m "k" #'psyc-modal-up)
  (define-key m "l" #'psyc-modal-right)
  (define-key m "w" #'psyc-modal-word-next)
  (define-key m "b" #'psyc-modal-word-back)
  (define-key m "e" #'psyc-modal-word-end)
  (define-key m "W" #'psyc-modal-WORD-next)
  (define-key m "B" #'psyc-modal-WORD-back)
  (define-key m "E" #'psyc-modal-WORD-end)
  (define-key m "f" #'psyc-modal-find-forward)
  (define-key m "t" #'psyc-modal-till-forward)
  (define-key m "F" #'psyc-modal-find-backward)
  (define-key m "T" #'psyc-modal-till-backward)

  ;; Line
  (define-key m "x" #'psyc-modal-select-line)
  (define-key m "X" #'psyc-modal-select-line-above)
  (define-key m "J" #'psyc-modal-join-lines)

  ;; Selection
  (define-key m "v" #'psyc-modal-enter-select)
  (define-key m ";" #'psyc-modal-collapse)
  (define-key m "%" #'psyc-modal-select-all)
  (define-key m (kbd "M-;") #'psyc-modal-flip-selection)

  ;; Actions
  (define-key m "d" #'psyc-modal-delete)
  (define-key m "c" #'psyc-modal-change)
  (define-key m "y" #'psyc-modal-yank)
  (define-key m "p" #'psyc-modal-paste-after)
  (define-key m "P" #'psyc-modal-paste-before)
  (define-key m "R" #'psyc-modal-replace-paste)
  (define-key m "r" #'psyc-modal-replace-char)
  (define-key m "u" #'undo)
  (define-key m "U" #'undo-redo)
  (define-key m "~" #'psyc-modal-toggle-case)
  (define-key m ">" #'psyc-modal-indent)
  (define-key m "<" #'psyc-modal-dedent)
  (define-key m "=" #'psyc-modal-reindent)
  (define-key m "." #'repeat)

  ;; Insert entry
  (define-key m "i" #'psyc-modal-insert-before)
  (define-key m "a" #'psyc-modal-insert-after)
  (define-key m "I" #'psyc-modal-insert-bol)
  (define-key m "A" #'psyc-modal-insert-eol)
  (define-key m "o" #'psyc-modal-open-below)
  (define-key m "O" #'psyc-modal-open-above)

  ;; Search
  (define-key m "/" #'isearch-forward)
  (define-key m "n" #'psyc-modal-search-next)
  (define-key m "N" #'psyc-modal-search-prev)
  (define-key m "*" #'psyc-modal-search-selection)
  (define-key m "s" #'psyc-modal-select-regex)
  (define-key m "S" #'psyc-modal-select-regex-all)

  ;; Sexp movements
  (define-key m ")" #'psyc-modal-forward-sexp)
  (define-key m "(" #'psyc-modal-backward-sexp)

  ;; Expand/contract selection (tree-sitter or syntax-aware)
  (define-key m (kbd "M-o") #'expreg-expand)
  (define-key m (kbd "M-i") #'expreg-contract)

  ;; Multiple cursors
  (define-key m "C" #'mc/mark-next-like-this)
  (define-key m (kbd "M-C") #'mc/mark-previous-like-this)

  ;; Sub-modes
  (define-key m "g" psyc-modal-goto-map)
  (define-key m "m" psyc-modal-match-map)
  (define-key m " " psyc-modal-space-map)
  (define-key m "?" psyc-modal-help-map)
  (define-key m "\C-w" psyc-modal-window-map)
  (define-key m "z" psyc-modal-view-map)
  (define-key m "Z" #'psyc-modal-view-sticky)

  ;; Alt-action variants
  (define-key m (kbd "M-d") #'psyc-modal-delete-no-yank)
  (define-key m (kbd "M-c") #'psyc-modal-change-no-yank)
  (define-key m (kbd "M-s") #'psyc-modal-split-on-newlines)
  (define-key m (kbd "M-S") #'psyc-modal-for-each-line)
  (define-key m (kbd "M-x") #'psyc-modal-shrink-to-line)
  (define-key m (kbd "M-:") #'psyc-modal-ensure-forward)
  (define-key m (kbd "M-'") #'psyc-modal-split-selection)
  (define-key m (kbd "M-p") #'psyc-modal-paste-split)
  (define-key m "K" #'psyc-modal-keep-matching)
  (define-key m "|" #'psyc-modal-pipe-shell)

  ;; Comment toggle
  (define-key m "\C-c" #'comment-line)

  ;; Jumplist (Emacs xref history / mark ring)
  (define-key m "\C-o" #'pop-global-mark)
  (define-key m "\C-i" #'xref-go-forward)
  (define-key m "\C-s" #'push-mark-command)

  ;; Command mode / goto line
  (define-key m ":" #'execute-extended-command)
  (define-key m "G" #'goto-line)

  ;; God mode
  (define-key m "," #'psyc-modal-god-execute)

  ;; Scrolling
  (define-key m "\C-u" #'scroll-down-command)
  (define-key m "\C-d" #'scroll-up-command)
  (define-key m "\C-b" #'scroll-down-command)
  (define-key m "\C-f" #'scroll-up-command)

  ;; Macros
  (define-key m "Q" #'kmacro-start-macro-or-insert-counter)
  (define-key m "q" #'kmacro-end-or-call-macro)
  (define-key m (kbd "M-q") #'apply-macro-to-region-lines)

  ;; Unimpaired — ] prefix (next), [ prefix (prev)
  (define-key m "]d" #'flymake-goto-next-error)
  (define-key m "[d" #'flymake-goto-prev-error)
  (define-key m "]f" #'end-of-defun)
  (define-key m "[f" #'beginning-of-defun)
  (define-key m "]p" #'forward-paragraph)
  (define-key m "[p" #'backward-paragraph)
  (define-key m (kbd "] SPC") (lambda () (interactive) (save-excursion (end-of-line) (newline))))
  (define-key m (kbd "[ SPC") (lambda () (interactive) (save-excursion (beginning-of-line) (open-line 1))))
  (define-key m "]c" #'psyc-modal-next-comment)
  (define-key m "[c" #'psyc-modal-prev-comment)
  (define-key m "]g" #'diff-hl-next-hunk)
  (define-key m "[g" #'diff-hl-previous-hunk)

  ;; Increment / decrement (Helix uses C-a/C-x, but C-x shadows the
  ;; entire ctl-x-map prefix, so decrement lives on -)
  (define-key m "\C-a" #'increment-number-at-point)
  (define-key m "-"    #'decrement-number-at-point)

  ;; Which-key (available from every state)
  (define-key m [f5]   #'which-key-show-top-level)
  (define-key m [C-f5] #'which-key-show-major-mode)

  ;; Digit arguments
  (dotimes (i 10)
    (define-key m (number-to-string i) #'digit-argument))

)

;;;; --- Insert mode bindings ---

(let ((m psyc-modal-insert-map))
  (define-key m [escape] #'psyc-modal-enter-normal)
  ;; Helix insert-mode convenience keys
  (define-key m (kbd "C-w") #'backward-kill-word)
  (define-key m (kbd "C-u") #'backward-kill-line)
  (define-key m (kbd "C-k") #'kill-line)
  (define-key m (kbd "C-d") #'psyc-modal-insert-delete-char)
  (define-key m (kbd "DEL") #'psyc-modal-insert-backward-delete)
  (define-key m [backspace] #'psyc-modal-insert-backward-delete)
  ;; Which-key from insert too
  (define-key m [f5]   #'which-key-show-top-level)
  (define-key m [C-f5] #'which-key-show-major-mode))

;; Global f5 for non-modal buffers (eshell, term, etc.)
(global-set-key [f5] #'which-key-show-top-level)

;;;; --- Alt-action variants ---

(defun psyc-modal-delete-no-yank ()
  "Delete selection without saving to kill ring (Alt-d)."
  (interactive)
  (if (use-region-p)
      (delete-region (region-beginning) (region-end))
    (delete-char 1)))

(defun psyc-modal-change-no-yank ()
  "Change selection without saving to kill ring (Alt-c)."
  (interactive)
  (if (use-region-p)
      (delete-region (region-beginning) (region-end))
    (delete-char 1))
  (psyc-modal-enter-insert))

(defun psyc-modal-split-on-newlines ()
  "Split selection into one selection per line (Alt-s).
With multiple-cursors: creates a cursor per line.
Without: activates rectangle-mark-mode on the region."
  (interactive)
  (cond
   ((and (use-region-p) (fboundp 'mc/edit-lines))
    (mc/edit-lines))
   ((use-region-p)
    (let ((beg (region-beginning))
          (end (region-end)))
      (goto-char beg)
      (rectangle-mark-mode 1)
      (goto-char end)))
   (t (message "No selection to split"))))

(defun psyc-modal-shrink-to-line ()
  "Shrink selection to line bounds, excluding leading/trailing whitespace (Alt-x)."
  (interactive)
  (when (region-active-p)
    (let ((beg (save-excursion (goto-char (region-beginning))
                               (back-to-indentation) (point)))
          (end (save-excursion (goto-char (region-end))
                               (skip-chars-backward " \t\n") (point))))
      (set-mark beg)
      (goto-char end))))

(defun psyc-modal-ensure-forward ()
  "Ensure selection goes forward — anchor before cursor (Alt-:)."
  (interactive)
  (when (and (region-active-p) (> (mark) (point)))
    (exchange-point-and-mark)))

(defun psyc-modal-keep-matching ()
  "Keep only lines in selection matching prompted regex (K)."
  (interactive)
  (when (use-region-p)
    (let ((re (read-string "keep matching: ")))
      (keep-lines re (region-beginning) (region-end)))))

(defun psyc-modal-pipe-shell ()
  "Pipe selection through shell command, replace with output (|)."
  (interactive)
  (if (use-region-p)
      (shell-command-on-region (region-beginning) (region-end)
                               (read-string "pipe: ") t t)
    (shell-command-on-region (line-beginning-position) (line-end-position)
                             (read-string "pipe: ") t t)))

;;;; --- For-each-line ---

(defun psyc-modal-for-each-line ()
  "Run a command on each line of the selection.
Prompts for an interactive command, then executes it with point at
the beginning of each line (bottom-to-top for stability).
The whole operation is a single undo step."
  (interactive)
  (unless (use-region-p) (user-error "No selection"))
  (let* ((cmd (intern (completing-read "command per line: " obarray #'commandp t)))
         (beg (save-excursion (goto-char (region-beginning))
                              (line-beginning-position)))
         (end (save-excursion (goto-char (region-end))
                              (when (bolp) (forward-line -1))
                              (line-end-position)))
         (lines (count-lines beg end)))
    (deactivate-mark)
    (atomic-change-group
      (save-excursion
        (goto-char end)
        (dotimes (_ lines)
          (beginning-of-line)
          (set-mark (line-end-position))
          (call-interactively cmd)
          (forward-line -1))))
    (message "Ran %s on %d lines" cmd lines)))

;;;; --- Split ring ---

(defvar psyc-modal--split-ring nil
  "List of strings from the last split operation.  FIFO — consumed by paste.")

(defun psyc-modal-split-selection ()
  "Split selection into pieces by newline (or prompted separator).
Pieces are stored in a FIFO split ring, pasted with `psyc-modal-paste-split'.
With prefix arg, prompts for a custom separator regex."
  (interactive)
  (unless (use-region-p) (user-error "No selection"))
  (let* ((sep (if current-prefix-arg
                  (read-string "split on (regex): ")
                "\n"))
         (text (buffer-substring-no-properties (region-beginning) (region-end)))
         (pieces (split-string text sep)))
    (setq psyc-modal--split-ring pieces)
    (deactivate-mark)
    (message "Split into %d pieces — M-p to paste" (length pieces))))

(defun psyc-modal-paste-split ()
  "Paste and consume the next piece from the split ring (FIFO)."
  (interactive)
  (unless psyc-modal--split-ring (user-error "Split ring empty"))
  (let ((piece (pop psyc-modal--split-ring)))
    (insert piece)
    (message "Pasted (%d remaining)" (length psyc-modal--split-ring))))

;;;; --- Search enhancements ---

(defun psyc-modal-search-selection ()
  "Use current selection as search pattern, or symbol at point (*)."
  (interactive)
  (let ((str (if (use-region-p)
                 (buffer-substring-no-properties (region-beginning) (region-end))
               (thing-at-point 'symbol t))))
    (when str
      (deactivate-mark)
      (setq psyc-modal--last-search (cons (regexp-quote str) t))
      (psyc-modal-search-next))))

(defun psyc-modal-select-regex-all ()
  "Select ALL regex matches in selection, creating multiple cursors (S)."
  (interactive)
  (if (and (use-region-p) (fboundp 'mc/mark-all-in-region-regexp))
      (let ((str (read-string "select all: ")))
        (mc/mark-all-in-region-regexp (region-beginning) (region-end) str)
        (setq psyc-modal--last-search (cons str t)))
    (call-interactively #'psyc-modal-select-regex)))

;;;; --- Insert helpers ---

(defun psyc-modal-insert-delete-char ()
  "Delete forward char, respecting paren balance in lisp modes."
  (interactive)
  (cond
   ;; On closing paren in a lisp — skip over it
   ((and (derived-mode-p 'emacs-lisp-mode 'lisp-mode 'clojure-mode
                         'janet-mode 'scheme-mode 'lisp-interaction-mode)
         (looking-at "\\s)"))
    (up-list))
   (t (delete-char 1))))

(defun psyc-modal-insert-backward-delete ()
  "Balanced backward delete for insert mode.
Deletes matching pair when between them, skips over close parens in lisps."
  (interactive)
  (cond
   ;; Between matching pair: (|) or [|] or {|} — delete both
   ((and (not (bobp)) (not (eobp))
         (looking-back "\\s(" 1)
         (looking-at "\\s)"))
    (delete-char 1)
    (delete-char -1))
   ;; In lisp: don't delete unmatched close paren
   ((and (derived-mode-p 'emacs-lisp-mode 'lisp-mode 'clojure-mode
                         'janet-mode 'scheme-mode 'lisp-interaction-mode)
         (not (bobp))
         (save-excursion (backward-char) (looking-at "\\s)")))
    (backward-char))
   ;; Normal backward delete
   (t (backward-delete-char-untabify 1))))

;;;; --- Tree-sitter text objects ---

(defun psyc-modal--treesit-select (thing around)
  "Select THING at point using tree-sitter.  If AROUND, include whitespace."
  (when (and (fboundp 'treesit-node-at) (treesit-language-at (point)))
    (let* ((node (treesit-node-at (point)))
           (target (treesit-parent-until
                    node
                    (lambda (n) (string-match-p thing (treesit-node-type n))))))
      (when target
        (let ((beg (treesit-node-start target))
              (end (treesit-node-end target)))
          (when around
            (save-excursion (goto-char end) (skip-chars-forward " \t\n")
                            (setq end (point))))
          (set-mark beg)
          (goto-char end))))))

(defun psyc-modal-select-inside-function ()
  "Select inside function body (mif)."
  (interactive)
  (or (psyc-modal--treesit-select
       "function_definition\\|function_declaration\\|method_definition\\|defun\\|fn_item\\|function_item"
       nil)
      ;; Fallback: use defun boundaries
      (let ((beg (save-excursion (beginning-of-defun) (point)))
            (end (save-excursion (end-of-defun) (point))))
        (set-mark beg) (goto-char end))))

(defun psyc-modal-select-around-function ()
  "Select around function including whitespace (maf)."
  (interactive)
  (or (psyc-modal--treesit-select
       "function_definition\\|function_declaration\\|method_definition\\|defun\\|fn_item\\|function_item"
       t)
      (let ((beg (save-excursion (beginning-of-defun) (point)))
            (end (save-excursion (end-of-defun) (skip-chars-forward " \t\n") (point))))
        (set-mark beg) (goto-char end))))

;;;; --- Unimpaired extras ---

(defun psyc-modal-next-comment ()
  "Jump to next comment (]c)."
  (interactive)
  (forward-line)
  (while (and (not (eobp))
              (not (nth 4 (syntax-ppss))))
    (forward-line))
  (back-to-indentation))

(defun psyc-modal-prev-comment ()
  "Jump to previous comment ([c)."
  (interactive)
  (forward-line -1)
  (while (and (not (bobp))
              (not (nth 4 (syntax-ppss))))
    (forward-line -1))
  (back-to-indentation))

;;;; --- Increment / decrement numbers ---

(defun increment-number-at-point (&optional arg)
  "Increment number at point by ARG (default 1)."
  (interactive "p")
  (save-excursion
    (skip-chars-backward "0-9")
    (when (looking-at "[0-9]+")
      (replace-match (number-to-string (+ (string-to-number (match-string 0))
                                          (or arg 1)))))))

(defun decrement-number-at-point (&optional arg)
  "Decrement number at point by ARG (default 1)."
  (interactive "p")
  (increment-number-at-point (- (or arg 1))))

;;;; --- Which-key descriptions ---

(defconst psyc-modal--which-key-strip-prefixes
  '("mc/" "diff-hl-" "which-key-" "xref-" "flymake-" "eglot-"
    "consult-" "project-" "magit-" "vertico-" "org-" "cider-"
    "janet-" "nix-" "windmove-" "clipboard-" "kmacro-")
  "Package prefixes removed when generating which-key labels.")

(defconst psyc-modal--which-key-command-labels
  '((psyc-modal-escape . "cancel / escape")
    (psyc-modal-enter-select . "toggle select")
    (psyc-modal-replace-paste . "replace with yank")
    (psyc-modal-search-selection . "search selection")
    (psyc-modal-select-regex . "select regex")
    (psyc-modal-select-regex-all . "select regex all")
    (psyc-modal-view-sticky . "view sticky")
    (psyc-modal-god-execute . "god mode")
    (psyc-modal-shrink-to-line . "shrink to line")
    (psyc-modal-ensure-forward . "forward selection")
    (psyc-modal-split-on-newlines . "split on lines")
    (psyc-modal-paste-split . "paste split")
    (psyc-modal-keep-matching . "keep matching lines")
    (psyc-modal-pipe-shell . "pipe through shell")
    (psyc-modal-insert-delete-char . "delete char")
    (psyc-modal-insert-backward-delete . "backspace")
    (psyc-modal-show-keys . "show keys")
    (psyc-tutor . "start tutor")
    (psyc-tutor-quick-reference . "editing quick ref")
    (expreg-expand . "expand selection")
    (expreg-contract . "shrink selection")
    (mc/mark-next-like-this . "mark next like this")
    (mc/mark-previous-like-this . "mark prev like this")
    (which-key-show-top-level . "top-level keys")
    (which-key-show-major-mode . "major-mode keys")
    (pop-global-mark . "jump back")
    (xref-go-forward . "jump forward")
    (push-mark-command . "push mark")
    (flymake-goto-next-error . "next diagnostic")
    (flymake-goto-prev-error . "prev diagnostic")
    (diff-hl-next-hunk . "next hunk")
    (diff-hl-previous-hunk . "prev hunk")
    (beginning-of-defun . "prev defun")
    (end-of-defun . "next defun")
    (consult-mark . "mark")
    (consult-imenu-multi . "imenu all")
    (flymake-show-project-diagnostics . "project diagnostics")
    (pp-eval-expression . "eval expression")
    (vertico-repeat . "repeat minibuffer")
    (comment-region . "comment region")
    (magit-status . "status")
    (magit-blame-addition . "blame")
    (magit-log-buffer-file . "file log")
    (magit-find-file . "find file at rev")
    (backward-kill-word . "delete word backward")
    (backward-kill-line . "delete to bol")
    (save-buffers-kill-emacs . "quit Emacs"))
  "Concise which-key labels keyed by command symbol.")

(defun psyc-modal--which-key-doc-label (command)
  "Return a concise which-key label for psyc COMMAND."
  (when-let ((doc (documentation command t)))
    (let ((label (car (split-string doc "\n" t))))
      (setq label (car (split-string label "\\.  +" t)))
      (setq label (replace-regexp-in-string "\\s-*([^)]+)\\.?\\'" "" label))
      (setq label (string-trim (replace-regexp-in-string "\\.$" "" label)))
      (unless (string-empty-p label)
        (concat (downcase (substring label 0 1)) (substring label 1))))))

(defun psyc-modal--which-key-humanize-command (command)
  "Return a readable which-key label for COMMAND."
  (when (symbolp command)
    (let ((label (symbol-name command)))
      (setq label (replace-regexp-in-string "\\`[^/]+/" "" label))
      (dolist (prefix psyc-modal--which-key-strip-prefixes)
        (when (string-prefix-p prefix label)
          (setq label (substring label (length prefix)))))
      (setq label (replace-regexp-in-string "-or-" "/" label))
      (setq label (replace-regexp-in-string "-at-point\\'" "" label))
      (replace-regexp-in-string "-" " " label))))

(defun psyc-modal--which-key-command-label (command)
  "Return the preferred which-key label for COMMAND."
  (or (alist-get command psyc-modal--which-key-command-labels)
      (and (symbolp command)
           (string-prefix-p "psyc-modal-" (symbol-name command))
           (psyc-modal--which-key-doc-label command))
      (psyc-modal--which-key-humanize-command command)))

(defun psyc-modal--which-key-collect-replacements (keymap &optional prefix recursive)
  "Collect which-key replacements for KEYMAP.
PREFIX is the current key sequence prefix.  If RECURSIVE is non-nil,
descend into nested keymaps and emit replacements for full sequences."
  (let (replacements)
    (map-keymap
     (lambda (event binding)
       (when-let ((key (ignore-errors (key-description (vector event)))))
         (let ((full-key (if prefix (concat prefix " " key) key)))
           (cond
            ((commandp binding)
             (when-let ((label (psyc-modal--which-key-command-label binding)))
               (setq replacements
                     (nconc replacements (list full-key (cons label binding))))))
            ((and recursive (keymapp binding))
             (setq replacements
                   (nconc replacements
                          (psyc-modal--which-key-collect-replacements
                           binding full-key recursive))))))))
     keymap)
    replacements))

(defun psyc-modal--which-key-register-bindings (keymap &optional recursive)
  "Register concise which-key labels for KEYMAP.
If RECURSIVE is non-nil, also label nested key sequences."
  (when (and (keymapp keymap)
             (fboundp 'which-key-add-keymap-based-replacements))
    (when-let ((replacements
                (psyc-modal--which-key-collect-replacements keymap nil recursive)))
      (apply #'which-key-add-keymap-based-replacements keymap replacements))))

(defun psyc-modal--which-key-register-local-map ()
  "Register which-key labels for the current buffer's local leader map."
  (when (keymapp psyc-modal-local-map)
    (psyc-modal--which-key-register-bindings psyc-modal-local-map t)))

(defun psyc-modal--setup-which-key ()
  "Register which-key descriptions for psyc-modal keymaps."
  (when (fboundp 'which-key-add-keymap-based-replacements)
    (dolist (map (list psyc-modal-normal-map
                       psyc-modal-insert-map
                       psyc-modal-goto-map
                       psyc-modal-match-map
                       psyc-modal-space-map
                       psyc-modal-help-map
                       psyc-modal-window-map
                       psyc-modal-view-map
                       psyc-modal-view-sticky-map))
      (psyc-modal--which-key-register-bindings map))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (psyc-modal--which-key-register-local-map)))
    ;; Sub-map prefixes in normal map
    (which-key-add-keymap-based-replacements psyc-modal-normal-map
      "g" "goto"
      "m" "match/surround/struct"
      " " "leader"
      "?" "help…"
      "C-w" "window"
      "z" "view"
      "]" "next…"
      "[" "prev…"
      "] d" "next diagnostic"
      "[ d" "prev diagnostic"
      "] f" "next defun"
      "[ f" "prev defun"
      "] p" "next paragraph"
      "[ p" "prev paragraph"
      "] SPC" "open line below"
      "[ SPC" "open line above"
      "] c" "next comment"
      "[ c" "prev comment"
      "] g" "next hunk"
      "[ g" "prev hunk")
    ;; Goto map
    (which-key-add-keymap-based-replacements psyc-modal-goto-map
      "g" "file start"
      "e" "file end"
      "h" "line start"
      "l" "line end"
      "s" "first non-blank"
      "t" "window top"
      "c" "window center"
      "b" "window bottom"
      "d" "definition"
      "r" "references"
      "n" "next buffer"
      "p" "prev buffer")
    ;; Match map
    (which-key-add-keymap-based-replacements psyc-modal-match-map
      "m" "match bracket"
      "s" "surround add"
      "d" "surround delete"
      "r" "surround replace"
      "w" "wrap sexp"
      "i" "select inside"
      "a" "select around"
      ")" "slurp →"
      "(" "slurp ←"
      "}" "barf →"
      "{" "barf ←"
      "S" "splice"
      "R" "raise"
      "T" "transpose")
    ;; Space map
    (which-key-add-keymap-based-replacements psyc-modal-space-map
      "f" "find file"
      "F" "project file"
      "b" "switch buffer"
      "s" "save"
      "w" "window…"
      "/" "ripgrep"
      " " "M-x"
      "q" "quit window"
      "Q" "quit frame/client"
      "d" "kill buffer"
      "c" "comment"
      "k" "eldoc"
      "y" "clipboard copy"
      "p" "clipboard paste"
      "R" "rename file"
      "'" "repeat minibuffer"
      ";" "eval expression"
      "i" "imenu"
      "j" "mark"
      "l" "line search"
      "a" "code action"
      "r" "rename symbol"
      "e" "diagnostics"
      "E" "project diagnostics"
      "S" "imenu all"
      "D" "project diagnostics"
      "C" "comment region"
      "h" "help…"
      "m" "local leader"
      "g" "git…"
      "g g" "status"
      "g b" "blame"
      "g l" "file log"
      "g f" "find file at rev")
    ;; Help map
    (which-key-add-keymap-based-replacements psyc-modal-help-map
      "?" "editing quick ref"
      "t" "start tutor"
      "k" "modal keys"
      "m" "major-mode keys")
    ;; Window map
    (which-key-add-keymap-based-replacements psyc-modal-window-map
      "s" "split horiz"
      "v" "split vert"
      "h" "← window"
      "j" "↓ window"
      "k" "↑ window"
      "l" "→ window"
      "H" "swap ←"
      "J" "swap ↓"
      "K" "swap ↑"
      "L" "swap →"
      "q" "close"
      "o" "only"
      "=" "balance"
      "w" "other"
      "f" "file other")
    ;; View map
    (which-key-add-keymap-based-replacements psyc-modal-view-map
      "z" "recenter"
      "c" "recenter"
      "t" "top"
      "b" "bottom"
      "j" "scroll down line"
      "k" "scroll up line"
      "C-f" "page down"
      "C-b" "page up"
      "C-d" "half page down"
      "C-u" "half page up")
    (which-key-add-keymap-based-replacements psyc-modal-view-sticky-map
      "z" "recenter"
      "c" "recenter"
      "t" "top"
      "b" "bottom"
      "j" "scroll down line"
      "k" "scroll up line")))

(add-hook 'after-init-hook #'psyc-modal--setup-which-key)

(defun psyc-modal-show-keys ()
  "Show which-key popup for current psyc-modal state."
  (interactive)
  (if (fboundp 'which-key-show-keymap)
      (pcase psyc-modal--state
        ('normal (which-key-show-keymap 'psyc-modal-normal-map))
        ('insert (which-key-show-keymap 'psyc-modal-insert-map))
        (_ (which-key-show-keymap 'psyc-modal-normal-map)))
    (message "which-key not available")))

;;;; --- Corfu integration ---

(with-eval-after-load 'corfu
  (add-hook 'psyc-modal-state-change-hook
            (lambda (state)
              (when (and (eq state 'normal)
                         (bound-and-true-p corfu-mode)
                         (fboundp 'corfu-quit))
                (corfu-quit)))))

(provide 'psyc-modal)
;;; psyc-modal.el ends here
