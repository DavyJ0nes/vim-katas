-- Quickfix / multi-file katas.
-- These use ctx.files_dir to set up temp files.
-- validate reads files from disk to check results.
return {
  {
    id       = "qf_001",
    category = "quickfix",
    title    = "Populate quickfix with :vimgrep",
    difficulty = 3,
    filetype = "go",
    files = {
      {
        name  = "main.go",
        lines = {
          "package main",
          "",
          'func main() { runApp() }',
        },
      },
      {
        name  = "server.go",
        lines = {
          "package main",
          "",
          "func runApp() {",
          "    startServer()",
          "    startWorker()",
          "}",
        },
      },
      {
        name  = "worker.go",
        lines = {
          "package main",
          "",
          "func startWorker() {",
          "    // TODO: implement",
          "}",
        },
      },
    },
    cursor = { row = 1, col = 0 },
    instructions = [[
KATA: Find with vimgrep
────────────────────────
Populate the quickfix list with
all occurrences of 'func' across
the three .go files.

Use: :vimgrep /func/ *.go

Then navigate to the THIRD match
using :cnext (or :cn).

After: run :clist to verify,
submit with <leader>ks.

Expected: cursor on the 3rd
'func' match (server.go line 3).
]],
    hint              = ":vimgrep /func/ *.go  then :cnext twice",
    optimal_keystrokes = 25,
    validate = function(ctx)
      -- Check the quickfix list is populated with func occurrences
      local qflist = vim.fn.getqflist()
      if #qflist < 3 then
        return { success = false, message = string.format(
          "Quickfix list has %d entries, expected at least 3", #qflist) }
      end
      -- Check that at least some entries mention 'func'
      local func_count = 0
      for _, entry in ipairs(qflist) do
        if entry.text and entry.text:match("func") then
          func_count = func_count + 1
        end
      end
      if func_count < 2 then
        return { success = false, message = "Quickfix list doesn't appear to contain 'func' matches" }
      end
      return { success = true, message = string.format(
        "Quickfix populated with %d matches.", #qflist) }
    end,
  },

  {
    id       = "qf_002",
    category = "quickfix",
    title    = "Multi-file rename with :cfdo",
    difficulty = 4,
    filetype = "go",
    files = {
      {
        name  = "api.go",
        lines = {
          "package api",
          "",
          "func HandleRequest(req *Request) {}",
          "func ValidateRequest(req *Request) bool { return true }",
        },
      },
      {
        name  = "handler.go",
        lines = {
          "package api",
          "",
          "type Request struct {",
          "    Body []byte",
          "    Headers map[string]string",
          "}",
          "",
          "func NewRequest() *Request {",
          "    return &Request{}",
          "}",
        },
      },
      {
        name  = "middleware.go",
        lines = {
          "package api",
          "",
          "func LogRequest(req *Request) {",
          "    // log the request",
          "}",
        },
      },
    },
    cursor = { row = 1, col = 0 },
    instructions = [[
KATA: Rename Type Across Files
───────────────────────────────
Rename 'Request' to 'HttpRequest'
across all three files.

Steps:
1. Populate quickfix:
   :vimgrep /Request/ *.go

2. Rename in all files:
   :cfdo %s/Request/HttpRequest/g | w

3. Verify with :cfdo or
   manually check files.

The '| w' saves each file
after substitution.
]],
    hint              = ":vimgrep /Request/ *.go  then :cfdo %s/Request/HttpRequest/g | w",
    optimal_keystrokes = 50,
    validate = function(ctx)
      if not ctx.files_dir then
        return { success = false, message = "files_dir not set (internal error)" }
      end
      local files = { "api.go", "handler.go", "middleware.go" }
      for _, fname in ipairs(files) do
        local path = ctx.files_dir .. "/" .. fname
        local f = io.open(path, "r")
        if not f then
          return { success = false, message = string.format(
            "Cannot open %s for verification", fname) }
        end
        local content = f:read("*a")
        f:close()
        if content:find("Request") and not content:find("HttpRequest") then
          -- There's a bare 'Request' that isn't part of 'HttpRequest'
          -- Simple check: if 'Request' appears without 'HttpRequest' prefix
          local bare = content:gsub("HttpRequest", ""):find("Request")
          if bare then
            return { success = false, message = string.format(
              "%s still contains unrenamed 'Request'", fname) }
          end
        end
      end
      return { success = true, message = "All 'Request' occurrences renamed." }
    end,
  },

  {
    id       = "qf_003",
    category = "quickfix",
    title    = "Location list navigation",
    difficulty = 3,
    filetype = "go",
    files = {
      {
        name  = "errors.go",
        lines = {
          "package main",
          "",
          "// TODO: add error context",
          "var ErrNotFound = errors.New(\"not found\")",
          "// TODO: wrap this error",
          "var ErrForbidden = errors.New(\"forbidden\")",
          "// TODO: add stack trace",
          "var ErrInternal = errors.New(\"internal error\")",
        },
      },
    },
    cursor = { row = 1, col = 0 },
    instructions = [[
KATA: Use Location List
────────────────────────
Find all TODO comments in the
current file using location list
(local to the window, unlike qf).

Use: :lvimgrep /TODO/ %

Navigate to the SECOND TODO
with :lnext.

Then delete the TODO line you
land on.

After: submit with <leader>ks.
]],
    hint              = ":lvimgrep /TODO/ %  then :lnext to navigate",
    optimal_keystrokes = 20,
    validate = function(ctx)
      -- Check that exactly one TODO was deleted from the buffer
      local todo_count = 0
      for _, line in ipairs(ctx.lines) do
        if line:match("TODO") then todo_count = todo_count + 1 end
      end
      if todo_count == 2 then
        return { success = true, message = "One TODO deleted, two remain." }
      end
      if todo_count == 3 then
        return { success = false, message = "No TODO lines were deleted." }
      end
      if todo_count < 2 then
        return { success = false, message = string.format(
          "Too many TODO lines deleted. Expected 2 remaining, got %d.", todo_count) }
      end
      return { success = false, message = string.format(
        "Expected 2 TODO lines remaining, got %d", todo_count) }
    end,
  },

  {
    id       = "qf_004",
    category = "quickfix",
    title    = "Quickfix with :cdo",
    difficulty = 4,
    filetype = "go",
    files = {
      {
        name  = "config.go",
        lines = {
          "package config",
          "",
          "const DefaultTimeout = 30",
          "const DefaultRetries = 3",
        },
      },
      {
        name  = "client.go",
        lines = {
          "package main",
          "",
          "var timeout = DefaultTimeout",
          "var retries = DefaultRetries",
        },
      },
      {
        name  = "server.go",
        lines = {
          "package main",
          "",
          "var srvTimeout = DefaultTimeout",
        },
      },
    },
    cursor = { row = 1, col = 0 },
    instructions = [[
KATA: cdo vs cfdo
──────────────────
Rename 'DefaultTimeout' to
'config.DefaultTimeout' on EVERY
matching LINE (not every file).

:cdo runs a command once per
quickfix ENTRY (each match line).
:cfdo runs once per FILE.

Steps:
1. :vimgrep /DefaultTimeout/ *.go
2. :cdo s/DefaultTimeout/config.DefaultTimeout/g | w

This replaces only on lines
in the quickfix list.
]],
    hint              = ":vimgrep then :cdo s/DefaultTimeout/config.DefaultTimeout/g | w",
    optimal_keystrokes = 60,
    validate = function(ctx)
      if not ctx.files_dir then
        return { success = false, message = "files_dir not set" }
      end
      -- client.go and server.go should have the renamed constant
      local check_files = { "client.go", "server.go" }
      for _, fname in ipairs(check_files) do
        local path = ctx.files_dir .. "/" .. fname
        local f = io.open(path, "r")
        if not f then
          return { success = false, message = "Cannot open " .. fname }
        end
        local content = f:read("*a")
        f:close()
        if not content:find("config%.DefaultTimeout") then
          return { success = false, message = fname .. " missing 'config.DefaultTimeout'" }
        end
      end
      return { success = true, message = "All occurrences renamed with namespace." }
    end,
  },
}
