-- Kata lifecycle: start, submit, retry, next, quit.
local config     = require("vim_katas.config")
local state      = require("vim_katas.state")
local katas      = require("vim_katas.katas")
local keytracker = require("vim_katas.keytracker")
local multifile  = require("vim_katas.multifile")
local scorer     = require("vim_katas.scorer")
local progress   = require("vim_katas.progress")
local ui         = require("vim_katas.ui")
local M = {}

-- ─────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────

local function stop_timer()
  local t = state.data.timer
  if t then
    t:stop()
    t:close()
    state.data.timer = nil
  end
end

local function start_timer()
  stop_timer()
  local t = vim.loop.new_timer()
  state.data.timer = t
  t:start(0, config.get().timer_interval_ms, vim.schedule_wrap(function()
    if state.data.phase == "ACTIVE" then
      ui.update_panel_status()
    else
      stop_timer()
    end
  end))
end

local function set_buf_keymaps(bufnr)
  local cfg = config.get()
  local opts = { buffer = bufnr, nowait = true, desc = "" }

  vim.keymap.set("n", cfg.keymaps.submit, function() M.submit() end,
    vim.tbl_extend("force", opts, { desc = "Vim Katas: submit" }))
  vim.keymap.set("n", cfg.keymaps.hint, function() M.show_hint() end,
    vim.tbl_extend("force", opts, { desc = "Vim Katas: hint" }))
  vim.keymap.set("n", cfg.keymaps.quit, function() M.quit() end,
    vim.tbl_extend("force", opts, { desc = "Vim Katas: quit" }))
end

local function teardown()
  stop_timer()
  keytracker.detach()

  -- Close the tab we opened (kills all windows inside it)
  if state.data.tab and vim.api.nvim_tabpage_is_valid(state.data.tab) then
    local ok = pcall(vim.cmd, "tabclose " .. vim.api.nvim_tabpage_get_number(state.data.tab))
    if not ok then
      -- Fallback: close individual windows
      for _, win in ipairs({ state.data.panel_win, state.data.win }) do
        if win and vim.api.nvim_win_is_valid(win) then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end
  end

  -- Wipe buffers
  for _, bufnr in ipairs({ state.data.panel_buf, state.data.buf }) do
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end

  -- Clean up multi-file temp directory
  if state.data.files_dir then
    multifile.teardown(state.data.files_dir)
  end

  -- If we changed cwd, restore (best-effort only)
  if state.data._saved_cwd then
    pcall(vim.cmd, "cd " .. vim.fn.fnameescape(state.data._saved_cwd))
    state.data._saved_cwd = nil
  end

  state.reset()
end

-- ─────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────

function M.start_kata(kata_id)
  local kata = katas.get(kata_id)
  if not kata then
    vim.notify("vim-katas: unknown kata id: " .. tostring(kata_id), vim.log.levels.ERROR)
    return
  end

  -- If already running, clean up first
  if state.data.phase ~= "IDLE" then
    teardown()
  end

  state.data.phase = "LOADING"
  state.data.kata  = kata

  -- Build UI (opens new tab, creates buffers)
  ui.open_kata_layout(kata)

  local bufnr = state.data.buf

  -- Configure practice buffer
  vim.bo[bufnr].swapfile  = false
  vim.bo[bufnr].bufhidden = "wipe"
  vim.b[bufnr].vim_katas_buf = true   -- guard LSP attachment

  -- Load content
  if kata.files then
    -- Multi-file kata: write files, set up buffer name, change cwd
    state.data._saved_cwd = vim.fn.getcwd()
    local files_dir = multifile.setup(kata)
    state.data.files_dir = files_dir
    multifile.load_into_buf(kata, bufnr, files_dir)
    -- Change cwd so *.go globs work in :vimgrep
    pcall(vim.cmd, "lcd " .. vim.fn.fnameescape(files_dir))
  else
    -- Single buffer kata
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, kata.lines or {})
  end

  -- Set filetype for syntax highlighting
  if kata.filetype and kata.filetype ~= "" then
    vim.bo[bufnr].filetype = kata.filetype
  end

  -- Place cursor
  local cur = kata.cursor or { row = 1, col = 0 }
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local safe_row = math.min(cur.row, line_count)
  pcall(vim.api.nvim_win_set_cursor, state.data.win, { safe_row, cur.col })

  -- Mark buffer as unmodified (we just loaded it)
  vim.bo[bufnr].modified = false

  -- Attach keymaps
  set_buf_keymaps(bufnr)

  -- Begin tracking
  state.data.keycount   = 0
  state.data.hint_shown = false
  state.data.start_time = os.clock()
  state.data.phase      = "ACTIVE"

  keytracker.attach()
  start_timer()
end

function M.show_hint()
  if state.data.phase ~= "ACTIVE" then return end
  state.data.hint_shown = true
  ui.show_hint()
end

function M.submit()
  if state.data.phase ~= "ACTIVE" then return end
  state.data.phase = "VALIDATING"
  stop_timer()

  local kata  = state.data.kata
  local bufnr = state.data.buf

  -- Gather context
  local lines  = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local raw_cur = vim.api.nvim_win_get_cursor(state.data.win)
  local cursor  = { row = raw_cur[1], col = raw_cur[2] }

  local ctx = {
    buf           = bufnr,
    lines         = lines,
    cursor        = cursor,
    initial_lines = kata.lines or (kata.files and kata.files[1].lines) or {},
    files_dir     = state.data.files_dir,
  }

  -- Run validation
  local ok, result = pcall(kata.validate, ctx)
  local passed, msg
  if not ok then
    passed = false
    msg    = "Validation error: " .. tostring(result)
    vim.notify("vim-katas: " .. msg, vim.log.levels.ERROR)
  else
    passed = result and result.success
    msg    = result and result.message or ""
  end

  -- Score the attempt
  local snap = {
    kata       = kata,
    keycount   = state.data.keycount,
    start_time = state.data.start_time,
    hint_shown = state.data.hint_shown,
    passed     = passed,
  }
  local score = scorer.rate(snap)

  -- Save progress
  pcall(progress.save, score)

  -- Update phase
  state.data.phase = passed and "PASSED" or "FAILED"

  -- Show result
  if passed then
    ui.show_result(score)
  else
    ui.show_failure(msg)
    -- Resume ACTIVE so they can keep trying
    state.data.phase = "ACTIVE"
    start_timer()
    keytracker.attach()
  end
end

function M.quit()
  teardown()
end

function M.retry()
  local kata = state.data.kata
  if not kata then return end
  local id = kata.id
  teardown()
  M.start_kata(id)
end

-- Move to a kata adjacent in the same category, or show the menu
function M.next()
  local kata = state.data.kata
  teardown()
  if not kata then
    ui.open_menu()
    return
  end
  local cat_katas = katas.by_category(kata.category)
  local idx = 1
  for i, k in ipairs(cat_katas) do
    if k.id == kata.id then idx = i; break end
  end
  local next_kata = cat_katas[idx + 1]
  if next_kata then
    M.start_kata(next_kata.id)
  else
    vim.notify("vim-katas: end of category! Opening menu.", vim.log.levels.INFO)
    ui.open_menu()
  end
end

return M
