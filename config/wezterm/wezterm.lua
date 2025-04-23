local config = {}

local wezterm = require("wezterm")
require("navigation").setup()
require("keymapping").setup(config)
require("statusline").setup()


config.automatically_reload_config = false
config.force_reverse_video_cursor = true
config.colors = require("colors.Kanagawa")

config.font = wezterm.font("MonoLisa Nerd Font")
-- config.font = wezterm.font_with_fallback({
--     { family = "OperatorMono Nerd Font", weight = "Regular" },
--     "JetBrains Mono",
--     "Noto Color Emoji",
--     "Symbols Nerd Font Mono",
-- })
-- config.font = wezterm.font("BerkeleyMono Nerd Font")
config.font_size = 14
config.max_fps = 120
config.harfbuzz_features = { "calt=1", "clig=1", "liga=0" }

config.window_decorations = "RESIZE"
config.window_background_opacity = 1.0
config.window_close_confirmation = "NeverPrompt"

config.window_padding = {
    left = 16,
    right = 16,
    top = 16,
    bottom = 16,
}

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 999999

for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
    if gpu.backend == "Vulkan" and (gpu.device_type == "IntegratedGpu" or gpu.device_type == "DiscreteGpu") then
        config.webgpu_preferred_adapter = gpu
        config.front_end = "WebGpu"
    end
end

return config
