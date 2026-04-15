local M = {}

local defaults = {
  data_dir = vim.fn.stdpath("data") .. "/vim-katas",
  panel_width = 42,
  timer_interval_ms = 250,
  default_category = nil,
  keymaps = {
    submit = "<leader>ks",
    hint   = "<leader>kh",
    quit   = "<leader>kq",
    menu   = "<leader>km",
  },
  -- seconds per keystroke used to compute time par per difficulty level
  time_par = {
    [1] = 0.8,
    [2] = 1.2,
    [3] = 1.8,
  },
  -- count macro replay keystrokes individually (true) or as 1 (false)
  count_macro_keys = false,
}

local _cfg = nil

function M.setup(opts)
  _cfg = vim.tbl_deep_extend("force", defaults, opts or {})
end

function M.get()
  if not _cfg then
    _cfg = vim.deepcopy(defaults)
  end
  return _cfg
end

return M
