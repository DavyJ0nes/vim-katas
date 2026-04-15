-- Search and replace katas.
return {
  {
    id       = "search_001",
    category = "search_replace",
    title    = "Global substitution (:s)",
    difficulty = 2,
    filetype = "go",
    lines    = {
      'var errNotFound = errors.New("not found")',
      'var errTimeout = errors.New("timeout")',
      'var errBadInput = errors.New("bad input")',
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Rename All Variables
───────────────────────────
Rename the prefix 'err' to
'Err' (exported) in all three
variable declarations.

Expected:
var ErrNotFound = ...
var ErrTimeout = ...
var ErrBadInput = ...

Use: :%s/\berr\b/Err/g

Note: \b is a word boundary.
]],
    hint              = ":%s/\\berr/Err/g renames err prefix",
    optimal_keystrokes = 18,
    validate = function(ctx)
      for i, line in ipairs(ctx.lines) do
        if line:match("var err") then
          return { success = false, message = string.format(
            "Line %d still has lowercase 'err' variable: [%s]", i, line) }
        end
        if not line:match("var Err") then
          return { success = false, message = string.format(
            "Line %d missing uppercase 'Err' variable: [%s]", i, line) }
        end
      end
      return { success = true, message = "All variables renamed." }
    end,
  },

  {
    id       = "search_002",
    category = "search_replace",
    title    = "Delete lines matching pattern (:g/d)",
    difficulty = 3,
    filetype = "go",
    lines    = {
      "func main() {",
      "    // TODO: implement auth",
      "    setupServer()",
      "    // TODO: add logging",
      "    startListening()",
      "    // TODO: graceful shutdown",
      "}",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Delete TODO Comments
───────────────────────────
Delete all lines containing
'// TODO' using the global
command.

Expected:
func main() {
    setupServer()
    startListening()
}

Use: :g/TODO/d
]],
    hint              = "':g/TODO/d' deletes all matching lines",
    optimal_keystrokes = 12,
    validate = function(ctx)
      for i, line in ipairs(ctx.lines) do
        if line:match("TODO") then
          return { success = false, message = string.format(
            "Line %d still contains TODO: [%s]", i, line) }
        end
      end
      local expected = {
        "func main() {",
        "    setupServer()",
        "    startListening()",
        "}",
      }
      if #ctx.lines ~= #expected then
        return { success = false, message = string.format(
          "Expected %d lines, got %d", #expected, #ctx.lines) }
      end
      return { success = true, message = "TODO lines deleted." }
    end,
  },

  {
    id       = "search_003",
    category = "search_replace",
    title    = "Change next match (cgn)",
    difficulty = 3,
    filetype = "go",
    lines    = {
      'fmt.Println("debug: starting")',
      'fmt.Println("debug: loaded")',
      'fmt.Println("debug: ready")',
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Change Next Match (cgn)
──────────────────────────────
Replace 'debug' with 'info'
in all three lines using the
cgn + dot-repeat technique.

Steps:
1. Search: /debug<CR>
2. Change match: cgn  then type 'info'
3. Dot repeat: ..  (twice)

This is the efficient way to
replace multiple instances.

Motion: /debug<CR>  cgn info<Esc>  ..
]],
    hint              = "/debug<CR> cgn then type replacement, dot repeat",
    optimal_keystrokes = 18,
    validate = function(ctx)
      for i, line in ipairs(ctx.lines) do
        if line:find("debug") then
          return { success = false, message = string.format(
            "Line %d still has 'debug': [%s]", i, line) }
        end
        if not line:find("info") then
          return { success = false, message = string.format(
            "Line %d missing 'info': [%s]", i, line) }
        end
      end
      return { success = true, message = "All 'debug' replaced with 'info'." }
    end,
  },

  {
    id       = "search_004",
    category = "search_replace",
    title    = "Global command with norm (:g/norm)",
    difficulty = 4,
    filetype = "text",
    lines    = {
      "apple",
      "banana",
      "cherry",
      "date",
      "elderberry",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Append to Every Line
───────────────────────────
Add ' (fruit)' to the end of
every line using :g/norm.

Expected:
apple (fruit)
banana (fruit)
cherry (fruit)
date (fruit)
elderberry (fruit)

Use: :g/./norm A (fruit)
     (matches all non-empty lines)
]],
    hint              = "':g/./norm A (fruit)' appends to all lines",
    optimal_keystrokes = 20,
    validate = function(ctx)
      for i, line in ipairs(ctx.lines) do
        if not line:match(" %(fruit%)$") then
          return { success = false, message = string.format(
            "Line %d missing ' (fruit)': [%s]", i, line) }
        end
      end
      return { success = true, message = "Correct." }
    end,
  },

  {
    id       = "search_005",
    category = "search_replace",
    title    = "Substitute with capture group",
    difficulty = 4,
    filetype = "go",
    lines    = {
      'log.Printf("user: %s, id: %d", userName, userID)',
      'log.Printf("method: %s, path: %s", method, path)',
      'log.Printf("status: %d, dur: %v", statusCode, duration)',
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Wrap Printf with Context
───────────────────────────────
Change log.Printf(...) to
log.Ctx(ctx).Printf(...) on
all lines.

Expected:
log.Ctx(ctx).Printf(...)
log.Ctx(ctx).Printf(...)
log.Ctx(ctx).Printf(...)

Use: :%s/log\.Printf/log.Ctx(ctx).Printf/g
]],
    hint              = ":%s/log\\.Printf/log.Ctx(ctx).Printf/g",
    optimal_keystrokes = 40,
    validate = function(ctx)
      for i, line in ipairs(ctx.lines) do
        if line:match("log%.Printf") and not line:match("log%.Ctx") then
          return { success = false, message = string.format(
            "Line %d not updated: [%s]", i, line) }
        end
        if not line:match("log%.Ctx%(ctx%)%.Printf") then
          return { success = false, message = string.format(
            "Line %d not in expected form: [%s]", i, line) }
        end
      end
      return { success = true, message = "All Printf calls wrapped with Ctx." }
    end,
  },

  {
    id       = "search_006",
    category = "search_replace",
    title    = "Search word under cursor (*)",
    difficulty = 1,
    filetype = "go",
    lines    = {
      "func validateUser(user *User) error {",
      "    if user == nil {",
      "        return ErrNilUser",
      "    }",
      "    if user.Name == \"\" {",
      "        return ErrEmptyName",
      "    }",
      "    return nil",
      "}",
    },
    cursor   = { row = 2, col = 7 },  -- on 'user' in 'if user == nil'
    instructions = [[
KATA: Navigate Word Matches
────────────────────────────
Use '*' to search for all
occurrences of 'user' and
navigate to the THIRD match.

Start: cursor on 'user' (line 2)
End:   cursor on 'user' on line 5
       (the 'user.Name' check)

Motion: *  n  (two more jumps)
]],
    hint              = "'*' searches word under cursor, 'n' for next",
    optimal_keystrokes = 2,
    validate = function(ctx)
      if ctx.cursor.row == 5 then
        return { success = true, message = "On the third 'user' match." }
      end
      return { success = false, message = string.format(
        "Expected row 5 (third 'user' occurrence), got row %d", ctx.cursor.row) }
    end,
  },

  {
    id       = "search_007",
    category = "search_replace",
    title    = "Substitute in a range",
    difficulty = 3,
    filetype = "go",
    lines    = {
      "func oldHandler() {}",
      "func oldProcessor() {}",
      "func oldValidator() {}",
      "",
      "// legacy section below — do not rename",
      "func oldLegacy() {}",
      "func oldCompat() {}",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Rename Within a Range
────────────────────────────
Rename 'old' to 'new' only
in lines 1-3, not the legacy
section below.

Expected (lines 1-3 only):
func newHandler() {}
func newProcessor() {}
func newValidator() {}

Use: :1,3s/old/new/g
]],
    hint              = "':1,3s/old/new/g' substitutes only in range",
    optimal_keystrokes = 16,
    validate = function(ctx)
      -- Lines 1-3 should have 'new', lines 6-7 should still have 'old'
      for i = 1, 3 do
        if ctx.lines[i] and ctx.lines[i]:match("old[HPA]") then
          return { success = false, message = string.format(
            "Line %d still has 'old': [%s]", i, ctx.lines[i]) }
        end
      end
      for i = 6, 7 do
        if ctx.lines[i] and not ctx.lines[i]:match("old") then
          return { success = false, message = string.format(
            "Line %d should still have 'old' (not renamed): [%s]", i, ctx.lines[i] or "") }
        end
      end
      return { success = true, message = "Correct range substitution." }
    end,
  },

  {
    id       = "search_008",
    category = "search_replace",
    title    = "Delete trailing whitespace",
    difficulty = 2,
    filetype = "text",
    lines    = {
      "line one   ",
      "line two      ",
      "line three  ",
      "line four",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Strip Trailing Whitespace
────────────────────────────────
Remove trailing spaces from
all lines that have them.

Expected (no trailing spaces):
line one
line two
line three
line four

Use: :%s/\s\+$//
]],
    hint              = ":%s/\\s\\+$// removes trailing whitespace",
    optimal_keystrokes = 13,
    validate = function(ctx)
      for i, line in ipairs(ctx.lines) do
        if line:match("%s+$") then
          return { success = false, message = string.format(
            "Line %d still has trailing whitespace: [%s]", i, line) }
        end
      end
      return { success = true, message = "Trailing whitespace removed." }
    end,
  },
}
