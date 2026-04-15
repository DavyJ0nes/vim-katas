-- Tracks keystrokes in the practice buffer using vim.on_key.
-- Counts each logical keypress (multi-byte sequences count as 1).
-- When count_macro_keys is false, keystrokes replayed during macro
-- execution are not counted (only the initiating @x or @@ counts).
local config = require("vim_katas.config")
local state  = require("vim_katas.state")
local M = {}

local NS_NAME = "vim_katas_keytracker"

function M.attach()
  local ns = vim.api.nvim_create_namespace(NS_NAME)
  state.data.on_key_ns = ns

  vim.on_key(function(key, typed)
    if state.data.phase ~= "ACTIVE" then return end
    -- Only count keys pressed in the practice buffer
    local cur_buf = vim.api.nvim_get_current_buf()
    if cur_buf ~= state.data.buf then return end
    -- Skip empty strings (can happen on some events)
    if not typed or typed == "" then return end
    -- Skip pure mouse events (start with \x80 in Neovim special encoding)
    if typed:byte(1) == 0x80 then
      -- Allow <C-...> and other specials but skip mouse buttons
      local lower = typed:lower()
      if lower:find("mouse") or lower:find("scroll") or lower:find("drag") then
        return
      end
    end
    -- Optionally skip macro replay keys
    if not config.get().count_macro_keys then
      if vim.fn.reg_executing() ~= "" then
        return
      end
    end

    state.data.keycount = state.data.keycount + 1
  end, ns)
end

function M.detach()
  if state.data.on_key_ns then
    vim.on_key(nil, state.data.on_key_ns)
    state.data.on_key_ns = nil
  end
end

return M
