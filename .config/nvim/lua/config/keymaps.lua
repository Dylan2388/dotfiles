-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Copy the diagnostic message(s) on the current line to the clipboard
vim.keymap.set("n", "<leader>cy", function()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diags = vim.diagnostic.get(0, { lnum = line })
  if vim.tbl_isempty(diags) then
    vim.notify("No diagnostics on this line", vim.log.levels.WARN)
    return
  end
  local msgs = vim.tbl_map(function(d)
    return d.message
  end, diags)
  local text = table.concat(msgs, "\n")
  vim.fn.setreg("+", text)
  vim.notify("Copied diagnostic:\n" .. text)
end, { desc = "Copy diagnostic message" })

-- vim-herdr-navigation (editor side): <C-h/j/k/l> move between Neovim splits
-- and, at a split edge, hand off to herdr so focus crosses into the neighbouring
-- pane. Loaded here because LazyVim loads its own keymaps before this file, so
-- these maps replace LazyVim's plain <C-w>h/j/k/l ones.
-- The herdr side (the ctrl+h/j/k/l keybinds) lives in ~/.config/herdr/config.toml.
do
  -- Resolve the installed plugin by glob: herdr appends a content hash to the
  -- directory name, which changes when the plugin is updated.
  local matches = vim.fn.glob(vim.fn.expand("~/.config/herdr/plugins/github/vim-herdr-navigation-*/editor/nvim.lua"), true, true)
  if #matches > 0 then
    dofile(matches[1])
  end
end
