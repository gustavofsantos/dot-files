;;; cursorized.el --- Shared core of the cursorized themes -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;
;; Emacs port of config/nvim/colors/cursorized.lua (same palette, same rules):
;;   * Ink first. Code is mostly fg; color marks meaning, not every identifier.
;;   * Each accent owns one idea:
;;       violet keywords   blue functions   green strings   orange literals
;;       yellow types      cyan escapes     magenta builtins/macros   red errors
;;   * The cursor is Cursor orange, the one color outside these rules.
;;   * Tints (diff, region, virtual text) are OKLab blends over bg, and text on
;;     a tint walks toward fg_emph until it reaches 4.5:1 contrast.
;;
;; The palettes live in cursorized-{dark,light}-theme.el; this file holds the
;; color math and the role -> face table both variants share. Built on
;; `def-doom-theme', so every package face doom-themes knows gets a color too.
;;
;;; Code:

(require 'cl-lib)
(require 'doom-themes)

(defgroup cursorized nil
  "Warm paper, near-black ink, eight vivid accents."
  :group 'doom-themes)

(defcustom cursorized-italic-comments t
  "Whether comments are italic."
  :group 'cursorized
  :type 'boolean)

(defconst cursorized-signature "#f54e00"
  "Cursor orange: the cursor's color in both variants.")

(defconst cursorized-alpha
  ;; Light backgrounds show tint sooner, so they get lower alphas than dark ones.
  '((light :diff-add 0.14 :diff-delete 0.14 :diff-change 0.14 :diff-text 0.30
           :visual 0.16 :virtual-text 0.10)
    (dark  :diff-add 0.20 :diff-delete 0.20 :diff-change 0.20 :diff-text 0.40
           :visual 0.25 :virtual-text 0.14))
  "Tint strength per variant, as in cursorized.lua.")

;;
;;; Color math (OKLab), a line-for-line port of the Lua

(defun cursorized--rgb (hex)
  (mapcar (lambda (i) (/ (string-to-number (substring hex i (+ i 2)) 16) 255.0))
          '(1 3 5)))

(defun cursorized--hex (rgb)
  (apply #'format "#%02x%02x%02x"
         (mapcar (lambda (c) (floor (+ (* (min 1.0 (max 0.0 c)) 255) 0.5))) rgb)))

(defun cursorized--linear (c)
  (if (<= c 0.04045) (/ c 12.92) (expt (/ (+ c 0.055) 1.055) 2.4)))

(defun cursorized--srgb (c)
  (setq c (min 1.0 (max 0.0 c)))
  (if (<= c 0.0031308) (* 12.92 c) (- (* 1.055 (expt c (/ 1 2.4))) 0.055)))

(defun cursorized--cbrt (x)
  (if (>= x 0) (expt x (/ 1.0 3)) (- (expt (- x) (/ 1.0 3)))))

(defun cursorized--to-oklab (hex)
  (cl-destructuring-bind (r g b) (mapcar #'cursorized--linear (cursorized--rgb hex))
    (let ((l (cursorized--cbrt (+ (* 0.4122214708 r) (* 0.5363325363 g) (* 0.0514459929 b))))
          (m (cursorized--cbrt (+ (* 0.2119034982 r) (* 0.6806995451 g) (* 0.1073969566 b))))
          (s (cursorized--cbrt (+ (* 0.0883024619 r) (* 0.2817188376 g) (* 0.6299787005 b)))))
      (list (+ (* 0.2104542553 l) (* 0.7936177850 m) (* -0.0040720468 s))
            (+ (* 1.9779984951 l) (* -2.4285922050 m) (* 0.4505937099 s))
            (+ (* 0.0259040371 l) (* 0.7827717662 m) (* -0.8086757660 s))))))

(defun cursorized--from-oklab (lab)
  (cl-destructuring-bind (L a b) lab
    (let ((l (expt (+ L (* 0.3963377774 a) (* 0.2158037573 b)) 3))
          (m (expt (- L (* 0.1055613458 a) (* 0.0638541728 b)) 3))
          (s (expt (- L (* 0.0894841775 a) (* 1.2914855480 b)) 3)))
      (cursorized--hex
       (mapcar #'cursorized--srgb
               (list (+ (* 4.0767416621 l) (* -3.3077115913 m) (* 0.2309699292 s))
                     (+ (* -1.2684380046 l) (* 2.6097574011 m) (* -0.3413193965 s))
                     (+ (* -0.0041960863 l) (* -0.7034186147 m) (* 1.7076147010 s))))))))

(defun cursorized-blend (fg bg alpha)
  "Mix FG over BG in OKLab; ALPHA 0 is BG, 1 is FG."
  (cursorized--from-oklab
   (cl-mapcar (lambda (x y) (+ (* x alpha) (* y (- 1 alpha))))
              (cursorized--to-oklab fg) (cursorized--to-oklab bg))))

(defun cursorized-shade (hex delta)
  "Shift HEX's OKLab lightness by DELTA, keeping hue and chroma."
  (cl-destructuring-bind (L a b) (cursorized--to-oklab hex)
    (cursorized--from-oklab (list (min 1.0 (max 0.0 (+ L delta))) a b))))

(defun cursorized--luminance (hex)
  (cl-destructuring-bind (r g b) (mapcar #'cursorized--linear (cursorized--rgb hex))
    (+ (* 0.2126 r) (* 0.7152 g) (* 0.0722 b))))

(defun cursorized-contrast (x y)
  "WCAG contrast ratio of X and Y, 1..21."
  (let ((a (cursorized--luminance x)) (b (cursorized--luminance y)))
    (/ (+ (max a b) 0.05) (+ (min a b) 0.05))))

(defun cursorized-ensure-contrast (fg bg target &optional min)
  "Walk FG toward TARGET until it reaches MIN (4.5) contrast on BG.
If TARGET itself falls short, keep moving its lightness away from BG."
  (let ((min (or min 4.5)))
    (or (cl-loop for i from 0 to 10
                 for c = (cursorized-blend target fg (/ i 10.0))
                 when (>= (cursorized-contrast c bg) min) return c)
        (let ((away (if (> (cursorized--luminance bg) 0.18) -0.02 0.02))
              (c target))
          (dotimes (_ 50 c)
            (unless (>= (cursorized-contrast c bg) min)
              (setq c (cursorized-shade c away))))))))

;;
;;; Palette -> doom-themes color table

(defun cursorized--defs (variant p)
  "Doom color definitions for VARIANT from palette plist P.
All derived colors are computed here, once, from palette values only."
  (let* ((light (eq variant 'light))
         (alpha (alist-get variant cursorized-alpha))
         (get (lambda (k) (plist-get p k)))
         (bg (funcall get :bg))
         (fg-emph (funcall get :fg_emph))
         (over (lambda (color key &optional scale)
                 (cursorized-blend (funcall get color) bg
                                   (* (or scale 1) (plist-get alpha key)))))
         (readable (lambda (fg tint) (cursorized-ensure-contrast fg tint fg-emph 4.5)))
         (tints `((diff-add-bg          ,(funcall over :green :diff-add))
                  (diff-add-soft-bg     ,(funcall over :green :diff-add 0.5))
                  (diff-add-text-bg     ,(funcall over :green :diff-text))
                  (diff-delete-bg       ,(funcall over :red :diff-delete))
                  (diff-delete-soft-bg  ,(funcall over :red :diff-delete 0.5))
                  (diff-delete-text-bg  ,(funcall over :red :diff-text))
                  (diff-change-bg       ,(funcall over :blue :diff-change))
                  (diff-text-bg         ,(funcall over :blue :diff-text))
                  (visual-bg            ,(funcall over :blue :visual))
                  (vt-error-bg          ,(funcall over :red :virtual-text))
                  (vt-warn-bg           ,(funcall over :yellow :virtual-text))
                  (vt-info-bg           ,(funcall over :blue :virtual-text))))
         (tint (lambda (k) (cadr (assq k tints))))
         (fg (funcall get :fg))
         (on-tint `((diff-add-fg    ,(funcall readable fg (funcall tint 'diff-add-text-bg)))
                    (diff-delete-fg ,(funcall readable fg (funcall tint 'diff-delete-text-bg)))
                    (diff-change-fg ,(funcall readable fg (funcall tint 'diff-text-bg)))
                    (visual-fg      ,(funcall readable fg (funcall tint 'visual-bg)))
                    (vt-error-fg    ,(funcall readable (funcall get :red) (funcall tint 'vt-error-bg)))
                    (vt-warn-fg     ,(funcall readable (funcall get :yellow) (funcall tint 'vt-warn-bg)))
                    (vt-info-fg     ,(funcall readable (funcall get :blue) (funcall tint 'vt-info-bg)))))
         (ansi (funcall get :ansi))
         (ink-16 (if light "black" "white"))
         (paper-16 (if light "white" "black")))
    (cl-flet ((c (hex &optional name) `'(,hex ,hex ,(or name "brightblack"))))
      `(;; grays: bg -> fg spectrum as doom-themes expects (base0 starker bg)
        (bg        ,(c bg paper-16))
        (bg-alt    ,(c (funcall get :bg_hl) paper-16))
        (fg        ,(c fg ink-16))
        (fg-alt    ,(c (funcall get :fg_comment)))
        (base0     ,(c (cursorized-shade bg (if light 0.02 -0.03)) paper-16))
        (base1     ,(c (funcall get :bg_hl)))
        (base2     ,(c (cursorized-blend (funcall get :border) (funcall get :bg_hl) 0.5)))
        (base3     ,(c (funcall get :border)))
        (base4     ,(c (funcall get :fg_faint)))
        (base5     ,(c (funcall get :fg_comment)))
        (base6     ,(c (cursorized-blend fg (funcall get :fg_comment) 0.5)))
        (base7     ,(c fg ink-16))
        (base8     ,(c fg-emph ink-16))
        (border     ,(c (funcall get :border)))
        (fg-faint   ,(c (funcall get :fg_faint)))
        (fg-comment ,(c (funcall get :fg_comment)))
        (fg-emph    ,(c fg-emph ink-16))
        (signature  ,(c cursorized-signature "brightred"))
        (grey       fg-faint)
        ;; accents
        (red        ,(c (funcall get :red) "red"))
        (orange     ,(c (funcall get :orange) "brightred"))
        (yellow     ,(c (funcall get :yellow) "yellow"))
        (green      ,(c (funcall get :green) "green"))
        (cyan       ,(c (funcall get :cyan) "cyan"))
        (teal       cyan)
        (dark-cyan  ,(c (cursorized-shade (funcall get :cyan) (if light -0.08 -0.15)) "cyan"))
        (blue       ,(c (funcall get :blue) "blue"))
        (dark-blue  ,(c (funcall tint 'visual-bg) "blue"))
        (violet     ,(c (funcall get :violet) "brightmagenta"))
        (magenta    ,(c (funcall get :magenta) "magenta"))
        ;; derived tints and the text drawn on them
        ,@(cl-loop for (k v) in (append tints on-tint) collect `(,k ,(c v)))
        ;; terminal: the Ghostty theme's 16 slots
        ,@(cl-loop for hex across ansi for i from 0
                   collect `(,(intern (format "ansi%d" i)) ,(c hex)))
        ;; doom-themes' universal syntax classes
        (highlight      blue)
        (vertical-bar   border)
        (selection      visual-bg)
        (builtin        magenta)
        (comments       fg-comment)
        (doc-comments   fg-comment)
        (constants      orange)
        (functions      blue)
        (keywords       violet)
        (methods        blue)
        (operators      fg)
        (type           yellow)
        (strings        green)
        (variables      fg)
        (numbers        orange)
        (region         visual-bg)
        (error          red)
        (warning        yellow)
        (success        green)
        (vc-modified    yellow)
        (vc-added       green)
        (vc-deleted     red)))))

;;
;;; Roles -> faces (overrides on top of doom-themes-base)

(defconst cursorized--faces
  `(;;;; editor
    (cursor :background signature)
    (region :background visual-bg :distant-foreground visual-fg :extend t)
    (highlight :background visual-bg :foreground fg-emph)
    (hl-line :background bg-alt :extend t)
    (fringe :background bg :foreground fg-faint)
    (vertical-border :background border :foreground border)
    (window-divider :foreground border)
    (window-divider-first-pixel :foreground border)
    (window-divider-last-pixel :foreground border)
    (line-number :foreground fg-faint :background bg)
    (line-number-current-line :foreground fg-emph :background bg-alt :weight 'bold)
    (shadow :foreground fg-comment)
    (minibuffer-prompt :foreground blue)
    (link :foreground blue :underline t)
    (link-visited :foreground violet :underline t)
    (tooltip :background bg-alt :foreground fg)
    (show-paren-match :foreground fg-emph :background border :weight 'bold)
    (show-paren-mismatch :foreground bg :background red :weight 'bold)
    (isearch :foreground bg :background orange :weight 'bold)
    (isearch-fail :foreground bg :background red)
    (lazy-highlight :foreground bg :background yellow)
    (match :foreground bg :background yellow)
    (evil-ex-search :foreground bg :background orange :weight 'bold)
    (evil-ex-lazy-highlight :foreground bg :background yellow)
    (evil-ex-substitute-matches :foreground bg :background orange)
    (header-line :foreground fg-emph :background bg-alt)
    (mode-line :foreground fg-emph :background bg-alt)
    (mode-line-inactive :foreground fg-comment :background bg-alt)
    (mode-line-emphasis :foreground fg-emph :weight 'bold)
    (doom-modeline-bar :background blue)
    (solaire-mode-line-face :inherit 'mode-line)
    (solaire-mode-line-inactive-face :inherit 'mode-line-inactive)
    (error :foreground red :weight 'bold)
    (warning :foreground yellow)
    (success :foreground green)

    ;;;; syntax: ink first
    (font-lock-comment-face :foreground fg-comment
                            :slant (if cursorized-italic-comments 'italic 'normal))
    (font-lock-doc-face :inherit 'font-lock-comment-face :foreground fg-comment)
    (font-lock-doc-markup-face :foreground cyan)
    (font-lock-keyword-face :foreground violet)
    (font-lock-builtin-face :foreground magenta)
    (font-lock-preprocessor-face :foreground magenta)
    (font-lock-preprocessor-char-face :foreground magenta)
    (font-lock-function-name-face :foreground blue)
    (font-lock-function-call-face :foreground blue)
    (font-lock-variable-name-face :foreground fg)
    (font-lock-variable-use-face :foreground fg)
    (font-lock-property-name-face :foreground fg)
    (font-lock-property-use-face :foreground fg)
    (font-lock-constant-face :foreground orange)
    (font-lock-number-face :foreground orange)
    (font-lock-string-face :foreground green)
    (font-lock-type-face :foreground yellow)
    (font-lock-operator-face :foreground fg)
    (font-lock-negation-char-face :foreground fg)
    (font-lock-punctuation-face :foreground fg-comment)
    (font-lock-bracket-face :foreground fg-comment)
    (font-lock-delimiter-face :foreground fg-comment)
    (font-lock-misc-punctuation-face :foreground fg-comment)
    (font-lock-escape-face :foreground cyan)
    (font-lock-regexp-grouping-backslash :foreground cyan)
    (font-lock-regexp-grouping-construct :foreground cyan)
    (font-lock-warning-face :foreground yellow)
    (highlight-numbers-number :foreground orange)
    (hl-todo :foreground yellow :weight 'bold)

    ;;;; completion (vertico, corfu, orderless)
    (vertico-current :background visual-bg :extend t)
    (corfu-default :background bg-alt :foreground fg)
    (corfu-current :background blue :foreground bg)
    (corfu-border :background border)
    (corfu-bar :background fg-faint)
    (completions-common-part :foreground fg-emph :weight 'bold)
    (orderless-match-face-0 :foreground fg-emph :weight 'bold)
    (orderless-match-face-1 :foreground blue :weight 'bold)
    (orderless-match-face-2 :foreground violet :weight 'bold)
    (orderless-match-face-3 :foreground green :weight 'bold)

    ;;;; diagnostics and LSP
    (flycheck-error   :underline (list :style 'wave :color red))
    (flycheck-warning :underline (list :style 'wave :color yellow))
    (flycheck-info    :underline (list :style 'wave :color blue))
    (flycheck-fringe-error   :foreground red)
    (flycheck-fringe-warning :foreground yellow)
    (flycheck-fringe-info    :foreground blue)
    (flycheck-error-list-error   :foreground red)
    (flycheck-error-list-warning :foreground yellow)
    (flycheck-error-list-info    :foreground blue)
    (flycheck-posframe-background-face :background bg-alt)
    (flycheck-posframe-error-face   :foreground vt-error-fg :background vt-error-bg)
    (flycheck-posframe-warning-face :foreground vt-warn-fg :background vt-warn-bg)
    (flycheck-posframe-info-face    :foreground vt-info-fg :background vt-info-bg)
    (eglot-highlight-symbol-face :background visual-bg)
    (eglot-inlay-hint-face :foreground fg-comment)
    (eglot-diagnostic-tag-unnecessary-face :foreground fg-comment)
    (eglot-diagnostic-tag-deprecated-face :strike-through t)

    ;;;; diff and git
    (diff-added   :foreground diff-add-fg :background diff-add-bg :extend t)
    (diff-removed :foreground diff-delete-fg :background diff-delete-bg :extend t)
    (diff-changed :foreground diff-change-fg :background diff-change-bg :extend t)
    (diff-refine-added   :foreground diff-add-fg :background diff-add-text-bg :weight 'bold)
    (diff-refine-removed :foreground diff-delete-fg :background diff-delete-text-bg :weight 'bold)
    (diff-refine-changed :foreground diff-change-fg :background diff-text-bg :weight 'bold)
    (diff-indicator-added :foreground green)
    (diff-indicator-removed :foreground red)
    (diff-indicator-changed :foreground yellow)
    (diff-header :foreground fg-comment :background bg-alt)
    (diff-file-header :foreground fg-emph :background bg-alt :weight 'bold)
    (diff-hunk-header :foreground fg-comment :background bg-alt)
    (diff-hl-insert :foreground green :background green)
    (diff-hl-delete :foreground red :background red)
    (diff-hl-change :foreground yellow :background yellow)
    (magit-diff-added             :foreground diff-add-fg :background diff-add-soft-bg :extend t)
    (magit-diff-added-highlight   :foreground diff-add-fg :background diff-add-bg :extend t)
    (magit-diff-removed           :foreground diff-delete-fg :background diff-delete-soft-bg :extend t)
    (magit-diff-removed-highlight :foreground diff-delete-fg :background diff-delete-bg :extend t)
    (magit-diff-base              :foreground diff-change-fg :background diff-change-bg :extend t)
    (magit-diff-base-highlight    :foreground diff-change-fg :background diff-change-bg :extend t)
    (magit-diff-context           :foreground fg-comment :background bg :extend t)
    (magit-diff-context-highlight :foreground fg :background bg-alt :extend t)
    (magit-diff-hunk-heading           :foreground fg-comment :background bg-alt :extend t)
    (magit-diff-hunk-heading-highlight :foreground fg-emph :background border :weight 'bold :extend t)
    (magit-diff-file-heading :foreground fg-emph :weight 'bold :extend t)
    (magit-section-highlight :background bg-alt :extend t)
    (magit-section-heading :foreground orange :weight 'bold)
    (magit-branch-current :foreground blue :weight 'bold)
    (magit-hash :foreground fg-comment)
    (magit-blame-heading :foreground fg-comment :background bg-alt :extend t)
    (smerge-upper :background diff-delete-bg :extend t)
    (smerge-lower :background diff-add-bg :extend t)
    (smerge-base :background diff-change-bg :extend t)
    (smerge-markers :foreground fg-comment :background bg-alt :extend t)
    (smerge-refined-removed :foreground diff-delete-fg :background diff-delete-text-bg)
    (smerge-refined-added :foreground diff-add-fg :background diff-add-text-bg)
    (ediff-current-diff-A :background diff-delete-bg :extend t)
    (ediff-current-diff-B :background diff-add-bg :extend t)
    (ediff-current-diff-C :background diff-change-bg :extend t)
    (ediff-fine-diff-A :foreground diff-delete-fg :background diff-delete-text-bg :weight 'bold)
    (ediff-fine-diff-B :foreground diff-add-fg :background diff-add-text-bg :weight 'bold)
    (ediff-fine-diff-C :foreground diff-change-fg :background diff-text-bg :weight 'bold)

    ;;;; headings and markup: Title is orange
    ,@(cl-loop for i from 1 to 8
               append `((,(intern (format "outline-%d" i)) :foreground orange :weight 'bold)
                        (,(intern (format "org-level-%d" i)) :foreground orange :weight 'bold)))
    ,@(cl-loop for i from 1 to 6
               collect `(,(intern (format "markdown-header-face-%d" i)) :foreground orange :weight 'bold))
    (markdown-header-face :foreground orange :weight 'bold)
    (markdown-markup-face :foreground fg-comment)
    (markdown-list-face :foreground fg-comment)
    (markdown-code-face :background bg-alt :extend t)
    (markdown-inline-code-face :foreground cyan)
    (markdown-link-face :foreground blue)
    (markdown-url-face :foreground blue :underline t)
    (markdown-blockquote-face :inherit 'font-lock-comment-face)
    (org-document-title :foreground orange :weight 'bold)
    (org-block :background bg-alt :extend t)
    (org-block-begin-line :foreground fg-comment :background bg-alt :extend t)
    (org-block-end-line :foreground fg-comment :background bg-alt :extend t)
    (org-quote :inherit 'font-lock-comment-face :background bg-alt :extend t)
    (org-code :foreground cyan)
    (org-verbatim :foreground cyan)
    (org-meta-line :foreground fg-comment)
    (org-link :foreground blue :underline t)
    (org-todo :foreground yellow :weight 'bold)
    (org-done :foreground fg-comment)
    (org-headline-done :foreground fg-comment)

    ;;;; files
    (dired-directory :foreground blue)
    (diredfl-dir-name :foreground blue)

    ;;;; terminal: ghostel, vterm and compilation inherit ansi-color-*
    ,@(cl-loop for name in '("black" "red" "green" "yellow" "blue" "magenta" "cyan" "white")
               for i from 0
               for normal = (intern (format "ansi%d" i))
               for bright = (intern (format "ansi%d" (+ i 8)))
               append `((,(intern (format "ansi-color-%s" name)) :foreground ,normal :background ,normal)
                        (,(intern (format "ansi-color-bright-%s" name)) :foreground ,bright :background ,bright))))
  "Face specs shared by both variants, in `def-doom-theme' form.")

(defmacro cursorized-deftheme (name docstring variant &rest palette)
  "Define theme NAME for VARIANT (`light' or `dark') from PALETTE, a plist
with the keys of cursorized.lua's palette (:bg :bg_hl :border :fg_faint
:fg_comment :fg :fg_emph, the eight accents, and :ansi, a 16-color vector)."
  (declare (doc-string 2) (indent 2))
  `(def-doom-theme ,name ,docstring
     :family 'cursorized
     :background-mode ',variant
     ,(cursorized--defs variant palette)
     ,cursorized--faces))

(provide 'cursorized)
;;; cursorized.el ends here
