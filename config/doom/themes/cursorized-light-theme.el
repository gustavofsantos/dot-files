;;; cursorized-light-theme.el --- cursorized, light variant -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;; Palette copied from config/nvim/colors/cursorized.lua (palette.light).
;; Change colors there first, then here; the rules live in cursorized.el.
;;; Code:

(require 'cursorized (expand-file-name "cursorized" (file-name-directory (or load-file-name buffer-file-name))))

(cursorized-deftheme cursorized-light
  "Warm paper, near-black ink, eight vivid accents. Light variant."
  light
  :bg "#f7f7f4" :bg_hl "#eeede7" :border "#dbd9d2"
  :fg_faint "#8a8882" :fg_comment "#696761" :fg "#31302d" :fg_emph "#161614"
  :red "#ba3e4b" :orange "#aa5100" :yellow "#846600" :green "#007b2f"
  :cyan "#007677" :blue "#006cbc" :violet "#7856c0" :magenta "#a9438d"
  :ansi ["#161614" "#ba3e4b" "#007b2f" "#846600" "#006cbc" "#a9438d" "#007677" "#31302d"
         "#696761" "#a22638" "#006425" "#6c5300" "#00589b" "#922d78" "#006061" "#8a8882"])

;;; cursorized-light-theme.el ends here
