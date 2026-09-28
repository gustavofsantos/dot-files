;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Doom, shaped after config/nvim + config/tmux:
;;   tmux session  -> Doom workspace (one per project)
;;   tmux pane     -> Emacs window (C-h/j/k/l cross into tmux panes under `emacs -nw')
;;   telescope     -> vertico/consult, on the same <leader> letters as nvim
;; `C-h v' / `C-h f' (or `SPC H v' / `SPC H f') on any name below explains it.

;;; UI

(defconst gs/themes '(cursorized-dark . cursorized-light) ; themes/, ported from nvim
  "(DARK . LIGHT), picked from the OS appearance.")

(setq doom-theme gs/themes
      doom-font (font-spec :family "CommitMono" :size 16) ; px; ghostty uses 12pt
      display-line-numbers-type 'relative
      scroll-margin 3
      create-lockfiles nil
      org-directory "~/org/"
      doom-modeline-buffer-file-name-style 'relative-to-project
      eldoc-echo-area-use-multiline-p nil) ; one-line echo area, no layout shift

;; Doom picks the variant once at startup; this keeps following the OS while
;; Emacs runs, like nvim's system_theme.lua (portal signal on Linux).
(defun gs/follow-system-theme (dark)
  "Switch to the DARK or light member of `gs/themes'."
  (let ((want (if dark (car gs/themes) (cdr gs/themes)))
        (other (if dark (cdr gs/themes) (car gs/themes))))
    (unless (custom-theme-enabled-p want)
      (disable-theme other)
      (load-theme want t))))

(cond ((boundp 'ns-system-appearance-change-functions)
       (add-hook 'ns-system-appearance-change-functions
                 (lambda (appearance) (gs/follow-system-theme (eq appearance 'dark)))))
      ((and (featurep :system 'linux) (require 'dbus nil t)
            (ignore-errors (dbus-ping :session "org.freedesktop.portal.Desktop" 500)))
       (dbus-register-signal
        :session "org.freedesktop.portal.Desktop" "/org/freedesktop/portal/desktop"
        "org.freedesktop.portal.Settings" "SettingChanged"
        (lambda (namespace key value)
          (when (and (equal namespace "org.freedesktop.appearance")
                     (equal key "color-scheme"))
            ;; 1 = prefer dark; 0 (no preference) and 2 read as light, as in Doom
            (gs/follow-system-theme (eq 1 (car-safe (flatten-list value)))))))))

;; An OS theme switch also sends a font-settings change, and Emacs answers it
;; by putting the system UI font on `default' (Doom's font has no :user-spec to
;; keep). Re-apply Doom's fonts after it.
(advice-add #'font-setting-change-default-font :after
            (lambda (&rest _) (doom-init-fonts-h 'reload)))

;;; LSP — reuse the servers Mason already installed for nvim

(let ((mason-bin (expand-file-name "~/.local/share/nvim/mason/bin")))
  (when (file-directory-p mason-bin)
    (add-to-list 'exec-path mason-bin)
    (setenv "PATH" (concat mason-bin path-separator (getenv "PATH")))))

(set-eglot-client! 'kotlin-mode '("kotlin-lsp" "--stdio"))

;;; Projects = the same list tmux-sessionizer offers (bin/project-dirs)

(defvar gs--project-dirs nil
  "Truenames of the directories `project-dirs' prints, as directory names.")

(defun gs/project-dirs (&optional refresh)
  "Directories from the shared `project-dirs' script, cached unless REFRESH."
  (when (or refresh (null gs--project-dirs))
    (let ((bin (or (executable-find "project-dirs")
                   (expand-file-name "~/.bin/project-dirs"))))
      (setq gs--project-dirs
            (when (file-executable-p bin)
              (mapcar (lambda (d) (file-name-as-directory (file-truename d)))
                      (process-lines bin))))))
  gs--project-dirs)

(defun gs/projectile-root-from-project-dirs (dir)
  "Nearest ancestor of DIR that `project-dirs' lists.
Lets a monorepo child (backend-services/applications/*) be its own project,
as it is its own tmux session, instead of resolving to the repo's .git root."
  (let ((dirs (gs/project-dirs)))
    (locate-dominating-file
     dir (lambda (d) (member (file-name-as-directory (file-truename d)) dirs)))))

(defun gs/project-name (root)
  "Name a project like tmux-sessionizer names a session.
A worktree under <project>-worktrees/<branch> becomes <project>-<branch>."
  (let* ((dir (directory-file-name root))
         (name (file-name-nondirectory dir))
         (parent (file-name-nondirectory (directory-file-name (file-name-directory dir)))))
    (if (string-suffix-p "-worktrees" parent)
        (format "%s-%s" (string-remove-suffix "-worktrees" parent) name)
      name)))

(after! projectile
  (setq projectile-project-name-function #'gs/project-name
        projectile-project-root-functions
        (append '(projectile-root-local gs/projectile-root-from-project-dirs)
                (remq 'projectile-root-local projectile-project-root-functions)))
  ;; `SPC p p' offers the same list, not only projects already visited
  (dolist (dir (gs/project-dirs))
    (projectile-add-known-project (abbreviate-file-name dir))))

;; Telescope-style fuzzy file picking: each space-separated word matches as a
;; literal substring or, failing that, as its characters in order anywhere in
;; the path (`cfgpk' finds config/pack.lua). Scoped to project files so
;; M-x and buffer switching keep plain orderless.
(after! orderless
  (orderless-define-completion-style gs/orderless-fuzzy
    (orderless-matching-styles '(orderless-literal orderless-flex)))
  (setf (alist-get 'project-file completion-category-overrides)
        '((styles gs/orderless-fuzzy basic))))

;;; Workspaces = tmux sessions

(setq +workspaces-on-switch-project-behavior t) ; every project gets its own workspace

(defun gs/sessionizer (&optional workspaces-only)
  "Pick an open workspace or a project directory, like tmux-sessionizer.
A directory opens (or reuses) the workspace named after its project.
With WORKSPACES-ONLY, offer open workspaces only (tmux-sessionizer -s)."
  (interactive)
  (let* ((workspaces (+workspace-list-names))
         (dirs (unless workspaces-only
                 (mapcar #'abbreviate-file-name (gs/project-dirs 'refresh))))
         (choice (completing-read "→ " (append workspaces dirs) nil t)))
    (if (member choice workspaces)
        (+workspace-switch choice)
      (+workspaces-switch-to-project-h (expand-file-name choice)))))

(defun gs/sessionizer-workspaces ()
  "Switch between open workspaces only."
  (interactive)
  (gs/sessionizer t))

;;; Windows <-> tmux panes (vim-tmux-navigator / Navigator.nvim)

(defun gs/navigate (direction)
  "Select the window in DIRECTION; at the frame edge, move to the tmux pane."
  (let ((window (window-in-direction direction)))
    (cond (window (select-window window))
          ((and (getenv "TMUX") (not (display-graphic-p)))
           (call-process "tmux" nil 0 nil "select-pane"
                         (pcase direction ('left "-L") ('down "-D") ('up "-U") ('right "-R"))))
          (t (user-error "No window %s" direction)))))

(map! :map general-override-mode-map
      :nm "C-h" (cmd! (gs/navigate 'left))
      :nm "C-j" (cmd! (gs/navigate 'down))
      :nm "C-k" (cmd! (gs/navigate 'up))
      :nm "C-l" (cmd! (gs/navigate 'right))
      :ni "C-t" #'+ghostel/toggle)          ; toggleterm

(after! ghostel
  (setq ghostel-module-auto-install 'download)) ; prebuilt libghostty-vt module

;; Line numbers in a terminal buffer only cause layout shift: the gutter width
;; follows the line count, and anything toggling the mode (Doom's per-mode
;; hooks, `doom/toggle-line-numbers') resizes the text area, so the PTY columns
;; jump and full-screen TUIs like Claude Code redraw.
(add-hook! '(ghostel-mode-hook) (display-line-numbers-mode -1))
;; Same class of shift in file buffers: never shrink, and start wide.
(setq display-line-numbers-grow-only t
      display-line-numbers-width-start t)
;;; Terminals = agents and commands in a right-side panel, per workspace

(set-popup-rule! "^\\*term:" :side 'right :size 0.4 :select t :quit nil :ttl nil)

(defvar gs/term-commands '("claude" "cursor-agent")
  "Offered by `gs/term'; any other command can be typed.")

(defun gs/term--prefix ()
  (format "*term:%s:" (+workspace-current-name)))

(defun gs/term--live-p (buf)
  (and (buffer-live-p buf)
       (eq (buffer-local-value 'major-mode buf) 'ghostel-mode)
       (process-live-p (buffer-local-value 'ghostel--process buf))))

(defun gs/term-buffers ()
  "This workspace's live terminals, most recent first.
Leftovers without a live process (e.g. restored by a session) are killed."
  (let ((prefix (gs/term--prefix)) live)
    (dolist (buf (buffer-list))
      (when (string-prefix-p prefix (buffer-name buf))
        (if (gs/term--live-p buf) (push buf live) (kill-buffer buf))))
    (nreverse live)))

(defun gs/term--show (buf)
  (if-let* ((win (get-buffer-window buf)))
      (select-window win)
    (pop-to-buffer buf)))

(defun gs/term--start (command)
  "Open a new shell at the project root and run COMMAND in it (none: plain shell)."
  (let ((default-directory (or (doom-project-root) default-directory)))
    (dlet ((ghostel-buffer-name
            (format "%s%s*" (gs/term--prefix)
                    (if (string-blank-p command) "shell" (car (split-string command))))))
      (with-current-buffer (ghostel t) ; t: always a new instance, <2>, <3>...
        (setq-local ghostel-buffer-name-function nil) ; keep the name persp tracks
        (unless (string-blank-p command)
          (ghostel-send-string (concat command "\r")))
        (current-buffer)))))

(defun gs/term ()
  "Show one of this workspace's terminals, or type a command to open a new one.
An empty command opens a plain shell."
  (interactive)
  (let* ((names (mapcar #'buffer-name (gs/term-buffers)))
         (choice (completing-read "Terminal or command: "
                                  (append names gs/term-commands))))
    (if (member choice names)
        (gs/term--show (get-buffer choice))
      (gs/term--start choice))))

(defun gs/term-jump ()
  "Jump between the code and this workspace's last-used terminal."
  (interactive)
  (cond ((string-prefix-p (gs/term--prefix) (buffer-name))
         (select-window (get-mru-window nil nil t)))
        ((car (gs/term-buffers)) (gs/term--show (car (gs/term-buffers))))
        (t (call-interactively #'gs/term))))

(defun gs/term-toggle ()
  "Hide the terminal panel, or show the last-used terminal. Hiding keeps it running."
  (interactive)
  (if-let* ((win (seq-some #'get-buffer-window (gs/term-buffers))))
      (delete-window win)
    (gs/term-jump)))

(defun gs/term-send-reference (beg end)
  "Type an @path#Lx-y reference to the region (or @path) into the last-used terminal."
  (interactive (if (use-region-p) (list (region-beginning) (region-end)) (list nil nil)))
  (let* ((file (or buffer-file-name (user-error "Buffer is not visiting a file")))
         (term (or (car (gs/term-buffers)) (user-error "No terminal; open one with SPC j")))
         (path (file-relative-name file (or (doom-project-root) default-directory)))
         (ref (if beg
                  (format "@%s#L%d-%d " path (line-number-at-pos beg)
                          (line-number-at-pos (if (save-excursion (goto-char end) (bolp))
                                                  (max beg (1- end))
                                                end)))
                (format "@%s " path))))
    (when (evil-visual-state-p) (evil-exit-visual-state))
    (gs/term--show term)
    (ghostel-send-string ref)
    (evil-insert-state)))

(defun gs/term-visit-file-at-point ()
  "Open the path[:line] under point (agent output) in the code window."
  (interactive)
  (let ((thing (or (thing-at-point 'filename t) (user-error "No path at point"))))
    (unless (string-match "\\`@?\\(.+?\\)\\(?:[:#]L?\\([0-9]+\\)\\(?:-[0-9]+\\)?\\)?[:,.)]*\\'" thing)
      (user-error "No path at point"))
    (let ((file (expand-file-name (match-string 1 thing)))
          (line (and (match-string 2 thing) (string-to-number (match-string 2 thing)))))
      (unless (file-exists-p file) (user-error "No such file: %s" file))
      (select-window (get-mru-window nil nil t))
      (find-file file)
      (when line (goto-char (point-min)) (forward-line (1- line))))))

(map! :leader
      :desc "Terminals"                :n "j" #'gs/term
      :desc "Send region to terminal"  :v "j" #'gs/term-send-reference
      :desc "Toggle terminal panel"    :n "J" #'gs/term-toggle)
(map! :map general-override-mode-map
      :ni "M-j" #'gs/term-jump              ; works while typing in a terminal too
      :ni "M-J" #'gs/term-toggle)
(after! ghostel
  (map! :map ghostel-mode-map :n "gf" #'gs/term-visit-file-at-point))

;;; nvim keymaps

;; flash.nvim: `s' jumps, `S' selects outward by syntax (evil-snipe owned s/S)
(remove-hook 'doom-first-input-hook #'evil-snipe-mode)
(remove-hook 'doom-first-input-hook #'evil-snipe-override-mode)

(map! :n  "C-s" #'save-buffer
      :n  "C-q" #'evil-quit
      :n  "Q"   #'ignore
      :n  "-"   #'dired-jump                               ; oil.nvim
      :nvo "s"  #'evil-avy-goto-char-timer
      :nv "S"   #'er/expand-region
      :nv [f3]  #'+default/search-project-for-symbol-at-point
      :n  "gf"  #'+format/region-or-buffer                 ; conform
      :n  "gD"  #'+default/diagnostics
      ;; unimpaired pairs, nvim meaning
      :m  "]c"  #'next-error                               ; quickfix: grep/compile results
      :m  "[c"  #'previous-error
      :m  "]d"  #'flycheck-next-error                      ; diagnostics
      :m  "[d"  #'flycheck-previous-error
      :m  "]e"  (cmd! (let ((flycheck-navigation-minimum-level 'error)) (flycheck-next-error)))
      :m  "[e"  (cmd! (let ((flycheck-navigation-minimum-level 'error)) (flycheck-previous-error)))
      :m  "]h"  #'+vc-gutter/next-hunk                     ; gitsigns
      :m  "[h"  #'+vc-gutter/previous-hunk
      ;; nvim 0.11 LSP defaults (gr was Doom's eval operator; `gR' still evals)
      :n  "gr"  nil
      :n  "gra" #'eglot-code-actions
      :n  "grd" #'+lookup/definition
      :n  "grr" #'+lookup/references
      :n  "gri" #'+lookup/implementations
      :n  "grn" #'eglot-rename)

(after! evil
  ;; <leader>ws / <leader>wS, tmux prefix s / S: s is side by side
  (map! :map evil-window-map
        "s" #'+evil/window-vsplit-and-follow
        "S" #'+evil/window-split-and-follow))

;; <leader> letters from telescope.config.lua. Doom's prefixes they displace
;; move to the capital letter, so nothing is lost: SPC O open, SPC B buffer,
;; SPC F file, SPC H help. Delete this block to get stock Doom back.
(map! :leader
      :desc "open"                "O"   doom-leader-open-map
      :desc "buffer"              "B"   doom-leader-buffer-map
      :desc "file"                "F"   doom-leader-file-map
      :desc "help"                "H"   help-map
      :desc "Find file in project" "o"  #'projectile-find-file
      :desc "Workspace buffers"   "b"   #'persp-switch-to-buffer
      :desc "Recent project files" "e"  #'projectile-recentf
      :desc "Search buffer"       "f"   #'+default/search-buffer
      :desc "Search project"      "l"   #'+default/search-project
      :desc "Describe symbol"     "h"   #'describe-symbol
      :desc "Alternate buffer"    "SPC" #'evil-switch-to-windows-last-buffer
      :desc "Save all"            "W"   #'evil-write-all
      :desc "Quit all"            "Q"   #'evil-quit-all
      :desc "Yank path"           "y p" #'+default/yank-buffer-path-relative-to-project
      :desc "Switch workspace"    "TAB o" #'gs/sessionizer-workspaces
      :desc "Open project"        "TAB O" #'gs/sessionizer)

;; tmux prefix muscle memory in GUI Emacs (normal state). Under `emacs -nw'
;; tmux keeps C-a, so these never fire there.
(map! :n "C-a" nil
      :n "C-a o" #'gs/sessionizer-workspaces
      :n "C-a O" #'gs/sessionizer
      :n "C-a s" #'+evil/window-vsplit-and-follow
      :n "C-a S" #'+evil/window-split-and-follow
      :n "C-a x" #'evil-window-delete
      :n "C-a z" #'doom/window-maximize-buffer
      :n "C-a g" #'magit-status)

;;; Review queue (rvw), ported from nvim's after/plugin/review.lua

(load! "review")

;;; Tree-sitter: install missing grammars on first use, then use *-ts-mode.

;; (use-package! treesit-auto
;;   :custom
;;   (treesit-auto-install 'prompt)
;;   :config
;;   (treesit-auto-add-to-auto-mode-alist 'all)
;;   (global-treesit-auto-mode))

;;; Clojure: Midje tests through the REPL (emidje)

;; `emidje-setup' injects the midje-nrepl middleware into `cider-jack-in' and
;; installs its keys; without it, emidje is loaded but inert.
(after! cider
  (emidje-setup))

;; treesit-auto remaps to `clojure-ts-mode', whose keymap is not
;; `clojure-mode-map', so bind both.
(map! :after emidje
      :localleader
      :map (clojure-mode-map clojure-ts-mode-map)
      (:prefix ("j" . "midje")
       :desc "Run ns tests"      "n" #'emidje-run-ns-tests
       :desc "Run all tests"     "p" #'emidje-run-all-tests
       :desc "Re-run failed"     "r" #'emidje-re-run-failed-tests
       :desc "Run test at point" "t" #'emidje-run-test-at-point
       :desc "Test report"       "s" #'emidje-show-test-report
       :desc "Format tabular"    "f" #'emidje-format-tabular))
