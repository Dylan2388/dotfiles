-- LaTeX editing: VimTeX drives latexmk for compilation and zathura for preview.
--
-- Requires: a TeX distribution with xelatex/lualatex, latexmk, fontawesome6
-- (TeX Live 2024+), the Source Sans 3 and Roboto fonts visible to fontconfig,
-- and zathura with a PDF backend.
--
-- Core keymaps (<localleader> is "\"):
--   \ll  toggle continuous compilation (latexmk -pvc)
--   \lv  forward search: jump zathura to the cursor position
--   \lk  stop compilation
--   \lc  clean auxiliary files
--   \le  toggle the error/warning quickfix list
--   \lt  open the table-of-contents drawer (\lT toggles it)
return {
  {
    "lervag/vimtex",
    -- VimTeX must not be lazy-loaded; it manages its own ftplugin hooks.
    lazy = false,
    init = function()
      -- Preview
      vim.g.vimtex_view_method = "zathura"

      -- Compilation
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        -- Keep the PDF beside the .tex source. Awesome CV projects (and this
        -- repo's JD workflow) expect resume_Dylan.pdf next to resume_Dylan.tex.
        out_dir = "",
        callback = 1,
        continuous = 1,
        options = {
          "-verbose",
          "-file-line-error",
          "-synctex=1",
          "-interaction=nonstopmode",
        },
      }

      -- Engine selection. Awesome CV needs a Unicode engine (fontspec), so
      -- pdflatex is not viable. Default to xelatex and let a
      -- `%!TEX TS-program = ...` magic comment in the source override it.
      vim.g.vimtex_compiler_latexmk_engines = {
        ["_"] = "-xelatex",
        pdflatex = "-pdf",
        lualatex = "-lualatex",
        xelatex = "-xelatex",
      }

      -- Quickfix: Awesome CV emits many harmless font/hyperref warnings.
      -- Only surface entries that matter, and don't steal focus on open.
      vim.g.vimtex_quickfix_open_on_warning = 0
      vim.g.vimtex_quickfix_ignore_filters = {
        "Underfull \\\\hbox",
        "Overfull \\\\hbox",
        "Package hyperref Warning",
        "Font shape declaration has incorrect series value",
      }

      -- Don't fold or conceal; keep the source as-written for LaTeX resumes
      -- where exact spacing macros matter.
      vim.g.vimtex_fold_enabled = 0
      vim.g.vimtex_syntax_conceal_disable = 1

      -- Suppress the "no output PDF yet" popup on first compile.
      vim.g.vimtex_view_forward_search_on_start = 0
    end,
  },

  -- Treesitter grammar for better highlighting of the .tex sources.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "latex", "bibtex" })
      end
    end,
  },

  -- VimTeX defines its mappings as <Plug>(vimtex-*) with no `desc`, so
  -- which-key falls back to showing the raw <Plug> name. Label them instead.
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        {
          mode = "n",
          ft = "tex",
          { "<localleader>l", group = "vimtex" },
          { "<localleader>ll", desc = "Compile (toggle continuous)" },
          { "<localleader>lo", desc = "Compiler output" },
          { "<localleader>lk", desc = "Stop compilation" },
          { "<localleader>lK", desc = "Stop all compilers" },
          { "<localleader>lv", desc = "View / forward search" },
          { "<localleader>le", desc = "Errors (quickfix)" },
          { "<localleader>lq", desc = "Open raw log" },
          { "<localleader>lc", desc = "Clean aux files" },
          { "<localleader>lC", desc = "Clean aux files + PDF" },
          { "<localleader>lt", desc = "Open table of contents" },
          { "<localleader>lT", desc = "Toggle table of contents" },
          { "<localleader>lg", desc = "Compiler status" },
          { "<localleader>lG", desc = "Compiler status (all)" },
          { "<localleader>li", desc = "VimTeX info" },
          { "<localleader>lI", desc = "VimTeX info (full)" },
          { "<localleader>ls", desc = "Toggle main document" },
          { "<localleader>lx", desc = "Reload VimTeX" },
          { "<localleader>lX", desc = "Reload VimTeX state" },
          { "<localleader>lm", desc = "List insert-mode maps" },
          { "<localleader>la", desc = "Context menu" },
        },
      },
    },
  },
}
