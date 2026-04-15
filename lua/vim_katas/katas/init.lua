-- Central kata registry.
-- Loads all category files and exposes lookup/list APIs.
local M = {}

local category_files = {
  "vim_katas.katas.basic_motions",
  "vim_katas.katas.text_objects",
  "vim_katas.katas.operators",
  "vim_katas.katas.visual_mode",
  "vim_katas.katas.search_replace",
  "vim_katas.katas.macros",
  "vim_katas.katas.marks",
  "vim_katas.katas.registers",
  "vim_katas.katas.quickfix",
}

-- Human-readable category labels
M.category_labels = {
  basic_motions  = "Basic Motions",
  text_objects   = "Text Objects",
  operators      = "Operators",
  visual_mode    = "Visual Mode",
  search_replace = "Search & Replace",
  macros         = "Macros",
  marks          = "Marks",
  registers      = "Registers",
  quickfix       = "Quickfix & Multi-file",
}

-- Category display order
M.category_order = {
  "basic_motions",
  "text_objects",
  "operators",
  "visual_mode",
  "search_replace",
  "macros",
  "marks",
  "registers",
  "quickfix",
}

local _registry = nil   -- id -> kata
local _by_cat   = nil   -- category -> list of katas

local function load()
  if _registry then return end
  _registry = {}
  _by_cat   = {}
  for _, modname in ipairs(category_files) do
    local ok, katas = pcall(require, modname)
    if not ok then
      vim.notify("vim-katas: failed to load " .. modname .. ": " .. tostring(katas), vim.log.levels.WARN)
    else
      for _, kata in ipairs(katas) do
        if not kata.id then
          vim.notify("vim-katas: kata missing id in " .. modname, vim.log.levels.WARN)
        else
          _registry[kata.id] = kata
          local cat = kata.category or "unknown"
          _by_cat[cat] = _by_cat[cat] or {}
          table.insert(_by_cat[cat], kata)
        end
      end
    end
  end
end

-- Returns kata by id, or nil
function M.get(id)
  load()
  return _registry[id]
end

-- Returns list of all katas (flat)
function M.all()
  load()
  local list = {}
  for _, kata in pairs(_registry) do
    table.insert(list, kata)
  end
  table.sort(list, function(a, b) return a.id < b.id end)
  return list
end

-- Returns katas for a given category
function M.by_category(cat)
  load()
  return _by_cat[cat] or {}
end

-- Returns map of category -> list of katas
function M.grouped()
  load()
  return _by_cat
end

-- Returns list of all category names that have katas
function M.categories()
  load()
  local cats = {}
  for cat, _ in pairs(_by_cat) do
    table.insert(cats, cat)
  end
  table.sort(cats, function(a, b)
    local oa = vim.tbl_contains(M.category_order, a) and vim.fn.index(M.category_order, a) or 99
    local ob = vim.tbl_contains(M.category_order, b) and vim.fn.index(M.category_order, b) or 99
    return oa < ob
  end)
  return cats
end

return M
