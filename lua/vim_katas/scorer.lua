local config = require("vim_katas.config")
local M = {}

-- Returns a result table from a completed kata run.
-- state_snap: snapshot of relevant state fields
--   .kata         - kata definition
--   .keycount     - actual keystrokes
--   .start_time   - os.clock() when ACTIVE began
--   .hint_shown   - boolean
--   .passed       - boolean (validate returned true)
function M.rate(state_snap)
  local kata     = state_snap.kata
  local optimal  = kata.optimal_keystrokes or 1
  local keycount = state_snap.keycount
  local elapsed  = os.clock() - state_snap.start_time
  local cfg      = config.get()

  -- Base star rating (0-3)
  local stars
  if not state_snap.passed then
    stars = 0
  elseif keycount <= 0 then
    -- Keystrokes were not tracked (shouldn't happen, but don't reward it)
    stars = 0
  else
    -- Efficiency ratio: how close to optimal (capped at 1.0 so over-efficient = 3★)
    local ratio = math.min(optimal / keycount, 1.0)
    if ratio >= 1.00 then
      stars = 3
    elseif ratio >= 0.75 then
      stars = 2
    elseif ratio >= 0.50 then
      stars = 1
    else
      stars = 0
    end
  end

  -- Hint penalty: cap at 2 stars
  if state_snap.hint_shown and stars > 2 then
    stars = 2
  end

  -- Time bonus: only available at 3 stars (and no hint)
  local time_bonus = 0.0
  if stars == 3 and not state_snap.hint_shown then
    local secs_per_key = cfg.time_par[kata.difficulty] or 1.0
    local par = optimal * secs_per_key
    -- time_bonus = 1.0 if near-instant, 0.0 if took 3x par
    time_bonus = math.max(0, 1 - (elapsed / (par * 3)))
  end

  return {
    kata_id         = kata.id,
    stars           = stars,
    time_bonus      = time_bonus,
    keycount        = keycount,
    optimal         = optimal,
    elapsed_seconds = elapsed,
    hint_used       = state_snap.hint_shown,
    timestamp       = os.time(),
    passed          = state_snap.passed,
  }
end

-- Render star string for display (e.g. "★★★☆☆")
function M.stars_str(stars, bonus)
  local filled = string.rep("★", stars)
  local empty  = string.rep("☆", 3 - stars)
  local trophy = (bonus and bonus > 0.7) and " 🏆" or ""
  return filled .. empty .. trophy
end

return M
