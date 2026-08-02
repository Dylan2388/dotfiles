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
