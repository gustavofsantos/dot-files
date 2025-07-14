return {
    "olimorris/codecompanion.nvim",
    enabled = false,
    event = "VeryLazy",
    opts = {
        strategies = {
            chat = {
                adapter = {
                    name = "ollama",
                    model = "qwen2.5-coder:7b"
                },
                opts = {
                    completion_provider = "cmp",
                }
            },
            inline = {
                adapter = {
                    name = "ollama",
                    model = "qwen2.5-coder:7b"
                }
            },
            cmd = {
                adapter = {
                    name = "ollama",
                    model = "qwen2.5-coder:7b"
                }
            }
        },
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        {
            "echasnovski/mini.diff",
            config = function()
                local diff = require("mini.diff")
                diff.setup({
                    -- Disabled by default
                    source = diff.gen_source.none(),
                })
            end,
        },
    },
}
