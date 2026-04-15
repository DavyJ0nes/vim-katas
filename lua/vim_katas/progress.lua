local config = require("vim_katas.config")
local M = {}

local MAX_HISTORY = 20

local function path()
  return config.get().data_dir .. "/progress.json"
end

local function ensure_dir()
  vim.fn.mkdir(config.get().data_dir, "p")
end

function M.load()
  local p = path()
  local f = io.open(p, "r")
  if not f then
    return { version = 1, katas = {} }
  end
  local raw = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, raw)
  if not ok or type(data) ~= "table" then
    return { version = 1, katas = {} }
  end
  return data
end

-- result table shape (from scorer):
--   kata_id, stars, keycount, optimal, elapsed_seconds, hint_used, timestamp, passed
function M.save(result)
  ensure_dir()
  local data = M.load()
  local id = result.kata_id
  local entry = data.katas[id] or {
    attempts      = 0,
    best_stars    = 0,
    best_keycount = math.huge,
    best_time     = math.huge,
    last_played   = 0,
    history       = {},
  }

  entry.attempts    = entry.attempts + 1
  entry.last_played = result.timestamp

  if result.stars > entry.best_stars then
    entry.best_stars = result.stars
  end
  if result.passed and result.keycount < entry.best_keycount then
    entry.best_keycount = result.keycount
  end
  if result.passed and result.elapsed_seconds < entry.best_time then
    entry.best_time = result.elapsed_seconds
  end

  table.insert(entry.history, {
    stars    = result.stars,
    keycount = result.keycount,
    elapsed  = result.elapsed_seconds,
    hint_used = result.hint_used,
    timestamp = result.timestamp,
  })
  -- cap history
  while #entry.history > MAX_HISTORY do
    table.remove(entry.history, 1)
  end

  data.katas[id] = entry

  -- atomic write via temp file
  local tmp = path() .. ".tmp"
  local f = io.open(tmp, "w")
  if f then
    f:write(vim.json.encode(data))
    f:close()
    os.rename(tmp, path())
  end
end

-- Returns the entry for a kata id, or nil if never attempted
function M.get(kata_id)
  local data = M.load()
  return data.katas[kata_id]
end

-- Returns full data table
function M.all()
  return M.load()
end

return M
