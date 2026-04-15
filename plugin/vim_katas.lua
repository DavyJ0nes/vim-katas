-- Plugin entry point. Registers user commands.
-- Heavy modules are loaded lazily on first command invocation.
if vim.g.loaded_vim_katas then
  return
end
vim.g.loaded_vim_katas = true

-- Set up highlight groups immediately (before setup() is called)
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    pcall(function() require("vim_katas.ui").setup_highlights() end)
  end,
})

vim.api.nvim_create_user_command("VimKata", function(opts)
  require("vim_katas").start(opts.args)
end, {
  nargs = "?",
  complete = function(arg)
    -- Tab-complete kata ids
    local ok, reg = pcall(require, "vim_katas.katas")
    if not ok then return {} end
    local ids = {}
    for _, kata in ipairs(reg.all()) do
      if kata.id:find(arg, 1, true) then
        table.insert(ids, kata.id)
      end
    end
    return ids
  end,
  desc = "Start a vim kata (optionally specify kata id)",
})

vim.api.nvim_create_user_command("VimKataMenu", function()
  require("vim_katas").menu()
end, { desc = "Open the vim katas selection menu" })

vim.api.nvim_create_user_command("VimKataStats", function()
  require("vim_katas").stats()
end, { desc = "Show vim katas progress statistics" })
