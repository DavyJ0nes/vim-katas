-- Text object katas: validate buffer content after the edit.
return {
  {
    id       = "tobj_001",
    category = "text_objects",
    title    = "Delete inner word (diw)",
    difficulty = 2,
    filetype = "go",
    lines    = { 'fmt.Println("hello world")' },
    cursor   = { row = 1, col = 14 },  -- on 'hello'
    instructions = [[
KATA: Delete Inner Word
────────────────────────
Delete the word 'hello' from
inside the string, leaving the
space and 'world' intact.

Cursor is on 'h' of 'hello'.

Motion: diw
]],
    hint              = "'diw' deletes the word under cursor",
    optimal_keystrokes = 3,
    validate = function(ctx)
      local expected = 'fmt.Println(" world")'
      if ctx.lines[1] == expected then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        'Expected: %s\nGot:      %s', expected, ctx.lines[1]) }
    end,
  },

  {
    id       = "tobj_002",
    category = "text_objects",
    title    = "Change inside quotes (ci\")",
    difficulty = 2,
    filetype = "go",
    lines    = { '    msg := "old message"' },
    cursor   = { row = 1, col = 11 },  -- inside the string
    instructions = [[
KATA: Change Inside Quotes
───────────────────────────
Replace the content inside the
double quotes with: new message

Do NOT change the quotes
themselves.

Expected result:
    msg := "new message"

Motion: ci"  then type replacement
]],
    hint              = 'Use ci" to change inside double quotes',
    optimal_keystrokes = 14,
    validate = function(ctx)
      local expected = '    msg := "new message"'
      if ctx.lines[1] == expected then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        'Expected: [%s]\nGot:      [%s]', expected, ctx.lines[1]) }
    end,
  },

  {
    id       = "tobj_003",
    category = "text_objects",
    title    = "Delete around parentheses (da()",
    difficulty = 2,
    filetype = "go",
    lines    = { "result := compute(x, y, z)" },
    cursor   = { row = 1, col = 19 },  -- inside parens, on 'x'
    instructions = [[
KATA: Delete Around Parens
───────────────────────────
Delete the entire argument list
INCLUDING the parentheses.

Expected result:
result := compute

Motion: da(
]],
    hint              = "'da(' deletes the parens and their contents",
    optimal_keystrokes = 3,
    validate = function(ctx)
      local expected = "result := compute"
      if ctx.lines[1] == expected then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        'Expected: [%s]\nGot:      [%s]', expected, ctx.lines[1]) }
    end,
  },

  {
    id       = "tobj_004",
    category = "text_objects",
    title    = "Change inside braces (ci{)",
    difficulty = 2,
    filetype = "json",
    lines    = {
      "{",
      '  "key": "value"',
      "}",
    },
    cursor   = { row = 2, col = 2 },
    instructions = [[
KATA: Change Inside Braces
───────────────────────────
Replace everything inside the
outer braces with just:
  "name": "world"

Expected result:
{
  "name": "world"
}

Position cursor inside the
braces, then: ci{
]],
    hint              = "'ci{' changes everything inside the braces",
    optimal_keystrokes = 18,
    validate = function(ctx)
      local expected = { "{", '  "name": "world"', "}" }
      for i, line in ipairs(expected) do
        if ctx.lines[i] ~= line then
          return { success = false, message = string.format(
            'Line %d: expected [%s], got [%s]', i, line, ctx.lines[i] or "") }
        end
      end
      return { success = true, message = "Correct." }
    end,
  },

  {
    id       = "tobj_005",
    category = "text_objects",
    title    = "Yank inner paragraph (yip)",
    difficulty = 3,
    filetype = "text",
    lines    = {
      "First paragraph.",
      "Still first paragraph.",
      "",
      "Second paragraph here.",
      "Still second paragraph.",
    },
    cursor   = { row = 4, col = 0 },
    instructions = [[
KATA: Yank Inner Paragraph
───────────────────────────
Yank (copy) the second
paragraph (lines 4-5).

Then paste it BELOW the
current position (line 5).

Expected: the two lines are
duplicated after line 5.

Motion: yip  then  p
]],
    hint              = "'yip' yanks the paragraph, 'p' pastes below",
    optimal_keystrokes = 4,
    validate = function(ctx)
      local expected = {
        "First paragraph.",
        "Still first paragraph.",
        "",
        "Second paragraph here.",
        "Still second paragraph.",
        "",
        "Second paragraph here.",
        "Still second paragraph.",
      }
      if #ctx.lines ~= #expected then
        return { success = false, message = string.format(
          "Expected %d lines, got %d", #expected, #ctx.lines) }
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
    id       = "tobj_006",
    category = "text_objects",
    title    = "Delete inside braces (di{)",
    difficulty = 2,
    filetype = "go",
    lines    = { 'allowed := []string{"read", "write", "exec"}' },
    cursor   = { row = 1, col = 22 },  -- inside the {}, on '"'
    instructions = [[
KATA: Delete Inside Braces
───────────────────────────
Delete the contents of the
string slice literal, leaving
the braces empty.

Cursor is inside the {}.

Expected:
allowed := []string{}

Motion: di{
]],
    hint              = "Use 'di{' with cursor inside the braces",
    optimal_keystrokes = 3,
    validate = function(ctx)
      local expected = 'allowed := []string{}'
      if ctx.lines[1] == expected then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        'Expected: [%s]\nGot:      [%s]', expected, ctx.lines[1]) }
    end,
  },

  {
    id       = "tobj_007",
    category = "text_objects",
    title    = "Change around word (caw)",
    difficulty = 2,
    filetype = "go",
    lines    = { "var isEnabled bool = true" },
    cursor   = { row = 1, col = 12 },  -- on 'bool'... wait let me recalculate
    -- "var isEnabled bool = true"
    --  0123456789012345
    -- 'b' of bool is at col 14
    cursor   = { row = 1, col = 14 },
    instructions = [[
KATA: Change Around Word
─────────────────────────
Replace 'bool' (and its trailing
space) with 'string '.

Cursor is on the 'b' of 'bool'.

Expected:
var isEnabled string = true

Motion: caw  then type 'string'
]],
    hint              = "'caw' changes the word including surrounding space",
    optimal_keystrokes = 9,
    validate = function(ctx)
      local expected = "var isEnabled string = true"
      if ctx.lines[1] == expected then
        return { success = true, message = "Correct." }
      end
      return { success = false, message = string.format(
        'Expected: [%s]\nGot:      [%s]', expected, ctx.lines[1]) }
    end,
  },

  {
    id       = "tobj_008",
    category = "text_objects",
    title    = "Delete inside tag (dit)",
    difficulty = 3,
    filetype = "html",
    lines    = {
      "<div>",
      "  <p>Hello, World!</p>",
      "</div>",
    },
    cursor   = { row = 2, col = 5 },  -- inside <p>...</p>
    instructions = [[
KATA: Delete Inside Tag
────────────────────────
Delete the text content inside
the <p> tag, leaving the tags.

Expected result:
<div>
  <p></p>
</div>

Motion: dit  (cursor inside <p>)
]],
    hint              = "'dit' deletes content inside HTML/XML tag",
    optimal_keystrokes = 3,
    validate = function(ctx)
      local expected = {
        "<div>",
        "  <p></p>",
        "</div>",
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
}
