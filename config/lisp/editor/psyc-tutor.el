;;; psyc-tutor.el --- vimtutor-style guide for psyc-modal -*- lexical-binding: t -*-
;;; Commentary:
;;
;; A hands-on, vimtutor-style walkthrough of psyc-modal.  The tutor opens
;; an editable buffer containing the lessons; the reader practices the
;; techniques directly on the text in front of them.
;;
;; A live quick reference is also provided — keys are looked up from the
;; current keymaps, so it stays accurate after rebinding.
;;
;; Usage:  M-x psyc-tutor                  Start the tutor
;;         M-x psyc-tutor-quick-reference  Show live keybinding reference

;;; Code:

(require 'psyc-modal)

;;;; --- Quick reference ---

(defun psyc-tutor--key-for-command (cmd &optional keymap)
  "Return the key string bound to CMD in KEYMAP.
With no KEYMAP, searches `psyc-modal-normal-map' first, falling back to
`psyc-modal-insert-map' so commands like `psyc-modal-enter-normal'
resolve to their insert-mode binding."
  (when-let ((keys (or (where-is-internal cmd (or keymap psyc-modal-normal-map) t)
                       (unless keymap
                         (where-is-internal cmd psyc-modal-insert-map t)))))
    (key-description keys)))

(defun psyc-tutor--key-for-command-prefixed (cmd prefix)
  "Return a binding for CMD that begins with PREFIX, falling back to any.
PREFIX is compared against the `key-description' form, so e.g. \"SPC\"
matches the space-leader binding.  Used by placeholders of the form
`[[cmd@SPC]]' to disambiguate when a command has multiple bindings."
  (let* ((all (append (where-is-internal cmd psyc-modal-normal-map nil)
                      (where-is-internal cmd psyc-modal-insert-map nil)))
         (descs (delete-dups (mapcar #'key-description all)))
         (preferred (seq-find
                     (lambda (d) (string-prefix-p prefix d))
                     descs)))
    (or preferred (car descs) (psyc-tutor--key-for-command cmd))))

(defun psyc-tutor--reference-key (cmd)
  "Return a display key for CMD, falling back to its symbol name."
  (or (psyc-tutor--key-for-command cmd)
      (symbol-name cmd)))

(defun psyc-tutor--render-template (template)
  "Return TEMPLATE with [[cmd]] placeholders resolved to current bindings.
A `[[cmd]]' token is replaced with the key sequence currently bound to
the command symbol `cmd' in `psyc-modal-normal-map' (which traverses
sub-keymaps).  Use `[[cmd@PREFIX]]' to prefer a binding whose key
description starts with PREFIX (e.g. \"SPC\", \"C-w\").  If the command
is unbound, the placeholder is left in place so the omission is visible."
  (replace-regexp-in-string
   "\\[\\[\\([a-zA-Z][a-zA-Z0-9*/-]*\\)\\(?:@\\([^]]+\\)\\)?\\]\\]"
   (lambda (match)
     (let* ((name (match-string 1 match))
            (prefix (match-string 2 match))
            (sym (intern-soft name)))
       (or (and sym prefix (psyc-tutor--key-for-command-prefixed sym prefix))
           (and sym (psyc-tutor--key-for-command sym))
           match)))
   template))

(defun psyc-tutor--reference-prefix (cmd suffix)
  "Return the CMD binding followed by SUFFIX."
  (string-join (list (psyc-tutor--reference-key cmd) suffix) " "))

(defun psyc-tutor--reference-alt (&rest keys)
  "Join KEYS as alternatives for display."
  (string-join keys " / "))

(defun psyc-tutor--reference-seq (&rest keys)
  "Join KEYS as a sequential command pattern."
  (string-join keys " "))

(defun psyc-tutor--insert-reference-section (title rows)
  "Insert a reference section titled TITLE with ROWS."
  (let ((width (apply #'max 0 (mapcar (lambda (row) (length (car row))) rows))))
    (insert (propertize title 'face 'bold) "\n")
    (dolist (row rows)
      (insert "  "
              (propertize (format (format "%%-%ds" width) (car row))
                          'face 'help-key-binding)
              "  "
              (cdr row)
              "\n"))
    (insert "\n")))

(defconst psyc-tutor--reference-buf-name "*psyc-modal quick ref*")

(defvar psyc-tutor-reference-mode-map
  (let ((m (make-sparse-keymap)))
    (set-keymap-parent m special-mode-map)
    (define-key m "t" #'psyc-tutor)
    (define-key m "g" #'psyc-tutor-quick-reference)
    m)
  "Keymap for `psyc-tutor-reference-mode'.")

(define-derived-mode psyc-tutor-reference-mode special-mode "Tutor Ref"
  "Quick reference for psyc-modal editing patterns."
  (setq-local truncate-lines t))

(defun psyc-tutor-quick-reference ()
  "Show a quick reference for psyc-modal editing patterns."
  (interactive)
  (let ((buf (get-buffer-create psyc-tutor--reference-buf-name)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (psyc-tutor-reference-mode)
        (insert (propertize "PSYC Modal Quick Reference\n" 'face 'header-line)
                "\n")
        (insert "Selection-first editing: movements create a selection, then actions like "
                (propertize "d" 'face 'help-key-binding)
                ", "
                (propertize "c" 'face 'help-key-binding)
                ", and "
                (propertize "y" 'face 'help-key-binding)
                " consume it.\n\n")
        (psyc-tutor--insert-reference-section
         "Move"
         (list
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-left)
                 (psyc-tutor--reference-key 'psyc-modal-down)
                 (psyc-tutor--reference-key 'psyc-modal-up)
                 (psyc-tutor--reference-key 'psyc-modal-right))
                "move by character")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-word-next)
                 (psyc-tutor--reference-key 'psyc-modal-word-back)
                 (psyc-tutor--reference-key 'psyc-modal-word-end))
                "word start / back / end")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-WORD-next)
                 (psyc-tutor--reference-key 'psyc-modal-WORD-back)
                 (psyc-tutor--reference-key 'psyc-modal-WORD-end))
                "WORD motions")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-prefix 'psyc-modal-find-forward "x")
                 (psyc-tutor--reference-prefix 'psyc-modal-till-forward "x")
                 (psyc-tutor--reference-prefix 'psyc-modal-find-backward "x")
                 (psyc-tutor--reference-prefix 'psyc-modal-till-backward "x"))
                "find / till a character on the line")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-goto-line-start)
                 (psyc-tutor--reference-key 'psyc-modal-goto-line-end)
                 (psyc-tutor--reference-key 'psyc-modal-goto-file-start)
                 (psyc-tutor--reference-key 'psyc-modal-goto-file-end)
                 (psyc-tutor--reference-key 'psyc-modal-goto-first-nonblank))
                "line and buffer edges")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-backward-sexp)
                 (psyc-tutor--reference-key 'psyc-modal-forward-sexp))
                "previous / next sexp")))
        (psyc-tutor--insert-reference-section
         "Select + Edit"
         (list
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-enter-select)
                 (psyc-tutor--reference-key 'psyc-modal-collapse)
                 (psyc-tutor--reference-key 'psyc-modal-select-all))
                "extend selection / collapse / select buffer")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-select-line)
                 (psyc-tutor--reference-key 'psyc-modal-select-line-above)
                 (psyc-tutor--reference-key 'psyc-modal-join-lines))
                "select line / line above / join lines")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-delete)
                 (psyc-tutor--reference-key 'psyc-modal-change)
                 (psyc-tutor--reference-key 'psyc-modal-yank))
                "delete / change / yank")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-paste-after)
                 (psyc-tutor--reference-key 'psyc-modal-paste-before)
                 (psyc-tutor--reference-key 'psyc-modal-replace-paste))
                "paste after / before / replace with yank")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-replace-char)
                 (psyc-tutor--reference-key 'psyc-modal-toggle-case)
                 (psyc-tutor--reference-key 'repeat))
                "replace char / toggle case / repeat last edit")))
        (psyc-tutor--insert-reference-section
         "Insert"
         (list
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-insert-before)
                 (psyc-tutor--reference-key 'psyc-modal-insert-after))
                "insert before / after point")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-insert-bol)
                 (psyc-tutor--reference-key 'psyc-modal-insert-eol))
                "insert at first non-blank / end of line")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-open-below)
                 (psyc-tutor--reference-key 'psyc-modal-open-above))
                "open a line below / above")
          (cons (or (psyc-tutor--key-for-command
                     'psyc-modal-enter-normal psyc-modal-insert-map)
                    "<escape>")
                "return to normal state")))
        (psyc-tutor--insert-reference-section
         "Text Objects + Structure"
         (list
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "w")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-around "w"))
                "inside / around word")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "(")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-around "(")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "[")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-around "["))
                "inside / around parens and brackets")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "\"")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-around "\"")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "f")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-around "f"))
                "inside / around quotes and functions")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-prefix 'psyc-modal-surround-add "(")
                 (psyc-tutor--reference-prefix 'psyc-modal-surround-delete "(")
                 (psyc-tutor--reference-prefix 'psyc-modal-surround-replace "( [")
                 (psyc-tutor--reference-prefix 'psyc-modal-wrap "("))
                "surround / delete surround / replace surround / wrap")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-slurp-forward)
                 (psyc-tutor--reference-key 'psyc-modal-barf-forward)
                 (psyc-tutor--reference-key 'psyc-modal-splice)
                 (psyc-tutor--reference-key 'psyc-modal-raise))
                "slurp / barf / splice / raise")))
        (psyc-tutor--insert-reference-section
         "Practice"
         (list
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-seq
                  (psyc-tutor--reference-key 'psyc-modal-word-next)
                  (psyc-tutor--reference-key 'psyc-modal-delete))
                 (psyc-tutor--reference-seq
                  (psyc-tutor--reference-key 'psyc-modal-select-line)
                  (psyc-tutor--reference-key 'psyc-modal-delete))
                 (psyc-tutor--reference-seq
                  (psyc-tutor--reference-key 'psyc-modal-select-line)
                  (psyc-tutor--reference-key 'psyc-modal-yank)))
                "delete word / delete line / yank line")
          (cons (psyc-tutor--reference-seq
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "w")
                 (psyc-tutor--reference-key 'psyc-modal-change))
                "change inside word")
          (cons (psyc-tutor--reference-seq
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "(")
                 (psyc-tutor--reference-key 'psyc-modal-delete))
                "delete inside parens")
          (cons (psyc-tutor--reference-seq
                 (psyc-tutor--reference-key 'psyc-modal-select-all)
                 (psyc-tutor--reference-prefix 'psyc-modal-surround-add "("))
                "surround the whole buffer")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-tutor-quick-reference)
                 (psyc-tutor--reference-key 'psyc-tutor)
                 (psyc-tutor--reference-key 'psyc-modal-show-keys)
                 (psyc-tutor--reference-key 'which-key-show-major-mode))
                "this reference / start tutor / modal keys / major-mode keys")))
        (insert "In this buffer: "
                (propertize "q" 'face 'help-key-binding)
                " quits, "
                (propertize "t" 'face 'help-key-binding)
                " starts the tutor, "
                (propertize "g" 'face 'help-key-binding)
                " refreshes the reference.\n")
        (goto-char (point-min))))
    (pop-to-buffer buf)))

;;;; --- Vimtutor-style document ---

(defconst psyc-tutor--buffer-name "*psyc-tutor*")

(defconst psyc-tutor--text-template "\
===========================================================================
=                W E L C O M E   T O   T H E   T U T O R                  =
===========================================================================

  psyc-modal is a Helix-inspired modal editor for Emacs.  In about 30
  minutes you can pick up enough to edit comfortably.

  HOW TO USE THIS TUTOR
    - This buffer is fully editable.  Try every command on the lines
      marked with ---->.  Some lines start out broken on purpose.
    - The modeline shows your state: [N] normal, [S] select, [I] insert.
    - [[psyc-modal-enter-normal]] always returns you to NORMAL mode.  Reach for it freely.
    - To restart with a fresh copy:    M-x psyc-tutor
    - To see the live key reference:   M-x psyc-tutor-quick-reference
                                       (or `[[psyc-tutor-quick-reference]]' from normal mode)

  GROUND RULES
    1. Most lessons follow this pattern: read the explanation, then make
       the broken `---->' line match the `---->' line below it.
    2. Every key shown is looked up live, so the tutor stays accurate
       even if you've rebound something.
    3. If you get lost, press [[psyc-modal-enter-normal]] and start the lesson over.

  Press [[psyc-modal-enter-normal]], then `[[psyc-modal-down]]' a few times to scroll down.  Begin Lesson 1.


===========================================================================
= Lesson 1.1: THE THREE MODES
===========================================================================

  Normal [N] is for moving and issuing commands.
  Select [S] is normal mode with an active selection that grows with motion.
  Insert [I] is for typing text.

  Transitions you'll use constantly:

    [[psyc-modal-insert-before]]  [[psyc-modal-insert-after]]    enter INSERT before / after the cursor
    [[psyc-modal-open-below]]  [[psyc-modal-open-above]]    open a line below / above and enter INSERT
    [[psyc-modal-enter-select]]       toggle SELECT mode (movements extend the selection)
    [[psyc-modal-collapse]]       collapse a selection back to a single point
    [[psyc-modal-enter-normal]] always returns to NORMAL

  Try this on the ----> line: press `[[psyc-modal-insert-before]]', type the missing word `quick',
  then press [[psyc-modal-enter-normal]].

  ---->   The brown fox jumps.
  ---->   The quick brown fox jumps.


===========================================================================
= Lesson 1.2: BASIC MOTION ([[psyc-modal-left]] [[psyc-modal-down]] [[psyc-modal-up]] [[psyc-modal-right]])
===========================================================================

  In NORMAL mode the cursor moves with:

    [[psyc-modal-left]]   left
    [[psyc-modal-down]]   down
    [[psyc-modal-up]]   up
    [[psyc-modal-right]]   right

  Numeric prefix repeats: `5 [[psyc-modal-right]]' moves five characters right, `3 [[psyc-modal-down]]' moves
  three lines down.  This works with most motion commands.

  Move to the start of the line below using only the four motion keys,
  then back here.

  ---->   PRACTICE: jump around this line until the motions feel automatic.


===========================================================================
= Lesson 1.3: WORD MOTION
===========================================================================

  Words are blocks of letters/digits/underscore separated by punctuation.

    [[psyc-modal-word-next]]   jump to the START of the next word
    [[psyc-modal-word-back]]   jump BACK to the start of the previous word
    [[psyc-modal-word-end]]   jump to the END of the current word

  WORDS (uppercase) are whitespace-delimited — punctuation does NOT split
  them.  Use them when you want to fly past code:

    [[psyc-modal-WORD-next]]   next WORD start
    [[psyc-modal-WORD-back]]   previous WORD start
    [[psyc-modal-WORD-end]]   current WORD end

  Practice on the next line by walking it with `[[psyc-modal-word-next]]', then again with `[[psyc-modal-WORD-next]]'.

  ---->   foo.bar(qux, baz);   one_two-three   it's-a-trap


===========================================================================
= Lesson 1.4: LINE AND BUFFER MOTION
===========================================================================

  The GOTO map covers the common jumps:

    [[psyc-modal-goto-line-start]]   beginning of line
    [[psyc-modal-goto-line-end]]   end of line
    [[psyc-modal-goto-first-nonblank]]   first non-blank character on the line
    [[psyc-modal-goto-file-start]]   beginning of buffer
    [[psyc-modal-goto-file-end]]   end of buffer
    [[goto-line]] N go to line N (e.g. `42 [[goto-line]]')

  Window-relative jumps live in the same map:

    [[psyc-modal-goto-window-top]]   top of visible window
    [[psyc-modal-goto-window-center]]   center
    [[psyc-modal-goto-window-bottom]]   bottom

  Practice: from anywhere on the line below, press `[[psyc-modal-goto-first-nonblank]]', then `[[psyc-modal-goto-line-end]]',
  then `[[psyc-modal-goto-line-start]]'.

  ---->       this   line   has   leading   whitespace.


===========================================================================
= Lesson 1.5: FIND AND TILL ON A LINE
===========================================================================

  These motions search the current line for a single character:

    [[psyc-modal-find-forward]] X   move to the next X
    [[psyc-modal-find-backward]] X   move to the previous X
    [[psyc-modal-till-forward]] X   move up to (just before) the next X
    [[psyc-modal-till-backward]] X   move up to (just after) the previous X

  These are precise — the position of `X' on the line is exact.  Combined
  with the editing actions in the next chapter, they're a power tool.

  Practice: from the start of the next line, press `[[psyc-modal-find-forward]] .', then `[[psyc-modal-till-forward]] ;',
  then `[[psyc-modal-find-backward]] (' (or whatever character makes sense).

  ---->   path = obj.method(arg1, arg2); print(path);


===========================================================================
= Lesson 2.1: SELECTION-FIRST EDITING
===========================================================================

  The big idea: in psyc-modal you SELECT first, then ACT.  A motion
  doesn't just move — it selects everything between the old and new
  point.  Look at the modeline as you press a motion: it flashes [S].

  Common selections:

    [[psyc-modal-word-next]]  [[psyc-modal-word-back]]  [[psyc-modal-word-end]]   word selections (motion implicitly selects)
    [[psyc-modal-select-line]]         select the WHOLE current line
    [[psyc-modal-select-line-above]]         extend selection to the line above
    [[psyc-modal-select-all]]         select the entire buffer
    [[psyc-modal-enter-select]]         toggle persistent SELECT mode
    [[psyc-modal-collapse]]         collapse selection to a single point

  Actions consume the current selection:

    [[psyc-modal-delete]]   delete (and yank into the register)
    [[psyc-modal-change]]   change — delete and enter INSERT mode
    [[psyc-modal-yank]]   yank (copy) without removing
    [[psyc-modal-toggle-case]]   toggle case
    [[psyc-modal-indent]]   indent       [[psyc-modal-dedent]]   dedent       [[psyc-modal-reindent]]   reindent

  Try `[[psyc-modal-word-next]]' followed by `[[psyc-modal-delete]]' on the next line to delete the next word.
  Then press `[[undo]]' (undo) to bring it back.

  ---->   delete    me    from    this    line.

  Now press `[[psyc-modal-select-line]]' to select the whole next line, then `[[psyc-modal-delete]]' to remove it.
  Press `[[undo]]' to undo.

  ---->   this entire line is fair game


===========================================================================
= Lesson 2.2: PASTING
===========================================================================

  Yanked or deleted text goes onto the kill ring.  Paste with:

    [[psyc-modal-paste-after]]   paste AFTER the cursor (or below the line, if line-oriented)
    [[psyc-modal-paste-before]]   paste BEFORE the cursor (or above the line)
    [[psyc-modal-replace-paste]]   replace the selection with the most recent yank

  Try this:
    1. Move onto the next ----> line.
    2. Press `[[psyc-modal-select-line]]' (select line) then `[[psyc-modal-yank]]' (yank).
    3. Press `[[psyc-modal-paste-after]]' to duplicate it below.
    4. Press `[[undo]]' to undo.

  ---->   duplicate me, please


===========================================================================
= Lesson 2.3: ENTERING INSERT MODE
===========================================================================

  Six entries cover almost every case:

    [[psyc-modal-insert-before]]   INSERT before the cursor (or selection start)
    [[psyc-modal-insert-after]]   INSERT after the cursor (or selection end)
    [[psyc-modal-insert-bol]]   INSERT at the first non-blank of the line
    [[psyc-modal-insert-eol]]   INSERT at the END of the line
    [[psyc-modal-open-below]]   open a new line BELOW and INSERT
    [[psyc-modal-open-above]]   open a new line ABOVE and INSERT

  In INSERT mode the buffer behaves like vanilla Emacs — keys insert
  text.  Press [[psyc-modal-enter-normal]] to return to NORMAL.

  Practice: capitalize `BAR' in the line below.  Move on the `b', press
  `[[psyc-modal-change]]' to change the next selection, type `BAR', press [[psyc-modal-enter-normal]].

  ---->   foo bar baz


===========================================================================
= Lesson 2.4: REPLACE, CASE, REPEAT
===========================================================================

  Smaller edits don't need a selection:

    [[psyc-modal-replace-char]] X   replace the character under the cursor with X
    [[psyc-modal-toggle-case]]     toggle case (works on selection too)
    [[repeat]]     repeat the last editing command

  Number prefix works: `4 [[psyc-modal-replace-char]] *' replaces four characters with `*'.

  Practice: fix the typo by moving onto `e' in `helo' and pressing `[[psyc-modal-replace-char]] e'.

  ---->   helo, world


===========================================================================
= Lesson 2.5: LINE OPERATIONS
===========================================================================

    [[psyc-modal-select-line]]   select the current line (extends if repeated)
    [[psyc-modal-select-line-above]]   extend selection to the line above
    [[psyc-modal-join-lines]]   join the current line with the next (single space between)
    [[psyc-modal-indent]]   indent selection (or current line)
    [[psyc-modal-dedent]]   dedent

  Try joining the next two lines with `[[psyc-modal-join-lines]]':

  ---->   this line should be
  ---->   joined into one


===========================================================================
= Lesson 3.1: TEXT OBJECTS
===========================================================================

  Text objects describe semantic chunks: a word, a paren group, a string.
  Press `[[psyc-modal-select-inside]] X' to select INSIDE object X (excluding delimiters), or
  `[[psyc-modal-select-around]] X' to select AROUND it (including delimiters).

  Common objects:

    w     word                              W     WORD
    (  ) [  ] {  } < >                      paired brackets
    \"  '  `                                 quoted strings
    f                                       function call (the args)

  Combinations to try:

    [[psyc-modal-select-inside]] w  +  [[psyc-modal-change]]   change inside word
    [[psyc-modal-select-around]] (  +  [[psyc-modal-delete]]   delete a parenthesized group, brackets and all
    [[psyc-modal-select-inside]] \"  +  [[psyc-modal-change]]   change inside a string

  Try `[[psyc-modal-select-inside]] w' then `[[psyc-modal-change]]' on the word `kitten' below, type `dog', [[psyc-modal-enter-normal]].

  ---->   the kitten chased the laser dot

  Try `[[psyc-modal-select-inside]] (' then `[[psyc-modal-delete]]' on the line below.  The parens stay, contents go.

  ---->   call_me(arg1, arg2, arg3)


===========================================================================
= Lesson 3.2: SURROUND
===========================================================================

  Surround commands operate on the CURRENT SELECTION (for add/wrap) or on
  the surrounding pair (for delete/replace):

    [[psyc-modal-surround-add]] X     surround the selection with X (and its match)
    [[psyc-modal-surround-delete]] X     delete the surrounding X / its match
    [[psyc-modal-surround-replace]] X Y   replace surrounding X with Y
    [[psyc-modal-wrap]] X     wrap selection AND its surrounding whitespace with X

  Note: opening and closing brackets are interchangeable as the argument.

  Try this:
    1. Put the cursor on `name' below.
    2. `[[psyc-modal-select-inside]] w' to select inside the word.
    3. `[[psyc-modal-surround-add]] \"' to wrap it in quotes.

  ---->   greet(name)

  Then on the next line: from inside the parens, press `[[psyc-modal-surround-delete]] (' to remove
  the parens entirely.

  ---->   foo(bar)


===========================================================================
= Lesson 3.3: STRUCTURAL EDITING
===========================================================================

  These commands manipulate s-expressions and bracketed structures:

    [[psyc-modal-slurp-forward]]   slurp forward — pull the next sibling INTO the current list
    [[psyc-modal-slurp-backward]]   slurp backward — pull the previous sibling INTO the list
    [[psyc-modal-barf-forward]]   barf forward — push the last element OUT of the list
    [[psyc-modal-barf-backward]]   barf backward — push the first element OUT of the list
    [[psyc-modal-splice]]   splice — remove the surrounding pair, leaving its contents
    [[psyc-modal-raise]]   raise — replace the enclosing form with the sexp at point
    [[psyc-modal-transpose-sexp]]   transpose two sibling sexps

  These shine in Lisps but work in any bracketed code.  Try `[[psyc-modal-slurp-forward]]' from
  inside the empty parens below to slurp `bar':

  ---->   (foo) bar baz

  Then `[[psyc-modal-barf-forward]]' to barf back:

  ---->   (foo bar baz)


===========================================================================
= Lesson 3.4: SEARCH
===========================================================================

    [[isearch-forward]]     start incremental search forward (Emacs isearch)
    [[psyc-modal-search-next]]     next match
    [[psyc-modal-search-prev]]     previous match
    [[psyc-modal-search-selection]]     search for the current selection (or word under cursor)
    [[psyc-modal-select-regex]]     within the current selection, select all regex matches
    [[psyc-modal-select-regex-all]]     split selection on a regex (puts a cursor at each match)

  Try `[[isearch-forward]]' for `fox' below, then press <Enter>, then `[[psyc-modal-search-next]]' a few times.

  ---->   the fox jumped over the fox.  another fox watched.


===========================================================================
= Lesson 3.5: MULTIPLE CURSORS
===========================================================================

  Ways to get multiple cursors:

    [[mc/mark-next-like-this]]      add a cursor on the next match of the current selection
    [[mc/mark-previous-like-this]]    add a cursor on the previous match
    [[psyc-modal-split-on-newlines]]    split the selection at every newline (one cursor per line)
    [[psyc-modal-for-each-line]]    run a command on each line of the selection
    [[psyc-modal-split-selection]]    split selection into pieces (FIFO ring)
    [[psyc-modal-paste-split]]    paste the next piece from the split ring

  Useful selection refinements while you have cursors:

    [[psyc-modal-keep-matching]]      keep only selections that match a regex (or ! for non-match)
    [[psyc-modal-shrink-to-line]]    shrink selection to a single line

  Try this: select the line `apple banana cherry' below with `[[psyc-modal-select-line]]',
  press `[[psyc-modal-split-on-newlines]]' to put a cursor on each line (single line here),
  then `[[psyc-modal-toggle-case]]' to toggle case.

  ---->   apple banana cherry


===========================================================================
= Lesson 4.1: UNDO, REDO, REPEAT
===========================================================================

    [[undo]]   undo
    [[undo-redo]]   redo (undo the undo)
    [[repeat]]   repeat the last editing command (not motion)

  Repeat is powerful: change a word with `[[psyc-modal-select-inside]] w [[psyc-modal-change]] new [[psyc-modal-enter-normal]]', then
  walk to the next word with `[[psyc-modal-word-next]]' and press `[[repeat]]' to apply the same change
  again.

  Try it: `[[psyc-modal-change]]' the word, type `pear', [[psyc-modal-enter-normal]], `[[psyc-modal-word-next]]' to next, `[[repeat]]':

  ---->   apple banana cherry


===========================================================================
= Lesson 4.2: NAVIGATION HELPERS
===========================================================================

  Goto map:
    [[xref-find-definitions]]   jump to the DEFINITION of the symbol under cursor (xref)
    [[xref-find-references]]   list REFERENCES (xref)
    [[next-buffer]]   next buffer            [[previous-buffer]]   previous buffer
    [[pop-global-mark]]   pop to the previous mark (where you were before the jump)
    [[xref-go-forward]]   forward through the jump history
    [[push-mark-command]]   push the current location onto the mark ring

  View map (the `z' prefix scrolls without moving the cursor):
    [[recenter-top-bottom]]   center the current line
    z t   move current line to top of window
    z b   move current line to bottom
    [[scroll-up-line]] / [[scroll-down-line]]        scroll one line down / up
    z C-d / z C-u    half page down / up


===========================================================================
= Lesson 4.3: THE SPACE LEADER
===========================================================================

  SPC opens the leader map — the home of file/buffer/window/help
  commands you used to reach via `C-x'.  Highlights:

    [[find-file]]   find file                     [[switch-to-buffer]]   switch buffer
    [[project-find-file]]   project find file             [[save-buffer]]   save buffer
    [[kill-current-buffer]]   kill current buffer           [[quit-window]]   quit window
    [[consult-ripgrep]]   ripgrep across project        [[consult-line]]   consult-line
    [[consult-imenu]]   imenu in this file            [[consult-imenu-multi]]   imenu across project
    [[flymake-show-buffer-diagnostics]]   show buffer diagnostics       [[flymake-show-project-diagnostics]]   project diagnostics
    [[clipboard-kill-ring-save]]   copy to system clipboard      [[clipboard-yank]]   paste from clipboard
    [[comment-dwim]]   comment-dwim                  [[comment-region]]   comment-region
    [[eglot-code-actions]]   eglot code actions            [[eglot-rename]]   eglot rename
    [[magit-status]]  magit status   [[magit-blame-addition]]  blame   [[magit-log-buffer-file]]  log

  Two more you'll use a lot:

    [[execute-extended-command@SPC SPC]]   M-x (execute-extended-command)
    SPC h     help-map (`[[describe-key]]' describes a key, etc.)

  Window management lives under SPC w (or the shorter C-w binding):

    [[split-window-below@SPC]] / [[split-window-right@SPC]]   split below / right
    [[windmove-left@SPC]] [[windmove-down@SPC]] [[windmove-up@SPC]] [[windmove-right@SPC]] move between windows
    [[windmove-swap-states-left@SPC]] [[windmove-swap-states-down@SPC]] [[windmove-swap-states-up@SPC]] [[windmove-swap-states-right@SPC]] swap windows
    [[delete-window@SPC]]       delete window
    [[delete-other-windows@SPC]]       delete other windows


===========================================================================
= Lesson 4.4: GOD MODE — OCCASIONAL EMACS KEYS
===========================================================================

  When you need a raw Emacs key sequence without leaving NORMAL mode,
  press `[[psyc-modal-god-execute]]' and type the keys WITHOUT holding Control:

    [[psyc-modal-god-execute]] x s    -> C-x C-s  (save)
    [[psyc-modal-god-execute]] x b    -> C-x C-b  (list buffers, in vanilla)
    [[psyc-modal-god-execute]] g f    -> C-M-f    (forward sexp, with `g' as Meta prefix)
    [[psyc-modal-god-execute]] G f    -> C-M-f also (G is C-M-)
    [[psyc-modal-god-execute]] SPC k  -> a literal `C-SPC' followed by `k'

  which-key shows the popup as you go.  Useful for the long tail of
  Emacs commands you don't bind elsewhere.


===========================================================================
= Lesson 4.5: KEYBOARD MACROS
===========================================================================

  Macros record a sequence of keys and replay them.

    [[kmacro-start-macro-or-insert-counter]]       start recording (a second press stops if no count given)
    [[kmacro-end-or-call-macro]]       end recording / replay the last macro
    [[apply-macro-to-region-lines]]     apply the macro to each line in the selection

  Workflow: `[[kmacro-start-macro-or-insert-counter]]', do the edit you want, `[[kmacro-start-macro-or-insert-counter]]' to stop.  Move to the next
  spot, press `[[kmacro-end-or-call-macro]]' to replay.  For lots of lines: select them with `[[psyc-modal-select-line]]' a
  bunch (or `[[psyc-modal-select-all]]' for the buffer), then `[[apply-macro-to-region-lines]]'.


===========================================================================
= Lesson 4.6: BRACKETED MOTION
===========================================================================

  The `[' and `]' prefixes jump between things:

    [[flymake-goto-next-error]]   next diagnostic     [[flymake-goto-prev-error]]   previous diagnostic
    [[end-of-defun]]   end of defun        [[beginning-of-defun]]   beginning of defun
    [[forward-paragraph]]   next paragraph      [[backward-paragraph]]   previous paragraph
    [[psyc-modal-next-comment]]   next comment        [[psyc-modal-prev-comment]]   previous comment
    [[diff-hl-next-hunk]]   next git hunk       [[diff-hl-previous-hunk]]   previous git hunk
    ] SPC add a blank line BELOW (without moving)
    [ SPC add a blank line ABOVE


===========================================================================
= Lesson 4.7: HELP
===========================================================================

  From NORMAL mode, the `?' prefix opens the help map:

    [[psyc-tutor-quick-reference]]   live quick reference (this tutor's companion)
    [[psyc-tutor]]   open this tutor
    [[psyc-modal-show-keys]]   show all current modal keys
    [[which-key-show-major-mode]]   which-key popup for the major-mode keymap
    [[psyc-modal-preview-motions]]   overlay where each motion key would land — press
          another motion key to dismiss the overlay and run that motion.

  And from anywhere, `[[which-key-show-top-level]]' triggers a top-level which-key popup.

  Standard Emacs help is reachable through the help map:

    [[describe-key]]    describe-key
    [[describe-function]]    describe-function
    [[describe-variable]]    describe-variable
    [[describe-mode]]    describe-mode


===========================================================================
= Lesson 4.8: ADVANCED EDITING (FOR LATER)
===========================================================================

  When you're comfortable with the basics, these earn their place:

    [[psyc-modal-delete-no-yank]]   delete WITHOUT yanking      [[psyc-modal-change-no-yank]]   change WITHOUT yanking
    [[psyc-modal-split-on-newlines]]   split selection at newlines (one cursor per line)
    [[psyc-modal-for-each-line]]   for-each-line (treat selection as a series of lines)
    [[psyc-modal-ensure-forward]]   ensure selection points forward (anchor at start)
    [[expreg-expand]]   expand region (semantic grow)
    [[expreg-contract]]   contract region
    [[psyc-modal-keep-matching]]     keep selections matching a regex (`!K' to invert)
    [[psyc-modal-pipe-shell]]     pipe selection through a shell command
    [[psyc-modal-collapse]]     collapse selection to point
    [[psyc-modal-flip-selection]]   flip selection direction

  Worth knowing:

    [[pp-eval-expression]]      pp-eval-expression (try Lisp without leaving the buffer)
    [[vertico-repeat]] / [[consult-mark]]   vertico-repeat / consult-mark


===========================================================================
=                       Y O U   A R E   D O N E                           =
===========================================================================

  You've covered the editing surface.  A few habits to build:

    1. Stay in NORMAL.  Pop into INSERT, type, pop back out.
    2. Compose: a motion that selects + a verb that consumes is the loop.
    3. Use `[[repeat]]' to repeat — it pays for itself within the first afternoon.
    4. When you forget a key, ask:  [[psyc-tutor-quick-reference]]    (live reference)
                                    [[psyc-modal-show-keys]]   (full key list)
                                    [[describe-key]]   (describe a specific key)

  Run `M-x psyc-tutor' any time to come back here.  Happy editing.
")

(defvar psyc-tutor-mode-map
  (let ((m (make-sparse-keymap)))
    m)
  "Keymap for `psyc-tutor-mode' (currently empty — modal owns the keys).")

(define-derived-mode psyc-tutor-mode fundamental-mode "Tutor"
  "Major mode for the psyc-modal tutor buffer.

The buffer is an editable scratch area pre-filled with a vimtutor-style
walkthrough.  psyc-modal is enabled in normal state — practice the
techniques on the buffer itself."
  :group 'psyc-modal
  (setq-local truncate-lines nil)
  (psyc-modal-mode 1)
  (psyc-modal-enter-normal))

;;;###autoload
(defun psyc-tutor ()
  "Open a fresh copy of the psyc-modal tutor.

Calling this when the tutor buffer already exists kills it first, so the
practice text is reset."
  (interactive)
  (when-let ((existing (get-buffer psyc-tutor--buffer-name)))
    (kill-buffer existing))
  (let ((buf (get-buffer-create psyc-tutor--buffer-name)))
    (with-current-buffer buf
      (insert (psyc-tutor--render-template psyc-tutor--text-template))
      (goto-char (point-min))
      (psyc-tutor-mode)
      (set-buffer-modified-p nil))
    (pop-to-buffer buf)))

(provide 'psyc-tutor)
;;; psyc-tutor.el ends here
