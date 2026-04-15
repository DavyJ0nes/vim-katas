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

  -- Note: use only the first argument (key). The second argument (typed) is
  -- nil in many Neovim versions and must not be relied upon.
  vim.on_key(function(key)
    if state.data.phase ~= "ACTIVE" then return end
    -- Only count keys pressed in the practice buffer
    local cur_buf = vim.api.nvim_get_current_buf()
    if cur_buf ~= state.data.buf then return end
    -- Skip empty / nil
    if not key or key == "" then return end
    -- Skip mouse events: Neovim encodes special keys with a 0x80 prefix byte
    if key:byte(1) == 0x80 then
      local lower = key:lower()
      if lower:find("mouse") or lower:find("click") or lower:find("scroll") or lower:find("drag") then
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
