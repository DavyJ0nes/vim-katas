-- Sets up and tears down temporary files for multi-file katas.
local M = {}

-- Creates temp dir, writes kata.files to disk, returns the dir path.
function M.setup(kata)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")

  for _, file_def in ipairs(kata.files) do
    local path = dir .. "/" .. file_def.name
    local f = io.open(path, "w")
    if not f then
      vim.notify("vim-katas: could not create " .. path, vim.log.levels.ERROR)
    else
      f:write(table.concat(file_def.lines, "\n"))
      f:write("\n")
      f:close()
    end
  end

  return dir
end

-- Loads the first file into the given buffer and sets cursor.
function M.load_into_buf(kata, bufnr, files_dir)
  local first = kata.files[1]
  local path  = files_dir .. "/" .. first.name

  -- Set the buffer name so vim commands like :vimgrep *.go work
  -- from that directory (we'll also set the cwd of the window).
  vim.api.nvim_buf_set_name(bufnr, path)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, first.lines)
  vim.bo[bufnr].modified = false
end

-- Removes the temp dir and clears the quickfix/location lists.
function M.teardown(files_dir)
  if files_dir then
    vim.fn.delete(files_dir, "rf")
  end
  -- Clear quickfix
  vim.fn.setqflist({}, "r", { title = "", items = {} })
  -- Clear location list of every window (best effort)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    pcall(vim.fn.setloclist, win, {}, "r", { title = "", items = {} })
  end
end

return M
