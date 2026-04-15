-- Visual mode katas.
return {
  {
    id       = "visual_001",
    category = "visual_mode",
    title    = "Visual line indent",
    difficulty = 2,
    filetype = "go",
    lines    = {
      "if err != nil {",
      "return err",
      "fmt.Println(err)",
      "os.Exit(1)",
      "}",
    },
    cursor   = { row = 2, col = 0 },
    instructions = [[
KATA: Indent Three Lines
─────────────────────────
Indent lines 2-4 by one level.

Select with visual line mode
and press > to indent.

Expected:
if err != nil {
    return err
    fmt.Println(err)
    os.Exit(1)
}

Motion: V2j>
]],
    hint              = "'V2j>' selects 3 lines and indents them",
    optimal_keystrokes = 4,
    validate = function(ctx)
      local line2 = ctx.lines[2]
      local indented = line2:match("^\t") or line2:match("^    ") or line2:match("^  ")
      if indented then
        return { success = true, message = "Lines indented correctly." }
      end
      return { success = false, message = "Line 2 is not indented. Use V2j> to indent." }
    end,
  },

  {
    id       = "visual_002",
    category = "visual_mode",
    title    = "Visual block insert",
    difficulty = 3,
    filetype = "go",
    lines    = {
      'log.Print("connecting")',
      'log.Print("connected")',
      'log.Print("running")',
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Visual Block Insert
──────────────────────────
Add '// ' as a comment prefix
to all three lines simultaneously.

Use visual block mode to insert
at the start of each line.

Expected:
// log.Print("connecting")
// log.Print("connected")
// log.Print("running")

Motion: Ctrl-v  G  I  //   Esc
]],
    hint              = "<C-v>GI// <Esc> inserts at start of all lines",
    optimal_keystrokes = 8,
    validate = function(ctx)
      for i, line in ipairs(ctx.lines) do
        if not line:match("^// ") then
          return { success = false, message = string.format(
            "Line %d does not start with '// ': [%s]", i, line) }
        end
      end
      return { success = true, message = "All lines commented." }
    end,
  },

  {
    id       = "visual_003",
    category = "visual_mode",
    title    = "Visual block delete column",
    difficulty = 3,
    filetype = "text",
    lines    = {
      "| ID | Name  | Age |",
      "| 1  | Alice | 25  |",
      "| 2  | Bob   | 30  |",
      "| 3  | Carol | 28  |",
    },
    cursor   = { row = 1, col = 5 },  -- on 'N' of "Name" header
    instructions = [[
KATA: Delete a Column
──────────────────────
Delete the 'Name' column
(including its separators) from
all four rows using visual block.

Hint: use Ctrl-v to select
the column characters, then d.

Expected (something like):
| ID | Age |
| 1  | 25  |
| 2  | 30  |
| 3  | 28  |

The exact spacing may vary;
the Name column must be gone.
]],
    hint              = "<C-v> to enter block mode, select column, then 'd'",
    optimal_keystrokes = 8,
    validate = function(ctx)
      for i, line in ipairs(ctx.lines) do
        if line:find("Name") or line:find("Alice") or line:find("Bob") or line:find("Carol") then
          return { success = false, message = string.format(
            "Line %d still contains name data: [%s]", i, line) }
        end
      end
      return { success = true, message = "Name column removed." }
    end,
  },

  {
    id       = "visual_004",
    category = "visual_mode",
    title    = "Re-select and indent (gv>)",
    difficulty = 3,
    filetype = "python",
    lines    = {
      "def process():",
      "x = get_data()",
      "y = transform(x)",
      "return y",
    },
    cursor   = { row = 2, col = 0 },
    instructions = [[
KATA: Double Indent
────────────────────
Indent lines 2-4 by TWO levels.

Approach:
1. Select lines 2-4: V2j
2. Indent once: >
3. Re-select: gv
4. Indent again: >

Motion: V2j>gv>
]],
    hint              = "'gv' re-selects last visual selection",
    optimal_keystrokes = 6,
    validate = function(ctx)
      local line2 = ctx.lines[2]
      -- Should have at least 8 spaces or 2 tabs of indent
      local spaces = line2:match("^(%s+)")
      if spaces and #spaces >= 8 then
        return { success = true, message = "Double-indented correctly." }
      end
      if spaces and #spaces >= 4 then
        -- Check for tabs (2 tabs = good)
        local tabs = line2:match("^(\t+)")
        if tabs and #tabs >= 2 then
          return { success = true, message = "Double-indented correctly." }
        end
        return { success = false, message = "Only single indent detected. Need two levels." }
      end
      return { success = false, message = "Lines are not double-indented." }
    end,
  },

  {
    id       = "visual_005",
    category = "visual_mode",
    title    = "Select and yank between markers",
    difficulty = 2,
    filetype = "text",
    lines    = {
      "BEGIN_DATA",
      "line one",
      "line two",
      "line three",
      "END_DATA",
      "",
      "PASTE_HERE:",
    },
    cursor   = { row = 2, col = 0 },
    instructions = [[
KATA: Yank and Paste a Range
──────────────────────────────
Yank lines 2-4 (between the
markers) and paste them after
the PASTE_HERE: line.

Steps:
1. Select lines 2-4: V2j
2. Yank: y
3. Jump to line 7: 7G
4. Paste below: p

Motion: V2jy  7G  p
]],
    hint              = "V2jy to yank, then 7Gp to paste",
    optimal_keystrokes = 7,
    validate = function(ctx)
      -- Lines 8-10 should be "line one", "line two", "line three"
      if #ctx.lines < 10 then
        return { success = false, message = string.format(
          "Expected at least 10 lines, got %d", #ctx.lines) }
      end
      local ok = ctx.lines[8] == "line one"
        and ctx.lines[9] == "line two"
        and ctx.lines[10] == "line three"
      if ok then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        "Expected lines 8-10 to be 'line one/two/three', got:\n  [%s]\n  [%s]\n  [%s]",
        ctx.lines[8] or "nil", ctx.lines[9] or "nil", ctx.lines[10] or "nil") }
    end,
  },

  {
    id       = "visual_006",
    category = "visual_mode",
    title    = "Visual block number column",
    difficulty = 3,
    filetype = "text",
    lines    = {
      "  apple",
      "  banana",
      "  cherry",
      "  date",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Remove Leading Spaces
────────────────────────────
Remove the two leading spaces
from all four lines using
visual block mode.

Expected:
apple
banana
cherry
date

Motion: Ctrl-v  3j  2l  d
        (or Ctrl-v 3j 2x)
]],
    hint              = "<C-v>3j2ld removes 2 chars from 4 lines",
    optimal_keystrokes = 6,
    validate = function(ctx)
      local expected = { "apple", "banana", "cherry", "date" }
      for i, line in ipairs(expected) do
        if ctx.lines[i] ~= line then
          return { success = false, message = string.format(
            "Line %d: expected [%s], got [%s]", i, line, ctx.lines[i] or "") }
        end
      end
      return { success = true, message = "Leading spaces removed." }
    end,
  },
}
