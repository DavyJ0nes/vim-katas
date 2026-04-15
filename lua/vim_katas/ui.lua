-- UI: split layout, instructions panel, results overlay, kata menu.
local config   = require("vim_katas.config")
local state    = require("vim_katas.state")
local katas    = require("vim_katas.katas")
local progress = require("vim_katas.progress")
local M = {}

-- Difficulty stars string
local function diff_stars(n)
  return string.rep("★", n) .. string.rep("☆", 3 - n)
end

-- Format elapsed seconds as "m:ss"
function M.fmt_time(secs)
  local m = math.floor(secs / 60)
  local s = math.floor(secs % 60)
  return string.format("%d:%02d", m, s)
end

-- ─────────────────────────────────────────────
-- Panel content builders
-- ─────────────────────────────────────────────

local function build_panel_lines(kata, keycount, elapsed, hint_shown)
  local cfg   = config.get()
  local w     = cfg.panel_width - 2
  local sep   = string.rep("─", w)
  local lines = {}

  local function push(s) table.insert(lines, s or "") end

  push(" VIM KATAS")
  push(" " .. sep)
  push("")
  push(" " .. (kata.title or kata.id))
  push(" " .. diff_stars(kata.difficulty or 1)
       .. "  [" .. (kata.category or "") .. "]")
  push("")
  push(" " .. sep)
  push("")

  -- Instructions
  for _, l in ipairs(vim.split(kata.instructions or "", "\n", { plain = true })) do
    push(" " .. l)
  end

  push("")
  push(" " .. sep)
  push("")

  -- Hint
  if hint_shown then
    push(" HINT:")
    for _, hl in ipairs(vim.split(kata.hint or "", "\n", { plain = true })) do
      push("   " .. hl)
    end
    push("")
    push(" " .. sep)
    push("")
  end

  -- Status section (dynamic — track the start line)
  local status_start = #lines
  push(string.format(" Keys: %-4d  Optimal: %d",
    keycount, kata.optimal_keystrokes or "?"))
  push(string.format(" Time: %s", M.fmt_time(elapsed or 0)))
  push("")
  push(" <leader>ks  submit")
  push(" <leader>kh  hint")
  push(" <leader>kq  quit")

  return lines, status_start
end

-- ─────────────────────────────────────────────
-- Open kata layout
-- ─────────────────────────────────────────────

function M.open_kata_layout(kata)
  local cfg = config.get()

  -- New tab so we don't disturb existing layout
  vim.cmd("tabnew")
  state.data.tab = vim.api.nvim_get_current_tabpage()

  -- Practice buffer
  local practice_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_win_set_buf(0, practice_buf)
  local practice_win = vim.api.nvim_get_current_win()

  -- Panel split on the right
  vim.cmd("rightbelow vsplit")
  local panel_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(panel_win, cfg.panel_width)

  -- Panel buffer (scratch)
  local panel_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(panel_win, panel_buf)

  -- Configure panel
  vim.bo[panel_buf].buftype   = "nofile"
  vim.bo[panel_buf].swapfile  = false
  vim.bo[panel_buf].buflisted = false
  vim.wo[panel_win].number    = false
  vim.wo[panel_win].relativenumber = false
  vim.wo[panel_win].wrap      = true
  vim.wo[panel_win].cursorline = false
  vim.wo[panel_win].signcolumn = "no"
  vim.api.nvim_buf_set_name(panel_buf, "vim-katas://instructions")

  -- Render panel
  local panel_lines, status_start = build_panel_lines(kata, 0, 0, false)
  vim.bo[panel_buf].modifiable = true
  vim.api.nvim_buf_set_lines(panel_buf, 0, -1, false, panel_lines)
  vim.bo[panel_buf].modifiable = false
  vim.bo[panel_buf].readonly   = true

  -- Apply highlight groups to panel
  M.apply_panel_highlights(panel_buf)

  -- Focus on practice window
  vim.api.nvim_set_current_win(practice_win)

  state.data.buf        = practice_buf
  state.data.panel_buf  = panel_buf
  state.data.win        = practice_win
  state.data.panel_win  = panel_win
  state.data.status_line = status_start
end

-- ─────────────────────────────────────────────
-- Update the dynamic status lines in the panel
-- ─────────────────────────────────────────────

