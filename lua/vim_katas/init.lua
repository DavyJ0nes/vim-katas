-- Public API surface for vim-katas.
local M = {}

function M.setup(opts)
  local config = require("vim_katas.config")
  config.setup(opts)

  -- Set up highlight groups on colorscheme change
  local ui = require("vim_katas.ui")
  ui.setup_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group    = vim.api.nvim_create_augroup("VimKatasHighlights", { clear = true }),
    callback = function() ui.setup_highlights() end,
  })

  -- Guard LSP from attaching to kata buffers
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("VimKatasLspGuard", { clear = true }),
    callback = function(ev)
      if vim.b[ev.buf] and vim.b[ev.buf].vim_katas_buf then
        vim.lsp.buf_detach_client(ev.buf, ev.data.client_id)
      end
    end,
  })

  -- Set global menu keymap if configured
  local cfg = config.get()
  if cfg.keymaps and cfg.keymaps.menu then
    vim.keymap.set("n", cfg.keymaps.menu, function() M.menu() end,
      { desc = "Vim Katas: open menu" })
  end
end

function M.start(kata_id)
  if kata_id and kata_id ~= "" then
    require("vim_katas.runner").start_kata(kata_id)
  else
    M.menu()
  end
end

function M.menu()
  require("vim_katas.ui").open_menu()
end

function M.stats()
  require("vim_katas.ui").open_stats()
end

return M
