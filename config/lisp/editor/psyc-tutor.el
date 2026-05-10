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
  "Return the key string bound to CMD in KEYMAP (default: normal-map)."
  (when-let ((keys (where-is-internal cmd (or keymap psyc-modal-normal-map) t)))
    (key-description keys)))

(defun psyc-tutor--reference-key (cmd)
  "Return a display key for CMD, falling back to its symbol name."
  (or (psyc-tutor--key-for-command cmd)
      (symbol-name cmd)))

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
          (cons "<escape>" "return to normal state")))
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
          (cons (psyc-tutor--reference-alt "??" "? t" "? k" "? m")
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

(defconst psyc-tutor--text "\
===========================================================================
=                W E L C O M E   T O   T H E   T U T O R                  =
===========================================================================

  psyc-modal is a Helix-inspired modal editor for Emacs.  In about 30
  minutes you can pick up enough to edit comfortably.

  HOW TO USE THIS TUTOR
    - This buffer is fully editable.  Try every command on the lines
      marked with ---->.  Some lines start out broken on purpose.
    - The modeline shows your state: [N] normal, [S] select, [I] insert.
    - <Escape> always returns you to NORMAL mode.  Reach for it freely.
    - To restart with a fresh copy:    M-x psyc-tutor
    - To see the live key reference:   M-x psyc-tutor-quick-reference
                                       (or `? ?' from normal mode)

  GROUND RULES
    1. Most lessons follow this pattern: read the explanation, then make
       the broken `---->' line match the `---->' line below it.
    2. The keys shown are the defaults.  If you've rebound something,
       trust the live reference.
    3. If you get lost, press <Escape> and start the lesson over.

  Press <Escape>, then `j' a few times to scroll down.  Begin Lesson 1.


===========================================================================
= Lesson 1.1: THE THREE MODES
===========================================================================

  Normal [N] is for moving and issuing commands.
  Select [S] is normal mode with an active selection that grows with motion.
  Insert [I] is for typing text.

  Transitions you'll use constantly:

    i  a    enter INSERT before / after the cursor
    o  O    open a line below / above and enter INSERT
    v       toggle SELECT mode (movements extend the selection)
    ;       collapse a selection back to a single point
    <Escape> always returns to NORMAL

  Try this on the ----> line: press `i', type the missing word `quick',
  then press <Escape>.

  ---->   The brown fox jumps.
  ---->   The quick brown fox jumps.


===========================================================================
= Lesson 1.2: BASIC MOTION (h j k l)
===========================================================================

  In NORMAL mode the cursor moves with:

    h   left
    j   down
    k   up
    l   right

  Numeric prefix repeats: `5l' moves five characters right, `3j' moves
  three lines down.  This works with most motion commands.

  Move to the start of the line below using only h/j/k/l, then back here.

  ---->   PRACTICE: jump around this line until h-j-k-l feel automatic.


===========================================================================
= Lesson 1.3: WORD MOTION
===========================================================================

  Words are blocks of letters/digits/underscore separated by punctuation.

    w   jump to the START of the next word
    b   jump BACK to the start of the previous word
    e   jump to the END of the current word

  WORDS (uppercase) are whitespace-delimited — punctuation does NOT split
  them.  Use them when you want to fly past code:

    W   next WORD start
    B   previous WORD start
    E   current WORD end

  Practice on the next line by walking it with `w', then again with `W'.

  ---->   foo.bar(qux, baz);   one_two-three   it's-a-trap


===========================================================================
= Lesson 1.4: LINE AND BUFFER MOTION
===========================================================================

  The `g' prefix opens the GOTO map.  The most-used members:

    g h   beginning of line
    g l   end of line
    g s   first non-blank character on the line
    g g   beginning of buffer
    g e   end of buffer
    G N   go to line N (e.g. `42 G' or `G' from `:G')

  Window-relative jumps live in the same map:

    g t   top of visible window
    g c   center
    g b   bottom

  Practice: from anywhere on the line below, press `g s', then `g l',
  then `g h'.

  ---->       this   line   has   leading   whitespace.


===========================================================================
= Lesson 1.5: FIND AND TILL ON A LINE
===========================================================================

  These motions search the current line for a single character:

    f X   move to the next X
    F X   move to the previous X
    t X   move up to (just before) the next X
    T X   move up to (just after) the previous X

  These are precise — the position of `X' on the line is exact.  Combined
  with the editing actions in the next chapter, they're a power tool.

  Practice: from the start of the next line, press `f .', then `t ;',
  then `F (' (or whatever character makes sense).

  ---->   path = obj.method(arg1, arg2); print(path);


===========================================================================
= Lesson 2.1: SELECTION-FIRST EDITING
===========================================================================

  The big idea: in psyc-modal you SELECT first, then ACT.  A motion
  doesn't just move — it selects everything between the old and new
  point.  Look at the modeline as you press a motion: it flashes [S].

  Common selections:

    w  b  e   word selections (motion implicitly selects)
    x         select the WHOLE current line
    X         extend selection to the line above
    %         select the entire buffer
    v         toggle persistent SELECT mode
    ;         collapse selection to a single point

  Actions consume the current selection:

    d   delete (and yank into the register)
    c   change — delete and enter INSERT mode
    y   yank (copy) without removing
    ~   toggle case
    >   indent       <   dedent       =   reindent

  Try `w' followed by `d' on the next line to delete the next word.
  Then press `u' (undo) to bring it back.

  ---->   delete    me    from    this    line.

  Now press `x' to select the whole next line, then `d' to remove it.
  Press `u' to undo.

  ---->   this entire line is fair game


===========================================================================
= Lesson 2.2: PASTING
===========================================================================

  Yanked or deleted text goes onto the kill ring.  Paste with:

    p   paste AFTER the cursor (or below the line, if line-oriented)
    P   paste BEFORE the cursor (or above the line)
    R   replace the selection with the most recent yank

  Try this:
    1. Move onto the next ----> line.
    2. Press `x' (select line) then `y' (yank).
    3. Press `p' to duplicate it below.
    4. Press `u' to undo.

  ---->   duplicate me, please


===========================================================================
= Lesson 2.3: ENTERING INSERT MODE
===========================================================================

  Six entries cover almost every case:

    i   INSERT before the cursor (or selection start)
    a   INSERT after the cursor (or selection end)
    I   INSERT at the first non-blank of the line
    A   INSERT at the END of the line
    o   open a new line BELOW and INSERT
    O   open a new line ABOVE and INSERT

  In INSERT mode the buffer behaves like vanilla Emacs — keys insert
  text.  Press <Escape> to return to NORMAL.

  Practice: capitalize `BAR' in the line below.  Move on the `b', press
  `c' to change the next selection, type `BAR', press <Escape>.

  ---->   foo bar baz


===========================================================================
= Lesson 2.4: REPLACE, CASE, REPEAT
===========================================================================

  Smaller edits don't need a selection:

    r X   replace the character under the cursor with X
    ~     toggle case (works on selection too)
    .     repeat the last editing command

  Number prefix works: `4 r *' replaces four characters with `*'.

  Practice: fix the typo by moving onto `e' in `helo' and pressing `r e'.

  ---->   helo, world


===========================================================================
= Lesson 2.5: LINE OPERATIONS
===========================================================================

    x   select the current line (extends if repeated)
    X   extend selection to the line above
    J   join the current line with the next (single space between)
    >   indent selection (or current line)
    <   dedent

  Try joining the next two lines with `J':

  ---->   this line should be
  ---->   joined into one


===========================================================================
= Lesson 3.1: TEXT OBJECTS
===========================================================================

  Text objects describe semantic chunks: a word, a paren group, a string.
  Press `m i X' to select INSIDE object X (excluding delimiters), or
  `m a X' to select AROUND it (including delimiters).

  Common objects:

    w     word                              W     WORD
    (  ) [  ] {  } < >                      paired brackets
    \"  '  `                                 quoted strings
    f                                       function call (the args)

  Combinations to try:

    m i w  +  c   change inside word
    m a (  +  d   delete a parenthesized group, brackets and all
    m i \"  +  c   change inside a string

  Try `m i w' then `c' on the word `kitten' below, type `dog', <Escape>.

  ---->   the kitten chased the laser dot

  Try `m i (' then `d' on the line below.  The parens stay, contents go.

  ---->   call_me(arg1, arg2, arg3)


===========================================================================
= Lesson 3.2: SURROUND
===========================================================================

  Surround commands operate on the CURRENT SELECTION (for add/wrap) or on
  the surrounding pair (for delete/replace):

    m s X   surround the selection with X (and its match)
    m d X   delete the surrounding X / its match
    m r X Y replace surrounding X with Y
    m w X   wrap selection AND its surrounding whitespace with X

  Note: opening and closing brackets are interchangeable as the argument.

  Try this:
    1. Put the cursor on `name' below.
    2. `m i w' to select inside the word.
    3. `m s \"' to wrap it in quotes.

  ---->   greet(name)

  Then on the next line: from inside the parens, press `m d (' to remove
  the parens entirely.

  ---->   foo(bar)


===========================================================================
= Lesson 3.3: STRUCTURAL EDITING
===========================================================================

  These commands manipulate s-expressions and bracketed structures:

    m )   slurp forward — pull the next sibling INTO the current list
    m (   slurp backward — pull the previous sibling INTO the list
    m }   barf forward — push the last element OUT of the list
    m {   barf backward — push the first element OUT of the list
    m S   splice — remove the surrounding pair, leaving its contents
    m R   raise — replace the enclosing form with the sexp at point
    m T   transpose two sibling sexps

  These shine in Lisps but work in any bracketed code.  Try `m )' from
  inside the empty parens below to slurp `bar':

  ---->   (foo) bar baz

  Then `m }' to barf back:

  ---->   (foo bar baz)


===========================================================================
= Lesson 3.4: SEARCH
===========================================================================

    /     start incremental search forward (Emacs isearch)
    n     next match
    N     previous match
    *     search for the current selection (or word under cursor)
    s     within the current selection, select all regex matches
    S     split selection on a regex (puts a cursor at each match)

  Try `/' for `fox' below, then press <Enter>, then `n' a few times.

  ---->   the fox jumped over the fox.  another fox watched.


===========================================================================
= Lesson 3.5: MULTIPLE CURSORS
===========================================================================

  Two ways to get multiple cursors:

    C        add a cursor on the next match of the current selection
    M-C      add a cursor on the previous match
    M-S      split the selection on whitespace, one cursor per piece
    M-'      split the selection at every newline (one cursor per line)
    M-p      paste with one entry of the kill ring per cursor

  Useful selection refinements while you have cursors:

    K        keep only selections that match a regex (or ! for non-match)
    M-x      shrink selection to a single line

  Try this: select the line `apple banana cherry' below with `x',
  press `M-S' to split into three cursors, then `~' to toggle case.

  ---->   apple banana cherry


===========================================================================
= Lesson 4.1: UNDO, REDO, REPEAT
===========================================================================

    u   undo
    U   redo (undo the undo)
    .   repeat the last editing command (not motion)

  Repeat is powerful: change a word with `m i w c new <Escape>', then
  walk to the next word with `w' and press `.' to apply the same change
  again.

  Try it: `c' the word, type `pear', <Escape>, `w' to next, `.':

  ---->   apple banana cherry


===========================================================================
= Lesson 4.2: NAVIGATION HELPERS
===========================================================================

  Goto map:
    g d   jump to the DEFINITION of the symbol under cursor (xref)
    g r   list REFERENCES (xref)
    g n   next buffer            g p   previous buffer
    C-o   pop to the previous mark (where you were before the jump)
    C-i   forward through the jump history
    C-s   push the current location onto the mark ring

  View map (the `z' prefix scrolls without moving the cursor):
    z z   center the current line
    z t   move current line to top of window
    z b   move current line to bottom
    z j / z k        scroll one line down / up
    z C-d / z C-u    half page down / up


===========================================================================
= Lesson 4.3: THE SPACE LEADER
===========================================================================

  `SPC' opens the leader map — the home of file/buffer/window/help
  commands you used to reach via `C-x'.  Highlights:

    SPC f   find file                     SPC b   switch buffer
    SPC F   project find file             SPC s   save buffer
    SPC d   kill current buffer           SPC q   quit window
    SPC /   ripgrep across project        SPC l   consult-line
    SPC i   imenu in this file            SPC S   imenu across project
    SPC e   show buffer diagnostics       SPC E   project diagnostics
    SPC y   copy to system clipboard      SPC p   paste from clipboard
    SPC c   comment-dwim                  SPC C   comment-region
    SPC a   eglot code actions            SPC r   eglot rename
    SPC g g  magit status   SPC g b  blame   SPC g l  log

  Two more you'll use a lot:

    SPC SPC   M-x (execute-extended-command)
    SPC h     help-map (replaces C-h: `SPC h k' describes a key, etc.)

  Window management lives under `SPC w' (or `C-w' from normal):

    SPC w s / v   split below / right
    SPC w h j k l move between windows
    SPC w H J K L swap windows
    SPC w q       delete window
    SPC w o       delete other windows


===========================================================================
= Lesson 4.4: GOD MODE — OCCASIONAL EMACS KEYS
===========================================================================

  When you need a raw Emacs key sequence without leaving NORMAL mode,
  press `,' (comma) and type the keys WITHOUT holding Control:

    , x s    -> C-x C-s  (save)
    , x b    -> C-x C-b  (list buffers, in vanilla)
    , g f    -> C-M-f    (forward sexp, with `g' as Meta prefix)
    , G f    -> C-M-f also (G is C-M-)
    , SPC k  -> a literal `C-SPC' followed by `k'

  which-key shows the popup as you go.  Useful for the long tail of
  Emacs commands you don't bind elsewhere.


===========================================================================
= Lesson 4.5: KEYBOARD MACROS
===========================================================================

  Macros record a sequence of keys and replay them.

    Q       start recording (a second Q stops if no count given)
    q       end recording / replay the last macro
    M-q     apply the macro to each line in the selection

  Workflow: `Q', do the edit you want, `Q' to stop.  Move to the next
  spot, press `q' to replay.  For lots of lines: select them with `x' a
  bunch (or `%' for the buffer), then `M-q'.


===========================================================================
= Lesson 4.6: BRACKETED MOTION
===========================================================================

  The `[' and `]' prefixes jump between things:

    ] d   next diagnostic   [ d   previous diagnostic
    ] f   end of defun      [ f   beginning of defun
    ] p   next paragraph    [ p   previous paragraph
    ] c   next comment      [ c   previous comment
    ] g   next git hunk     [ g   previous git hunk
    ] SPC add a blank line BELOW (without moving)
    [ SPC add a blank line ABOVE


===========================================================================
= Lesson 4.7: HELP
===========================================================================

  From NORMAL mode, the `?' prefix opens the help map:

    ? ?   live quick reference (this tutor's companion)
    ? t   open this tutor
    ? k   show all current modal keys
    ? m   which-key popup for the major-mode keymap

  And from anywhere, `<f5>' triggers a top-level which-key popup.

  Standard Emacs help is reachable through `SPC h':

    SPC h k    describe-key
    SPC h f    describe-function
    SPC h v    describe-variable
    SPC h m    describe-mode


===========================================================================
= Lesson 4.8: ADVANCED EDITING (FOR LATER)
===========================================================================

  When you're comfortable with the basics, these earn their place:

    M-d   delete WITHOUT yanking      M-c   change WITHOUT yanking
    M-s   split selection at newlines (one cursor per line)
    M-S   for-each-line (treat selection as a series of lines)
    M-:   ensure selection points forward (anchor at start)
    M-o   expand region (semantic grow)
    M-i   contract region
    K     keep selections matching a regex (`!K' to invert)
    |     pipe selection through a shell command
    ;     collapse selection to point
    M-;   flip selection direction

  Worth knowing:

    SPC ;        pp-eval-expression (try Lisp without leaving the buffer)
    SPC ' / SPC j   vertico-repeat / consult-mark


===========================================================================
=                       Y O U   A R E   D O N E                           =
===========================================================================

  You've covered the editing surface.  A few habits to build:

    1. Stay in NORMAL.  Pop into INSERT, type, pop back out.
    2. Compose: a motion that selects + a verb that consumes is the loop.
    3. Use `.' to repeat — it pays for itself within the first afternoon.
    4. When you forget a key, ask:  ? ?    (live reference)
                                    ? k   (full key list)
                                    SPC h k   (describe a specific key)

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
      (insert psyc-tutor--text)
      (goto-char (point-min))
      (psyc-tutor-mode)
      (set-buffer-modified-p nil))
    (pop-to-buffer buf)))

(provide 'psyc-tutor)
;;; psyc-tutor.el ends here