function M.update_panel_status()
  local s = state.data
  if not s.panel_buf or not vim.api.nvim_buf_is_valid(s.panel_buf) then return end
  if not s.status_line then return end

  local elapsed = s.start_time and (os.clock() - s.start_time) or 0
  local new_lines = {
    string.format(" Keys: %-4d  Optimal: %d",
      s.keycount, (s.kata and s.kata.optimal_keystrokes) or 0),
    string.format(" Time: %s", M.fmt_time(elapsed)),
    "",
    " <leader>ks  submit",
    " <leader>kh  hint",
    " <leader>kq  quit",
  }

  vim.bo[s.panel_buf].modifiable = true
  vim.api.nvim_buf_set_lines(s.panel_buf, s.status_line, s.status_line + #new_lines, false, new_lines)
  vim.bo[s.panel_buf].modifiable = false
end

function M.show_hint()
  local s = state.data
  if not s.kata or not s.panel_buf then return end
  local elapsed = s.start_time and (os.clock() - s.start_time) or 0
  local lines, status_start = build_panel_lines(s.kata, s.keycount, elapsed, true)
  vim.bo[s.panel_buf].modifiable = true
  vim.api.nvim_buf_set_lines(s.panel_buf, 0, -1, false, lines)
  vim.bo[s.panel_buf].modifiable = false
  state.data.status_line = status_start
  M.apply_panel_highlights(s.panel_buf)
end

-- ─────────────────────────────────────────────
-- Results floating window
-- ─────────────────────────────────────────────

function M.show_result(result)
  local scorer = require("vim_katas.scorer")
  local width  = 44
  local lines  = {
    "",
    result.passed and "  ✓  KATA COMPLETE" or "  ✗  INCORRECT",
    "",
    string.format("  Score:      %s", scorer.stars_str(result.stars, result.time_bonus)),
    string.format("  Keystrokes: %d  (optimal: %d)", result.keycount, result.optimal),
    string.format("  Time:       %s", M.fmt_time(result.elapsed_seconds)),
    result.hint_used and "  Hint used  (capped at ★★)" or "",
    "",
    "  [r] retry    [n] next    [q] quit",
    "",
  }
  -- Remove empty hint line if not used
  if not result.hint_used then
    table.remove(lines, 7)
  end

  local height = #lines
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row      = row,
    col      = col,
    width    = width,
    height   = height,
    border   = "rounded",
    style    = "minimal",
    zindex   = 50,
  })

  vim.wo[win].cursorline = false

  -- Apply highlights
  local ns = vim.api.nvim_create_namespace("vim_katas_result")
  for i, line in ipairs(lines) do
    if line:find("✓") or line:find("COMPLETE") then
      vim.api.nvim_buf_add_highlight(buf, ns, "VimKataSuccess", i - 1, 0, -1)
    elseif line:find("✗") or line:find("INCORRECT") then
      vim.api.nvim_buf_add_highlight(buf, ns, "VimKataError", i - 1, 0, -1)
    elseif line:find("Score") then
      vim.api.nvim_buf_add_highlight(buf, ns, "VimKataStar", i - 1, 0, -1)
    end
  end

  -- Keymaps for result actions
  local runner = require("vim_katas.runner")
  local function map(key, fn)
    vim.keymap.set("n", key, function()
      vim.api.nvim_win_close(win, true)
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
      fn()
    end, { buffer = buf, nowait = true })
  end

  map("r", function() runner.retry() end)
  map("n", function() runner.next() end)
  map("q", function() runner.quit() end)
  map("<Esc>", function() runner.quit() end)
end

-- ─────────────────────────────────────────────
-- Failure message (inline, no float)
-- ─────────────────────────────────────────────

function M.show_failure(msg)
  vim.notify("vim-katas: " .. (msg or "Incorrect. Keep trying!"), vim.log.levels.WARN)
end

-- ─────────────────────────────────────────────
-- Kata menu
-- ─────────────────────────────────────────────

