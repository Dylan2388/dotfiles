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
      },
    },
  },
}
