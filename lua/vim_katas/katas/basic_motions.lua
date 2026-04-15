-- Basic cursor motion katas.
-- Validate functions check cursor position; content is unchanged.
return {
  {
    id       = "motion_001",
    category = "basic_motions",
    title    = "Jump to end of line",
    difficulty = 1,
    filetype = "text",
    lines    = { "The quick brown fox jumps over the lazy dog" },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Jump to End of Line
─────────────────────────
Move the cursor to the last
character of the line.

The cursor starts at column 0.
Reach the 'd' at the end.

Motion: $
]],
    hint              = "Press '$' to jump to end of line",
    optimal_keystrokes = 1,
    validate = function(ctx)
      local line = ctx.lines[1]
      local expected = #line - 1
      if ctx.cursor.col == expected then
        return { success = true, message = "Cursor at end of line." }
      end
      return { success = false, message = string.format(
        "Expected col %d, got %d", expected, ctx.cursor.col) }
    end,
  },

  {
    id       = "motion_002",
    category = "basic_motions",
    title    = "Jump to first non-blank",
    difficulty = 1,
    filetype = "text",
    lines    = { "    func main() {" },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: First Non-Blank
─────────────────────
Move the cursor to the first
non-whitespace character.

The line has leading spaces.
Land on the 'f' of 'func'.

Motion: ^
]],
    hint              = "Press '^' for first non-blank char",
    optimal_keystrokes = 1,
    validate = function(ctx)
      if ctx.cursor.col == 4 then
        return { success = true, message = "On first non-blank character." }
      end
      return { success = false, message = string.format(
        "Expected col 4 (the 'f'), got %d", ctx.cursor.col) }
    end,
  },

  {
    id       = "motion_003",
    category = "basic_motions",
    title    = "Jump to last line",
    difficulty = 1,
    filetype = "go",
    lines    = {
      "package main",
      "",
      "import \"fmt\"",
      "",
      "func main() {",
      "    fmt.Println(\"hello\")",
      "}",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Jump to Last Line
───────────────────────
Move to the last line of
the buffer (the closing '}').

Motion: G
]],
    hint              = "Press 'G' to go to the last line",
    optimal_keystrokes = 1,
    validate = function(ctx)
      if ctx.cursor.row == 7 then
        return { success = true, message = "On the last line." }
      end
      return { success = false, message = string.format(
        "Expected row 7, got %d", ctx.cursor.row) }
    end,
  },

  {
    id       = "motion_004",
    category = "basic_motions",
    title    = "Jump to specific line",
    difficulty = 1,
    filetype = "go",
    lines    = {
      "package main",
      "",
      "import \"fmt\"",
      "",
      "func add(a, b int) int {",
      "    return a + b",
      "}",
      "",
      "func main() {",
      "    fmt.Println(add(1, 2))",
      "}",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Jump to Line 9
─────────────────────
Jump directly to line 9
(the 'func main()' line).

Motion: 9G  or  :9<CR>
]],
    hint              = "Use '9G' to jump to line 9",
    optimal_keystrokes = 2,
    validate = function(ctx)
      if ctx.cursor.row == 9 then
        return { success = true, message = "On line 9." }
      end
      return { success = false, message = string.format(
        "Expected row 9, got %d", ctx.cursor.row) }
    end,
  },

  {
    id       = "motion_005",
    category = "basic_motions",
    title    = "Word forward (w)",
    difficulty = 1,
    filetype = "text",
    lines    = { "foo bar baz qux" },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Three Words Forward
──────────────────────────
Move forward three words.
Land on the 'b' of 'baz'.

Cursor starts on 'f' of 'foo'.

Motion: w (or count prefix)
]],
    hint              = "Use '3w' or 'www' to move 3 words",
    optimal_keystrokes = 2,
    validate = function(ctx)
      -- 'baz' starts at col 8
      if ctx.cursor.col == 8 then
        return { success = true, message = "On 'baz'." }
      end
      return { success = false, message = string.format(
        "Expected col 8 ('baz'), got %d", ctx.cursor.col) }
    end,
  },

  {
    id       = "motion_006",
    category = "basic_motions",
    title    = "Find character (f)",
    difficulty = 1,
    filetype = "go",
    lines    = { "    return errors.New(\"invalid input\")" },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Find Character
─────────────────────
Jump to the opening '(' on
this line using f-motion.

Land on the '('.

Motion: f(
]],
    hint              = "Use 'f(' to jump to the next '('",
    optimal_keystrokes = 2,
    validate = function(ctx)
      local line = ctx.lines[1]
      local expected = line:find("%(") - 1  -- 0-indexed
      if ctx.cursor.col == expected then
        return { success = true, message = "On the '('." }
      end
      return { success = false, message = string.format(
        "Expected col %d '(', got %d", expected, ctx.cursor.col) }
    end,
  },

  {
    id       = "motion_007",
    category = "basic_motions",
    title    = "Jump to matching bracket",
    difficulty = 2,
    filetype = "go",
    lines    = {
      "func process(items []string) ([]string, error) {",
      "    result := make([]string, 0, len(items))",
      "    for _, item := range items {",
      "        result = append(result, item)",
      "    }",
      "    return result, nil",
      "}",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Jump to Matching Brace
─────────────────────────────
The cursor is at the opening
'{' of the function body
(end of line 1).

Jump to the matching closing
'}' at line 7.

Hint: first navigate to the
'{', then use % to jump.

Motion: $  then  %
]],
    hint              = "Navigate to '{' with '$', then press '%'",
    optimal_keystrokes = 2,
    validate = function(ctx)
      if ctx.cursor.row == 7 and ctx.cursor.col == 0 then
        return { success = true, message = "On the matching '}'." }
      end
      return { success = false, message = string.format(
        "Expected {row=7, col=0}, got {row=%d, col=%d}",
        ctx.cursor.row, ctx.cursor.col) }
    end,
  },

  {
    id       = "motion_008",
    category = "basic_motions",
    title    = "Paragraph jump",
    difficulty = 2,
    filetype = "text",
    lines    = {
      "First paragraph line one.",
      "First paragraph line two.",
      "First paragraph line three.",
      "",
      "Second paragraph line one.",
      "Second paragraph line two.",
      "",
      "Third paragraph line one.",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Jump to Next Paragraph
─────────────────────────────
Move to the start of the
third paragraph (line 8).

Cursor starts at line 1.

Motion: }}  (two paragraph
           forward jumps)
]],
    hint              = "Use '}' twice to jump paragraphs",
    optimal_keystrokes = 2,
    validate = function(ctx)
      if ctx.cursor.row == 8 then
        return { success = true, message = "On the third paragraph." }
      end
      return { success = false, message = string.format(
        "Expected row 8 (third paragraph), got %d", ctx.cursor.row) }
    end,
  },
}
