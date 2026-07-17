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
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "flake8", "pylint" },
      },
    },
  },
  {
    -- Pin to the stable `master` branch. The `main` rewrite requires the
    -- tree-sitter CLI to build parsers, whose prebuilt binary needs
    -- GLIBC 2.39 (Ubuntu 24.04). This system has GLIBC 2.35 (Ubuntu 22.04),
    -- so `main` fails with a "GLIBC_2.39 not found" error.
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
  },
}
