-- Register katas: named registers, yank register, black hole, clipboard.
return {
  {
    id       = "reg_001",
    category = "registers",
    title    = "Yank to named register",
    difficulty = 2,
    filetype = "go",
    lines    = {
      "// Template A",
      'return fmt.Errorf("operation failed: %w", err)',
      "",
      "// Template B",
      'return fmt.Errorf("validation error: %w", err)',
      "",
      "func processA() error {",
      "    err := doA()",
      "    if err != nil {",
      "        REPLACE_A",
      "    }",
      "}",
      "",
      "func processB() error {",
      "    err := doB()",
      "    if err != nil {",
      "        REPLACE_B",
      "    }",
      "}",
    },
    cursor   = { row = 2, col = 0 },
    instructions = [[
KATA: Use Named Registers
──────────────────────────
Yank line 2 into register 'a'.
Yank line 5 into register 'b'.

Then replace:
- REPLACE_A with register 'a'
- REPLACE_B with register 'b'

Steps:
1. "ayy        (yank line 2 → 'a')
2. 5G  "byy    (yank line 5 → 'b')
3. 10G  "ap    (paste 'a' below line 9)
4. dd          (delete REPLACE_A line)
5. 17G  "bp    (paste 'b')
6. dd          (delete REPLACE_B line)

Or use ciw/"ap style — many ways!
]],
    hint              = '"ayy to yank to register a, "ap to paste from it',
    optimal_keystrokes = 20,
    validate = function(ctx)
      local found_a = false
      local found_b = false
      for _, line in ipairs(ctx.lines) do
        if line:match('fmt%.Errorf%("operation failed') then found_a = true end
        if line:match('fmt%.Errorf%("validation error') then found_b = true end
      end
      -- REPLACE markers must be gone
      for i, line in ipairs(ctx.lines) do
        if line:match("REPLACE_") then
          return { success = false, message = string.format(
            "Line %d still has REPLACE marker: [%s]", i, line) }
        end
      end
      if found_a and found_b then
        return { success = true, message = "Both templates pasted correctly." }
      end
      return { success = false, message = string.format(
        "Missing templates: found_a=%s found_b=%s",
        tostring(found_a), tostring(found_b)) }
    end,
  },

  {
    id       = "reg_002",
    category = "registers",
    title    = "Paste from yank register (\"0p)",
    difficulty = 3,
    filetype = "go",
    lines    = {
      '    return errors.New("not found")',
      "",
      "func handleMissing() error {",
      "    log.Println(\"item missing\")",
      "    PASTE_HERE",
      "}",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Paste from Yank Register
────────────────────────────────
The problem: you yank line 1,
navigate to line 5, delete the
PASTE_HERE placeholder — which
overwrites the default register.

But "0 always holds the last
YANKED text (not deleted text).

Steps:
1. yy          (yank line 1)
2. 5G          (go to PASTE_HERE)
3. dd          (delete placeholder — changes "")
4. "0P         (paste from yank register above)

Expected line 5:
    return errors.New("not found")
]],
    hint              = '"0p pastes from yank register, ignoring deletes',
    optimal_keystrokes = 7,
    validate = function(ctx)
      local target = '    return errors.New("not found")'
      for _, line in ipairs(ctx.lines) do
        if line == target then
          return { success = true, message = "Yank register paste correct." }
        end
      end
      -- Check PASTE_HERE is gone
      for i, line in ipairs(ctx.lines) do
        if line:match("PASTE_HERE") then
          return { success = false, message = string.format(
            "PASTE_HERE on line %d not replaced", i) }
        end
      end
      return { success = false, message = "Expected return line not found in buffer." }
    end,
  },

  {
    id       = "reg_003",
    category = "registers",
    title    = "Black hole register (\"_d)",
    difficulty = 2,
    filetype = "go",
    lines    = {
      "func buildQuery(filters []string) string {",
      "    // debug: dump filters",
      "    fmt.Println(filters)",
      "    query := strings.Join(filters, \" AND \")",
      "    return query",
      "}",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Delete Without Yanking
──────────────────────────────
Delete lines 2-3 (the debug
output) WITHOUT affecting the
default register.

Then paste something from
register 0 to verify it's intact.
(You don't need to paste here —
just delete cleanly.)

Expected:
func buildQuery(filters []string) string {
    query := strings.Join(...)
    return query
}

Use "_ register to delete:
"_2dd  (while on line 2)
]],
    hint              = '"_dd deletes to the black hole (no yank)',
    optimal_keystrokes = 5,
    validate = function(ctx)
      if #ctx.lines ~= 4 then
        return { success = false, message = string.format(
          "Expected 4 lines, got %d", #ctx.lines) }
      end
      for i, line in ipairs(ctx.lines) do
        if line:match("debug") or line:match("fmt%.Println") then
          return { success = false, message = string.format(
            "Line %d still has debug output: [%s]", i, line) }
        end
      end
      return { success = true, message = "Debug lines cleanly deleted." }
    end,
  },

  {
    id       = "reg_004",
    category = "registers",
    title    = "Append to named register",
    difficulty = 4,
    filetype = "go",
    lines    = {
      "    host := cfg.Host",
      "    port := cfg.Port",
      "    timeout := cfg.Timeout",
      "",
      "func buildAddr() string {",
      "    PASTE_CONFIG_LINES",
      '    return fmt.Sprintf("%s:%d", host, port)',
      "}",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Collect Lines into Register
──────────────────────────────────
Collect lines 1, 2, and 3 into
register 'c' (appending each).

Then paste into the function.

Steps:
1. "cyy   (yank line 1 into 'c')
2. j"Cyy  (APPEND line 2 to 'C')
3. j"Cyy  (APPEND line 3 to 'C')
4. 6G     (go to PASTE line)
5. "cp    (paste all three lines)
6. dd     (delete placeholder)

Capital letter appends to register.
]],
    hint              = '"cyy starts, "Cyy appends to register c',
    optimal_keystrokes = 14,
    validate = function(ctx)
      -- Lines 1-3 content should appear inside the function
      local has_host = false
      local has_port = false
      local has_timeout = false
      for _, line in ipairs(ctx.lines) do
        if line:match("host := cfg%.Host") then has_host = true end
        if line:match("port := cfg%.Port") then has_port = true end
        if line:match("timeout := cfg%.Timeout") then has_timeout = true end
      end
      for i, line in ipairs(ctx.lines) do
        if line:match("PASTE_CONFIG") then
          return { success = false, message = string.format(
            "Line %d still has placeholder", i) }
        end
      end
      if has_host and has_port and has_timeout then
        return { success = true, message = "All config lines pasted." }
      end
      return { success = false, message = string.format(
        "Missing lines: host=%s port=%s timeout=%s",
        tostring(has_host), tostring(has_port), tostring(has_timeout)) }
    end,
  },

  {
    id       = "reg_005",
    category = "registers",
    title    = "Expression register (\"=)",
    difficulty = 4,
    filetype = "go",
    lines    = {
      "const MaxWorkers = COMPUTE",
      "const BufferSize = COMPUTE",
    },
    cursor   = { row = 1, col = 0 },
    instructions = [[
KATA: Expression Register
──────────────────────────
Replace both 'COMPUTE' placeholders
with the result of an expression.

Line 1: MaxWorkers should be 2*4 = 8
Line 2: BufferSize should be 1024*4 = 4096

Use the expression register:
"= to insert a computed value.

In insert mode: <C-r>=2*4<CR>

Steps:
1. Navigate to 'COMPUTE' on line 1
2. ciw then <C-r>=2*4<CR>
3. Navigate to 'COMPUTE' on line 2
4. ciw then <C-r>=1024*4<CR>

Expected:
const MaxWorkers = 8
const BufferSize = 4096
]],
    hint              = "In insert mode, <C-r>= inserts expression result",
    optimal_keystrokes = 24,
    validate = function(ctx)
      if ctx.lines[1] ~= "const MaxWorkers = 8" then
        return { success = false, message = string.format(
          "Line 1: expected [const MaxWorkers = 8], got [%s]", ctx.lines[1] or "") }
      end
      if ctx.lines[2] ~= "const BufferSize = 4096" then
        return { success = false, message = string.format(
          "Line 2: expected [const BufferSize = 4096], got [%s]", ctx.lines[2] or "") }
      end
      return { success = true, message = "Expression register used correctly." }
    end,
  },
}
