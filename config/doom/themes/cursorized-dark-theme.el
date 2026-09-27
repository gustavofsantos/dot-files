;;; cursorized-dark-theme.el --- cursorized, dark variant -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;; Palette copied from config/nvim/colors/cursorized.lua (palette.dark).
;; Change colors there first, then here; the rules live in cursorized.el.
;;; Code:

(require 'cursorized (expand-file-name "cursorized" (file-name-directory (or load-file-name buffer-file-name))))

(cursorized-deftheme cursorized-dark
  "Warm paper, near-black ink, eight vivid accents. Dark variant."
  dark
  :bg "#1a1918" :bg_hl "#272623" :border "#393833"
  :fg_faint "#716f68" :fg_comment "#9d9b92" :fg "#d2cfc5" :fg_emph "#faf8f4"
  :red "#ff8b90" :orange "#f69557" :yellow "#d3a82d" :green "#64c175"
  :cyan "#00c0c0" :blue "#64b2ff" :violet "#b89fff" :magenta "#ed8ecf"
  :ansi ["#716f68" "#ff8b90" "#64c175" "#d3a82d" "#64b2ff" "#ed8ecf" "#00c0c0" "#d2cfc5"
         "#9d9b92" "#ffb1b2" "#7bd88a" "#eabe4a" "#93c8ff" "#ffa9e3" "#3ad7d7" "#faf8f4"])

;;; cursorized-dark-theme.el ends here