function M.open_menu()
  local progress_data = progress.all()
  local all_cats      = katas.category_order

  local lines   = {}
  local kata_map = {}   -- line index -> kata id

  table.insert(lines, " VIM KATAS — Select a kata")
  table.insert(lines, " ──────────────────────────────────────────")
  table.insert(lines, "")

  for _, cat in ipairs(all_cats) do
    local cat_katas = katas.by_category(cat)
    if #cat_katas > 0 then
      table.insert(lines, string.format(" ▶ %s", katas.category_labels[cat] or cat))
      for _, kata in ipairs(cat_katas) do
        local prog = progress_data.katas and progress_data.katas[kata.id]
        local status = "  "
        if prog then
          status = string.format("★%d", prog.best_stars or 0)
        end
        local line_str = string.format("   %s  %s  [%s]",
          diff_stars(kata.difficulty or 1),
          kata.title,
          status)
        table.insert(lines, line_str)
        kata_map[#lines] = kata.id
      end
      table.insert(lines, "")
    end
  end

  table.insert(lines, " j/k: navigate   Enter: start   q: close")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local width  = 54
  local height = math.min(#lines, vim.o.lines - 4)
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row, col = col,
    width = width, height = height,
    border = "rounded",
    style = "minimal",
    zindex = 40,
  })

  vim.wo[win].cursorline = true
  vim.api.nvim_win_set_cursor(win, { 4, 0 })  -- first kata line

  local function close()
    vim.api.nvim_win_close(win, true)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end

  -- Navigate only to kata lines (skip headers/empty lines)
  local function move(dir)
    local cur = vim.api.nvim_win_get_cursor(win)[1]
    local target = cur + dir
    while target >= 1 and target <= #lines do
      if kata_map[target] then
        vim.api.nvim_win_set_cursor(win, { target, 0 })
        return
      end
      target = target + dir
    end
  end

  vim.keymap.set("n", "j", function() move(1) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "k", function() move(-1) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Down>", function() move(1) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Up>", function() move(-1) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<CR>", function()
    local cur = vim.api.nvim_win_get_cursor(win)[1]
    local id  = kata_map[cur]
    if id then
      close()
      require("vim_katas.runner").start_kata(id)
    end
  end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
end

-- ─────────────────────────────────────────────
-- Stats view
-- ─────────────────────────────────────────────

function M.open_stats()
  local scorer       = require("vim_katas.scorer")
  local progress_data = progress.all()
  local all_katas    = katas.all()

  local lines = {
    " VIM KATAS — Progress",
    " ─────────────────────────────────────────────────────",
    string.format(" %-30s  %5s  %8s  %8s", "Kata", "Stars", "Best Keys", "Best Time"),
    " ─────────────────────────────────────────────────────",
  }

  for _, kata in ipairs(all_katas) do
    local prog = progress_data.katas and progress_data.katas[kata.id]
    local row
    if prog then
      local t = prog.best_time == math.huge and "—" or M.fmt_time(prog.best_time)
      local k = prog.best_keycount == math.huge and "—" or tostring(prog.best_keycount)
      row = string.format(" %-30s  %5s  %8s  %8s",
        kata.title:sub(1, 30),
        scorer.stars_str(prog.best_stars or 0),
        k, t)
    else
      row = string.format(" %-30s  %5s  %8s  %8s",
        kata.title:sub(1, 30), "——", "—", "—")
    end
    table.insert(lines, row)
  end

  table.insert(lines, "")
  table.insert(lines, " q / <Esc>: close")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local width  = 58
  local height = math.min(#lines + 2, vim.o.lines - 4)
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row, col = col,
    width = width, height = height,
    border = "rounded",
    style = "minimal",
    zindex = 40,
  })

  vim.wo[win].cursorline = true

  local function close()
    vim.api.nvim_win_close(win, true)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end

  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
end

-- ─────────────────────────────────────────────
-- Highlight groups
-- ─────────────────────────────────────────────

function M.setup_highlights()
  vim.api.nvim_set_hl(0, "VimKataStar",    { fg = "#f0c040", bold = true, default = true })
  vim.api.nvim_set_hl(0, "VimKataSuccess", { fg = "#73c991", bold = true, default = true })
  vim.api.nvim_set_hl(0, "VimKataError",   { fg = "#f14c4c", bold = true, default = true })
  vim.api.nvim_set_hl(0, "VimKataHint",    { fg = "#888888", italic = true, default = true })
  vim.api.nvim_set_hl(0, "VimKataHeader",  { fg = "#569cd6", bold = true, default = true })
end

function M.apply_panel_highlights(bufnr)
  local ns = vim.api.nvim_create_namespace("vim_katas_panel")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:match("^%s*VIM KATAS") or line:match("^%s*▶") then
      vim.api.nvim_buf_add_highlight(bufnr, ns, "VimKataHeader", i - 1, 0, -1)
    elseif line:match("[★☆]") then
      vim.api.nvim_buf_add_highlight(bufnr, ns, "VimKataStar", i - 1, 0, -1)
    elseif line:match("^%s*HINT") then
      vim.api.nvim_buf_add_highlight(bufnr, ns, "VimKataHint", i - 1, 0, -1)
    end
  end
end

return M
