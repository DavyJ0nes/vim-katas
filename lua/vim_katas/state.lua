-- Single source of truth for the kata runner state.
-- Only runner.lua should mutate this table.
local M = {}

M.data = {
  phase        = "IDLE",  -- IDLE | LOADING | ACTIVE | VALIDATING | PASSED | FAILED
  kata         = nil,     -- current kata definition table
  buf          = nil,     -- practice buffer id
  panel_buf    = nil,     -- instructions panel buffer id
  win          = nil,     -- practice window id
  panel_win    = nil,     -- instructions window id
  tab          = nil,     -- tabnr opened for this kata
  start_time   = nil,     -- os.clock() when ACTIVE began
  keycount     = 0,       -- incremented by keytracker
  hint_shown   = false,   -- whether hint was shown this run
  files_dir    = nil,     -- temp dir for multi-file katas
  timer        = nil,     -- libuv timer handle
  on_key_ns    = nil,     -- vim.on_key namespace id
  status_line  = nil,     -- line index (0-based) in panel_buf where status begins
}

function M.reset()
  M.data.phase       = "IDLE"
  M.data.kata        = nil
  M.data.buf         = nil
  M.data.panel_buf   = nil
  M.data.win         = nil
  M.data.panel_win   = nil
  M.data.tab         = nil
  M.data.start_time  = nil
  M.data.keycount    = 0
  M.data.hint_shown  = false
  M.data.files_dir   = nil
  M.data.timer       = nil
  M.data.on_key_ns   = nil
  M.data.status_line = nil
end

return M
