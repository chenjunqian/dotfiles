lvim.log.level = "warn"
lvim.format_on_save = false
lvim.colorscheme = "nordic"
-- lvim.transparent_window = true
-- to disable icons and use a minimalist setup, uncomment the following
-- lvim.use_icons = false

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["L"] = "$"
lvim.keys.normal_mode["H"] = "^"
lvim.keys.normal_mode["<Tab>"] = "<cmd>BufferLineCycleNext<cr>"
lvim.keys.normal_mode["<S-Tab>"] = "<cmd>BufferLineCyclePre<cr>"
lvim.keys.visual_mode["L"] = "$"
lvim.keys.visual_mode["H"] = "^"
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.dap.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.view.width = 40
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.auto_install = true
lvim.builtin.lualine.style = "default"
vim.opt.cmdheight = 1
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.wrap = true

lvim.plugins = {
    { "lunarvim/colorschemes" },
    { "windwp/nvim-ts-autotag" },
    -- { "ellisonleao/gruvbox.nvim" },
    {
        'AlexvZyl/nordic.nvim',
        lazy = false,
        priority = 1000,
        config = function()
            require 'nordic'.load()
        end
    },
    {
        "folke/lsp-colors.nvim",
        event = "BufRead",
    },
    {
        "echasnovski/mini.map",
        branch = "stable",
        config = function()
            require('mini.map').setup()
            local map = require('mini.map')
            map.setup({
                integrations = {
                    map.gen_integration.builtin_search(),
                    map.gen_integration.diagnostic({
                        error = 'DiagnosticFloatingError',
                        warn  = 'DiagnosticFloatingWarn',
                        info  = 'DiagnosticFloatingInfo',
                        hint  = 'DiagnosticFloatingHint',
                    }),
                    map.gen_integration.gitsigns(),
                },
                symbols = {
                    encode = map.gen_encode_symbols.dot('4x2'),
                },
                window = {
                    side = 'right',
                    width = 10, -- set to 1 for a pure scrollbar :)
                    winblend = 15,
                    show_integration_count = false,
                },
            })
            lvim.builtin.which_key.mappings['m'] = {
                name = 'MiniMap',
                o = { MiniMap.toggle, "Toggle MiniMap" },
            }
        end
    },
    -- {
    --     "karb94/neoscroll.nvim",
    --     event = "WinScrolled",
    --     config = function()
    --         require('neoscroll').setup({
    --             -- All these keys will be mapped to their corresponding default scrolling animation
    --             mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>',
    --                 '<C-y>', '<C-e>', 'zt', 'zz', 'zb' },
    --             hide_cursor = true,          -- Hide cursor while scrolling
    --             stop_eof = true,             -- Stop at <EOF> when scrolling downwards
    --             use_local_scrolloff = false, -- Use the local scope of scrolloff instead of the global scope
    --             respect_scrolloff = false,   -- Stop scrolling when the cursor reaches the scrolloff margin of the file
    --             cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
    --             easing_function = nil,       -- Default easing function
    --             pre_hook = nil,              -- Function to run before the scrolling animation starts
    --             post_hook = nil,             -- Function to run after the scrolling animation ends
    --         })
    --     end
    -- },
    {
        "rmagatti/goto-preview",
        config = function()
            require('goto-preview').setup {
                width = 120,              -- Width of the floating window
                height = 25,              -- Height of the floating window
                default_mappings = false, -- Bind default mappings
                debug = false,            -- Print debug information
                opacity = nil,            -- 0-100 opacity level of the floating window where 100 is fully transparent.
                post_open_hook = nil,     -- A function taking two arguments, a buffer and a window to be ran as a hook.
                -- You can use "default_mappings = true" setup option
                -- Or explicitly set keybindings
            }

            vim.cmd("nnoremap gpd <cmd>lua require('goto-preview').goto_preview_definition()<CR>")
            vim.cmd("nnoremap gpi <cmd>lua require('goto-preview').goto_preview_implementation()<CR>")
            vim.cmd("nnoremap gpt <cmd>lua require('goto-preview').goto_preview_type_definition()<CR>")
            vim.cmd("nnoremap gpr <cmd>lua require('goto-preview').goto_preview_references()<CR>")
            vim.cmd("nnoremap gP <cmd>lua require('goto-preview').close_all_win()<CR>")
            -- lvim.builtin.which_key.mappings['gp'] = {
            --   name = 'Goto Definition Preview',
            --   d = { "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", "Goto Preview Definition" },
            --   i = { "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>", "Goto Preiview Implementation" },
            --   r = { "<cmd>lua require('goto-preview').goto_preview_references()<CR>", "Goto Preiview References" },
            -- }
        end
    },
    {
        "simrat39/symbols-outline.nvim",
        config = function()
            lvim.builtin.which_key.mappings["lo"] = {
                "<cmd>SymbolsOutline<CR>", "Open symbols-outline"
                -- name = "Symbols Outline",
                -- o = {
                --     "<cmd>SymbolsOutlineOpen<CR>", "Open symbols-outline"
                -- },
                -- c = {
                --     "<cmd>SymbolsOutlineClose<CR>", "Close symbols-outline"
                -- }
            }
            require('symbols-outline').setup()
        end
    },
    {
        "ChristianChiarulli/far.vim",
        config = function()
            local keymap = lvim.builtin.which_key.mappings
            keymap["r"] = {
                { "<CMD>Farr --source=vimgrep<CR>", "Find & Replace" }
            }
            -- https://www.chiarulli.me/Neovim/23-far-find-and-replace/
            -- keymap["f"]["b"] = { "<CMD>Farr --source=vimgrep<CR>", "buffer" }
            -- keymap["f"]["p"] = { "<CMD>Farr --source=rgnvim<CR>", "project" }
            --    let g:far#window_width=60
            --    " Use %:p with buffer option only
            --    let g:far#file_mask_favorites=['%:p', '**/*.*', '**/*.js', '**/*.py', '**/*.java', '**/*.css', '**/*.html', '**/*.vim', '**/*.cpp', '**/*.c', '**/*.h', ]
            --    let g:far#window_min_content_width=30
            --    let g:far#enable_undo=1
        end
    },
    {
        "folke/todo-comments.nvim",
        event = "BufRead",
        config = function()
            require("todo-comments").setup()
        end,
    },
    {
        "iamcco/markdown-preview.nvim",
        build = "cd app && npm install",
        ft = "markdown",
        config = function()
            vim.g.mkdp_auto_start = 0
        end,
    },
    {
        "ray-x/lsp_signature.nvim",
        config = function()
            require "lsp_signature".on_attach()
            require "lsp_signature".setup({
                bind = true, -- This is mandatory, otherwise border config won't get registered.
                handler_opts = {
                    border = "rounded"
                }
            })
        end,
        event = "BufRead"
    },
    {
        "olexsmir/gopher.nvim",
    },
    {
        "leoluz/nvim-dap-go",
        config = function()
            lvim.builtin.which_key.mappings["dm"] = {
                name = 'Debug Method',
                g = { "<cmd>lua require('dap-go').debug_test()<CR>", "Debug Method for Golang" }
            }
        end
    }
}

-- LSP Setting
require("lvim.lsp.manager").setup("grammarly")

-- DAP Setting
require('dap.ext.vscode').load_launchjs()
require('dap-go').setup {
    dap_configurations = {
        {
            -- Must be "go" or it will be ignored by the plugin
            type = "go",
            name = "Attach remote",
            mode = "remote",
            request = "attach",
        },
    },
    -- delve configurations
    delve = {
        path = "dlv",
        initialize_timeout_sec = 20,
        port = "${port}",
        args = {},
        build_flags = "",
    },
}
-- Golang DAP End
