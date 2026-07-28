return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      -- snacks.bigfile switches a buffer to `filetype=bigfile` (disabling
      -- LSP/treesitter/formatting) when a file is > `size` OR its average
      -- line length is > `line_length`. Minified JSON lives on one huge line,
      -- which tripped `line_length` and stripped the `json` filetype, making
      -- `<leader>cf` report "no formatter". A minified JSON is precisely the
      -- file you want to format, so disable the line-length heuristic and keep
      -- only a generous size guard for genuinely huge files.
      bigfile = {
        size = 10 * 1024 * 1024, -- 10MB
        line_length = 1000000000, -- effectively disable the long-line trigger
      },
      explorer = {
        -- opens the picker-based explorer
      },
      picker = {
        sources = {
          explorer = {
            hidden = true, -- show dotfiles
            ignored = true, -- show gitignored files
          },
        },
        -- Remap preview scrolling. <C-b> collides with the tmux prefix key,
        -- so free it and use the Vim-style pair <C-e>/<C-y> instead. These are
        -- portable: no tmux conflict and no macOS Option-key issues (unlike
        -- <A-b>, where macOS Option produces a special character by default).
        --   <C-e> = scroll preview down   (Vim: scroll down one line)
        --   <C-y> = scroll preview up     (Vim: scroll up one line)
        -- Horizontal preview scroll is unmapped by default, so add h/l:
        --   <C-h> = scroll preview left   <C-l> = scroll preview right
        -- (Note: <C-h> in the input box no longer acts as Backspace; use <BS>.)
        win = {
          input = {
            keys = {
              ["<c-b>"] = false, -- free up Ctrl-b (grabbed by tmux prefix)
              ["<c-e>"] = { "preview_scroll_down", mode = { "i", "n" } },
              ["<c-y>"] = { "preview_scroll_up", mode = { "i", "n" } },
              ["<c-h>"] = { "preview_scroll_left", mode = { "i", "n" } },
              ["<c-l>"] = { "preview_scroll_right", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
              ["<c-b>"] = false,
              ["<c-e>"] = "preview_scroll_down",
              ["<c-y>"] = "preview_scroll_up",
              ["<c-h>"] = "preview_scroll_left",
              ["<c-l>"] = "preview_scroll_right",
            },
          },
        },
      },
    },
  },
  {
    -- LazyVim core only registers formatters for lua/fish/sh. JSON formatting
    -- normally comes from the `lang.json` extra (via the jsonls LSP), which is
    -- not enabled here. Register prettier (installed via Mason) for json/jsonc
    -- so `<leader>cf` and format-on-save work.
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        json = { "prettier" },
        jsonc = { "prettier" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "flake8", "pylint" },
      },
    },
  },
  {
    -- Use the `main` branch, which LazyVim and Neovim 0.12 require. The
    -- legacy `master` branch is frozen and its queries are incompatible with
    -- Neovim 0.12's core treesitter runtime, which caused crashes like
    --   languagetree.lua: attempt to call method 'range' (a nil value)
    -- whenever a file was opened via snacks (explorer, lazygit, picker).
    --
    -- `main` builds parsers with the tree-sitter CLI. Its prebuilt binary
    -- needs GLIBC 2.39, but this box has GLIBC 2.35 (Ubuntu 22.04), so we
    -- build the CLI from source instead:
    --   cargo install tree-sitter-cli --version 0.22.6 --locked
    -- and put ~/.cargo/bin on PATH (see ~/.bashrc) so nvim can find it.
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
  },
}
