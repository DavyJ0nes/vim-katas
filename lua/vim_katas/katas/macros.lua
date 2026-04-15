-- Macro katas: recording and replaying macros for repetitive edits.
return {
  {
    id       = "macro_001",
    category = "macros",
    title    = "Record and replay a macro",
    difficulty = 3,
    filetype = "go",
    lines    = {
      "GetUser",
      "GetProduct",
      "GetOrder",
      "GetSession",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Wrap Each in a Function
──────────────────────────────
Each line is a function name.
Transform all of them to:

func GetUser() {}
func GetProduct() {}
func GetOrder() {}
func GetSession() {}

Record a macro on line 1, then
replay it on lines 2-4.

Steps:
1. qq             (record into 'q')
2. Ifunc <Esc>    (insert 'func ')
3. A() {}<Esc>   (append '() {}')
4. j              (move down)
5. q              (stop recording)
6. 3@q            (replay 3 times)
]],
    hint              = "qq records, @q replays, 3@q replays 3 times",
    optimal_keystrokes = 15,
    validate = function(ctx)
      local expected = {
        "func GetUser() {}",
        "func GetProduct() {}",
        "func GetOrder() {}",
        "func GetSession() {}",
      }
      for i, line in ipairs(expected) do
        if ctx.lines[i] ~= line then
          return { success = false, message = string.format(
            "Line %d: expected [%s], got [%s]", i, line, ctx.lines[i] or "") }
        end
      end
      return { success = true, message = "All lines transformed correctly." }
    end,
  },

  {
    id       = "macro_002",
    category = "macros",
    title    = "Macro on numbered list",
    difficulty = 3,
    filetype = "markdown",
    lines    = {
      "- First item",
      "- Second item",
      "- Third item",
      "- Fourth item",
      "- Fifth item",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Convert to Numbered List
────────────────────────────────
Convert the bullet list to a
numbered list:

1. First item
2. Second item
3. Third item
4. Fourth item
5. Fifth item

Approach: record a macro that
replaces '- ' with the next
number, then use counts.

Simplest approach:
:%s/^- /  then use a counter
OR record macro with qn, then
replay with @n counts.

Hint: easiest is just a global sub
with line numbers. Try:
:let i=1 | g/^- /s//\=i.'. '/|let i+=1
]],
    hint              = ":let i=1 | g/^- /s//\\=i.'. '/|let i+=1",
    optimal_keystrokes = 38,
    validate = function(ctx)
      local expected = {
        "1. First item",
        "2. Second item",
        "3. Third item",
        "4. Fourth item",
        "5. Fifth item",
      }
      for i, line in ipairs(expected) do
        if ctx.lines[i] ~= line then
          return { success = false, message = string.format(
            "Line %d: expected [%s], got [%s]", i, line, ctx.lines[i] or "") }
        end
      end
      return { success = true, message = "List numbered correctly." }
    end,
  },

  {
    id       = "macro_003",
    category = "macros",
    title    = "Macro with search and replace",
    difficulty = 4,
    filetype = "go",
    lines    = {
      'if err := doA(); err != nil { return err }',
      'if err := doB(); err != nil { return err }',
      'if err := doC(); err != nil { return err }',
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Expand Inline Error Checks
──────────────────────────────────
Expand each single-line error check
into its multi-line form:

if err := doA(); err != nil {
    return err
}

Record a macro that:
1. Finds the '{'
2. Replaces '{ return err }' with
   the multiline form

This is a complex macro —
use: f{ci{<CR>    return err<CR><Esc>

Then replay on remaining lines.
]],
    hint              = "f{ci{ then type multiline body, then j@q",
    optimal_keystrokes = 22,
    validate = function(ctx)
      -- Each original line should expand to 3 lines
      if #ctx.lines ~= 9 then
        return { success = false, message = string.format(
          "Expected 9 lines (3x expanded), got %d", #ctx.lines) }
      end
      for i = 0, 2 do
        local base = i * 3 + 1
        local open = ctx.lines[base]
        local body = ctx.lines[base + 1]
        local close = ctx.lines[base + 2]
        if not open or not open:match("if err") then
          return { success = false, message = string.format(
            "Line %d doesn't start if-block: [%s]", base, open or "") }
        end
        if not body or not body:match("return err") then
          return { success = false, message = string.format(
            "Line %d missing 'return err': [%s]", base + 1, body or "") }
        end
        if not close or not close:match("^}") then
          return { success = false, message = string.format(
            "Line %d missing closing '}': [%s]", base + 2, close or "") }
        end
      end
      return { success = true, message = "All error checks expanded." }
    end,
  },

  {
    id       = "macro_004",
    category = "macros",
    title    = "Apply macro to visual selection",
    difficulty = 4,
    filetype = "go",
    lines    = {
      'const A = "alpha"',
      'const B = "beta"',
      'const C = "gamma"',
      "",
      '// do not modify below',
      'const D = "delta"',
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Macro on Selected Lines
──────────────────────────────
Uppercase the string value in
only the first THREE const lines.

Expected:
const A = "ALPHA"
const B = "BETA"
const C = "GAMMA"

// do not modify below
const D = "delta"  ← unchanged

Record macro: gU inside quotes
Then apply with count.

Motion: qq ci" gU<prev_text> q  3@q
        OR: qqgUi"jq  3@q
]],
    hint              = "qqgUi\"jq records, then 3@q applies to first 3",
    optimal_keystrokes = 11,
    validate = function(ctx)
      local expected_upper = { '"ALPHA"', '"BETA"', '"GAMMA"' }
      for i, pat in ipairs(expected_upper) do
        if not ctx.lines[i] or not ctx.lines[i]:find(pat, 1, true) then
          return { success = false, message = string.format(
            "Line %d: expected uppercase value %s, got [%s]",
            i, pat, ctx.lines[i] or "") }
        end
      end
      -- line 6 must still be lowercase
      if ctx.lines[6] and ctx.lines[6]:find('"delta"', 1, true) then
        return { success = true, message = "Correct — line 6 unchanged." }
      end
      return { success = false, message = string.format(
        "Line 6 was unexpectedly modified: [%s]", ctx.lines[6] or "") }
    end,
  },

  {
    id       = "macro_005",
    category = "macros",
    title    = "Recursive macro",
    difficulty = 5,
    filetype = "text",
    lines    = {
      "item",
      "item",
      "item",
      "item",
      "item",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Recursive Macro
──────────────────────
Use a recursive macro to add
sequential numbers to each line:

1 item
2 item
3 item
4 item
5 item

A recursive macro calls itself:
qq  I<C-r>=line('.')<CR>  <Esc>  j  @q  q

Then start it: @q

The macro stops when it hits
the end of the buffer.
]],
    hint              = "Recursive macro: qq I<C-r>=line('.')<CR> <Esc> j @q q",
    optimal_keystrokes = 13,
    validate = function(ctx)
      for i = 1, 5 do
        local expected = i .. " item"
        if ctx.lines[i] ~= expected then
          return { success = false, message = string.format(
            "Line %d: expected [%s], got [%s]", i, expected, ctx.lines[i] or "") }
        end
      end
      return { success = true, message = "Lines numbered correctly." }
    end,
  },
}
