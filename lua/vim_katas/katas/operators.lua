-- Operator katas: delete, change, yank, repeat, indent, etc.
return {
  {
    id       = "op_001",
    category = "operators",
    title    = "Delete to end of line (D)",
    difficulty = 1,
    filetype = "go",
    lines    = { "    name := getName() // TODO: validate" },
    cursor   = { row = 1, col = 24 },  -- on the space before '//'
    instructions = [[
KATA: Delete to End of Line
────────────────────────────
Delete from the cursor to the
end of the line (the comment).

Cursor is on the space before
the // comment.

Expected:
    name := getName()

Motion: D
]],
    hint              = "'D' deletes from cursor to end of line",
    optimal_keystrokes = 1,
    validate = function(ctx)
      local expected = "    name := getName()"
      if ctx.lines[1] == expected then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        'Expected: [%s]\nGot:      [%s]', expected, ctx.lines[1]) }
    end,
  },

  {
    id       = "op_002",
    category = "operators",
    title    = "Delete three lines (3dd)",
    difficulty = 1,
    filetype = "go",
    lines    = {
      "func setup() {",
      "    // legacy init",
      "    initDB()",
      "    initCache()",
      "    startWorker()",
      "}",
    },
    cursor   = { row = 2, col = 0 },  -- on '// legacy init'
    instructions = [[
KATA: Delete Three Lines
─────────────────────────
Delete the three lines:
  // legacy init
  initDB()
  initCache()

Leave the function shell intact.

Expected:
func setup() {
    startWorker()
}

Motion: 3dd
]],
    hint              = "'3dd' deletes 3 lines",
    optimal_keystrokes = 3,
    validate = function(ctx)
      local expected = {
        "func setup() {",
        "    startWorker()",
        "}",
      }
      if #ctx.lines ~= 3 then
        return { success = false, message = string.format(
          "Expected 3 lines, got %d", #ctx.lines) }
      end
      for i, line in ipairs(expected) do
        if ctx.lines[i] ~= line then
          return { success = false, message = string.format(
            "Line %d: expected [%s], got [%s]", i, line, ctx.lines[i]) }
        end
      end
      return { success = true, message = "Correct." }
    end,
  },

  {
    id       = "op_003",
    category = "operators",
    title    = "Dot repeat (.)",
    difficulty = 2,
    filetype = "go",
    lines    = {
      'log.Print("starting")',
      'log.Print("loading")',
      'log.Print("done")',
    },
    cursor   = { row = 1, col = 4 },  -- on 'P' of Print
    instructions = [[
KATA: Dot Repeat
─────────────────
Change 'Print' to 'Println' on
all three lines using the dot
repeat command.

Steps:
1. Change 'Print' to 'Println'
   on line 1 (ciw or cw)
2. Move down, use . to repeat
3. Move down, use . again

Motion: ciw → type → j.j.
]],
    hint              = "Make one change, then repeat with '.' after moving",
    optimal_keystrokes = 12,
    validate = function(ctx)
      local expected = {
        'log.Println("starting")',
        'log.Println("loading")',
        'log.Println("done")',
      }
      for i, line in ipairs(expected) do
        if ctx.lines[i] ~= line then
          return { success = false, message = string.format(
            "Line %d: expected [%s], got [%s]", i, line, ctx.lines[i] or "") }
        end
      end
      return { success = true, message = "Correct." }
    end,
  },

  {
    id       = "op_004",
    category = "operators",
    title    = "Indent block (>)",
    difficulty = 2,
    filetype = "go",
    lines    = {
      "func handler(w http.ResponseWriter, r *http.Request) {",
      "if r.Method != \"GET\" {",
      "http.Error(w, \"not allowed\", 405)",
      "return",
      "}",
      "}",
    },
    cursor   = { row = 2, col = 0 },
    instructions = [[
KATA: Indent a Block
─────────────────────
Lines 2-5 need to be indented
by one level (one tab/shiftwidth).

Expected (using tabs):
func handler(...) {
    if r.Method != "GET" {
        http.Error(...)
        return
    }
}

Select lines 2-5 visually
and indent with >.

Motion: V3j>
]],
    hint              = "Use 'V3j>' to visually select and indent",
    optimal_keystrokes = 4,
    validate = function(ctx)
      -- Accept either tab or 4-space indent
      local line2 = ctx.lines[2]
      local ok = line2:match("^\t") or line2:match("^    ")
      if ok then
        return { success = true, message = "Lines indented correctly." }
      end
      return { success = false, message = "Line 2 is not indented. Expected tab or 4 spaces." }
    end,
  },

  {
    id       = "op_005",
    category = "operators",
    title    = "Join lines (J)",
    difficulty = 1,
    filetype = "go",
    lines    = {
      "errMsg :=",
      '    "connection timed out"',
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Join Lines
─────────────────
Join the two lines into one,
removing the line break.

Expected:
errMsg := "connection timed out"

Motion: J
]],
    hint              = "'J' joins the current and next line",
    optimal_keystrokes = 1,
    validate = function(ctx)
      if #ctx.lines ~= 1 then
        return { success = false, message = string.format(
          "Expected 1 line, got %d", #ctx.lines) }
      end
      local expected = 'errMsg := "connection timed out"'
      if ctx.lines[1] == expected then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        "Expected: [%s]\nGot:      [%s]", expected, ctx.lines[1]) }
    end,
  },

  {
    id       = "op_006",
    category = "operators",
    title    = "Change to end of line (C)",
    difficulty = 1,
    filetype = "go",
    lines    = { "    return nil, fmt.Errorf(\"not implemented\")" },
    cursor   = { row = 1, col = 11 },  -- on 'n' of 'nil,'
    instructions = [[
KATA: Change to End of Line
────────────────────────────
Delete from cursor to end of
line and enter insert mode.

Replace everything from 'nil'
onward with:
  errors.New("not found")

Expected:
    return errors.New("not found")

Motion: C  then type replacement
]],
    hint              = "'C' clears to end of line and enters insert",
    optimal_keystrokes = 26,
    validate = function(ctx)
      local expected = '    return errors.New("not found")'
      if ctx.lines[1] == expected then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        'Expected: [%s]\nGot:      [%s]', expected, ctx.lines[1]) }
    end,
  },

  {
    id       = "op_007",
    category = "operators",
    title    = "Uppercase a range (gU)",
    difficulty = 2,
    filetype = "text",
    lines    = { "the quick brown fox" },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Uppercase the Line
─────────────────────────
Convert the entire line to
uppercase.

Expected:
THE QUICK BROWN FOX

Motion: gUU  or  gU$
]],
    hint              = "'gUU' uppercases the entire current line",
    optimal_keystrokes = 3,
    validate = function(ctx)
      local expected = "THE QUICK BROWN FOX"
      if ctx.lines[1] == expected then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        "Expected: [%s]\nGot:      [%s]", expected, ctx.lines[1]) }
    end,
  },

  {
    id       = "op_008",
    category = "operators",
    title    = "Yank and paste line below",
    difficulty = 1,
    filetype = "go",
    lines    = {
      "func (s *Server) Start() error {",
      "    return s.serve()",
      "}",
      "",
      "func (s *Server) Stop() error {",
      "}",
    },
    cursor   = { row = 2, col = 0 },  -- on 'return s.serve()'
    instructions = [[
KATA: Duplicate Line
─────────────────────
Duplicate the 'return s.serve()'
line to fix the Stop() method.

Yank line 2 and paste it inside
the Stop() function (after line 5).

Steps:
1. Yank line 2 with: yy
2. Jump to line 5: 5G
3. Paste below: p

Motion: yy  5G  p
]],
    hint              = "yy to yank, navigate, p to paste below",
    optimal_keystrokes = 5,
    validate = function(ctx)
      if #ctx.lines ~= 7 then
        return { success = false, message = string.format(
          "Expected 7 lines, got %d", #ctx.lines) }
      end
      if ctx.lines[6] == "    return s.serve()" then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        "Line 6 should be '    return s.serve()', got [%s]", ctx.lines[6]) }
    end,
  },

  {
    id       = "op_009",
    category = "operators",
    title    = "Delete word backward (db)",
    difficulty = 2,
    filetype = "go",
    lines    = { "    result, err := fetchUser(userID)" },
    cursor   = { row = 1, col = 35 },  -- on ')' at end... let me recalculate
    -- "    result, err := fetchUser(userID)"
    --  0                              34
    -- cursor on ')' which is at index 34
    cursor   = { row = 1, col = 29 },  -- on 'u' of 'userID'
    instructions = [[
KATA: Delete Word Backward
───────────────────────────
Delete the word 'userID'
using a backward delete.

Cursor is at the end of
the line on ')'.

Navigate to end, then db.

Actually: cursor is on 'u'
of 'userID'.

Delete 'userID' using db or daw.

Expected:
    result, err := fetchUser()

Motion: daw  (or diw since no space to keep)
]],
    hint              = "'daw' deletes the word and surrounding space",
    optimal_keystrokes = 3,
    validate = function(ctx)
      local expected = "    result, err := fetchUser()"
      if ctx.lines[1] == expected then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        'Expected: [%s]\nGot:      [%s]', expected, ctx.lines[1]) }
    end,
  },

  {
    id       = "op_010",
    category = "operators",
    title    = "Toggle case (~)",
    difficulty = 1,
    filetype = "go",
    lines    = { "const maxRetries = 3" },
    cursor   = { row = 1, col = 6 },  -- on 'm' of 'maxRetries'
    instructions = [[
KATA: Uppercase Constant Name
──────────────────────────────
Change 'maxRetries' to all caps
'MAXRETRIES' in place.

Cursor is on 'm' of 'maxRetries'.

Use gU with a motion to uppercase
the word.

Expected:
const MAXRETRIES = 3

Motion: gUiw  (uppercase inner word)
]],
    hint              = "'gUiw' uppercases the word under cursor",
    optimal_keystrokes = 4,
    validate = function(ctx)
      local expected = "const MAXRETRIES = 3"
      if ctx.lines[1] == expected then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        'Expected: [%s]\nGot:      [%s]', expected, ctx.lines[1]) }
    end,
  },
}
