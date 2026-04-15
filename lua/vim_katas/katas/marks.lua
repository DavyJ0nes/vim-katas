-- Marks katas: setting, jumping, and using marks for navigation.
return {
  {
    id       = "marks_001",
    category = "marks",
    title    = "Set mark and jump back",
    difficulty = 2,
    filetype = "go",
    lines    = {
      "package main",
      "",
      "import (",
      '    "fmt"',
      '    "os"',
      ")",
      "",
      "func main() {",
      "    args := os.Args[1:]",
      "    fmt.Println(args)",
      "}",
    },
    cursor   = { row = 8, col = 0 },  -- on 'func main()'
    instructions = [[
KATA: Set Mark, Navigate, Return
──────────────────────────────────
1. Set mark 'a' on line 8 (ma)
2. Jump to line 4 ("fmt" import)
3. Jump back to mark 'a' ('a)

End position: line 8, col 0.

Motion: ma  4G  'a
]],
    hint              = "'ma' sets mark a, ''a' jumps to it",
    optimal_keystrokes = 5,
    validate = function(ctx)
      if ctx.cursor.row == 8 then
        return { success = true, message = "Back on the marked line." }
      end
      return { success = false, message = string.format(
        "Expected row 8 (mark 'a' location), got %d", ctx.cursor.row) }
    end,
  },

  {
    id       = "marks_002",
    category = "marks",
    title    = "Exact position mark (`a)",
    difficulty = 2,
    filetype = "go",
    lines    = {
      "func processRequest(w http.ResponseWriter, r *http.Request) {",
      "    ctx := r.Context()",
      "    userID := ctx.Value(userKey).(string)",
      "    log.Printf(ctx, \"processing for %s\", userID)",
      "}",
    },
    cursor   = { row = 3, col = 13 },  -- on 'ctx' in line 3
    instructions = [[
KATA: Exact Position Mark
──────────────────────────
1. Set exact mark 'z' here
   (line 3, col 13 — the 'ctx')
2. Jump to line 1
3. Return to exact position with `z

The backtick (` z) restores
exact row AND column.

Motion: mz  gg  `z
]],
    hint              = "'mz' sets mark, '`z' returns to exact position",
    optimal_keystrokes = 5,
    validate = function(ctx)
      if ctx.cursor.row == 3 and ctx.cursor.col == 13 then
        return { success = true, message = "Exact position restored." }
      end
      return { success = false, message = string.format(
        "Expected {row=3, col=13}, got {row=%d, col=%d}",
        ctx.cursor.row, ctx.cursor.col) }
    end,
  },

  {
    id       = "marks_003",
    category = "marks",
    title    = "Yank between marks",
    difficulty = 3,
    filetype = "go",
    lines    = {
      "// START_BLOCK",
      "func helper() {",
      "    doSomething()",
      "}",
      "// END_BLOCK",
      "",
      "func main() {",
      "}",
    },
    cursor   = { row = 2, col = 0 },
    instructions = [[
KATA: Yank Between Two Marks
──────────────────────────────
Yank lines 2-4 (the helper
function) using two marks.

Steps:
1. Set mark 'a' on line 2 (ma)
2. Jump to line 4 (4G)
3. Set mark 'b' (mb)
4. Yank from mark a to b: y'a
   (or: 'ay'b)
5. Paste after line 7: 7Gp

Expected: helper() duplicated
inside main's area.

Motion: ma  4G  mb  y'a  7G  p
]],
    hint              = "Set two marks, then y'a yanks between them",
    optimal_keystrokes = 9,
    validate = function(ctx)
      -- After paste, lines 9-11 should be the helper function
      if #ctx.lines < 11 then
        return { success = false, message = string.format(
          "Expected at least 11 lines, got %d", #ctx.lines) }
      end
      if ctx.lines[9] == "func helper() {" then
        return { success = true, message = "Function duplicated correctly." }
      end
      return { success = false, message = string.format(
        "Line 9 should be 'func helper() {', got [%s]", ctx.lines[9] or "") }
    end,
  },

  {
    id       = "marks_004",
    category = "marks",
    title    = "Jump to last change (`.)",
    difficulty = 2,
    filetype = "go",
    lines    = {
      "var config = Config{",
      '    Host: "localhost",',
      '    Port: 8080,',
      '    Debug: false,',
      "}",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Return to Last Change
────────────────────────────
1. Change 'false' to 'true'
   on line 4 (navigate there
   and make the edit)
2. Jump back to line 1 (gg)
3. Use `. to jump back to where
   you made the last change

The `. mark always points to
the position of the last change.

Motion: 4G  ciw true<Esc>  gg  `.
]],
    hint              = "'`.' jumps to position of last change",
    optimal_keystrokes = 14,
    validate = function(ctx)
      -- The file should have 'true' on line 4 AND cursor near line 4
      local line4 = ctx.lines[4] or ""
      if not line4:find("true") then
        return { success = false, message = "Line 4 still shows 'false' — make the change first." }
      end
      if ctx.cursor.row == 4 then
        return { success = true, message = "Returned to last change." }
      end
      return { success = false, message = string.format(
        "Expected cursor at row 4 (last change), got %d", ctx.cursor.row) }
    end,
  },
}
