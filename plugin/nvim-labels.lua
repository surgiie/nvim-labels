if vim.g.loaded_labels then
  return
end
vim.g.loaded_labels = true

vim.api.nvim_create_user_command("NvimLabelJump", function()
  require("nvim-labels").jump()
end, { desc = "nvim-labels: jump to word" })

vim.api.nvim_create_user_command("NvimLabelCharShortcut", function()
  require("nvim-labels").insert_char_shortcut()
end, { desc = "nvim-labels: insert a character shortcut" })

-- Set vim.g.labels_no_default_mappings, or vim.g.labels_jump_key /
-- vim.g.labels_char_key, before load. labels_char_key deliberately does NOT
-- default through <leader>: <leader> is often <Space>, and a <Space>-prefixed
-- insert-mode mapping makes every space you type wait out 'timeoutlen' first.
if not vim.g.labels_no_default_mappings then
  vim.keymap.set("n", vim.g.labels_jump_key or "<leader>j", function()
    require("nvim-labels").jump()
  end, { desc = "nvim-labels: jump to word" })

  vim.keymap.set({ "n", "i" }, vim.g.labels_char_key or "<C-\\>", function()
    require("nvim-labels").insert_char_shortcut()
  end, { desc = "nvim-labels: insert character shortcut" })
end
