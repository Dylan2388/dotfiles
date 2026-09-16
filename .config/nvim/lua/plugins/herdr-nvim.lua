-- herdr-nvim: the nvim-side half (code annotations you send to the agent).
-- The herdr-side half (sidebar + file picker) is installed separately via
-- `herdr plugin install ChmaraX/herdr-nvim`.
--
-- Default keymaps live under <leader>a (comment/list/send/submit) and never
-- override maps you already set. Commands: :Herdr comment|list|send|submit.
return {
  {
    "ChmaraX/herdr-nvim",
    opts = {
      -- prefix = "<leader>a",    -- keymap prefix
      -- keymaps = true,          -- set false to define your own
      -- clear_after_send = true, -- comments are ephemeral by design
    },
  },
}
