# vim-katas

> **Note:** This plugin was written with the assistance of AI (Claude) and reviewed by the author.

A Neovim plugin for deliberate Vim practice. Work through kata exercises that
test specific motions and editing techniques, with keystroke counting, time
tracking, and star ratings.

## Features

- **56 katas** across 9 categories, difficulty 1–3
- **Keystroke efficiency scoring** — compares your keycount to the optimal
- **Time bonus** for sub-par performance on perfect runs
- **Progress persistence** — JSON stored in `stdpath("data")/vim-katas/`
- **Multi-file katas** — quickfix, `:cfdo`, `:vimgrep` workflows
- **Macro replay tracking** — macro keypresses are not double-counted by default

## Kata Categories

| Category         | Count | Topics |
|-----------------|-------|--------|
| Basic Motions   | 8     | `$`, `^`, `G`, `f`, `%`, `{}`/`}` |
| Text Objects    | 8     | `iw/aw`, `i"/a"`, `i(/a(`, `i{`, `it`, `ip` |
| Operators       | 10    | `D`, `C`, `J`, `.`, `gU`, `3dd`, `>` |
| Visual Mode     | 6     | `V>`, `<C-v>I`, block delete, `gv` |
| Search & Replace| 8     | `:%s`, `:g/d`, `cgn`, `:g/norm`, ranges |
| Macros          | 5     | record/replay, `@@`, recursive macros |
| Marks           | 4     | `ma`/`'a`, `` `a ``, `` `. ``, range yank |
| Registers       | 5     | `"ay`, `"0p`, `"_d`, append (`"A`), `<C-r>=` |
| Quickfix        | 4     | `:vimgrep`, `:cfdo`, `:cdo`, location list |

## Installation

### lazy.nvim

```lua
{
  "davyj0nes/vim-katas",
  cmd = { "VimKata", "VimKataMenu", "VimKataStats" },
  keys = {
    { "<leader>km", "<cmd>VimKataMenu<cr>", desc = "Kata Menu" },
  },
  opts = {},
  config = function(_, opts)
    require("vim_katas").setup(opts)
  end,
}
```

### packer.nvim

```lua
use {
  "davyj0nes/vim-katas",
  config = function()
    require("vim_katas").setup()
  end,
}
```

## Commands

| Command | Description |
|---------|-------------|
| `:VimKataMenu` | Open the interactive kata browser |
| `:VimKata [id]` | Start a specific kata by id (tab-completable) |
| `:VimKataStats` | View progress across all katas |

## Default Keymaps

Set during an active kata (buffer-local):

| Key | Action |
|-----|--------|
| `<leader>ks` | Submit the kata for scoring |
| `<leader>kh` | Reveal hint (caps score at ★★) |
| `<leader>kq` | Quit kata |
| `<leader>km` | Open kata menu (global) |

## Configuration

```lua
require("vim_katas").setup({
  -- Directory for progress JSON file
  data_dir = vim.fn.stdpath("data") .. "/vim-katas",

  -- Width of the instructions panel (columns)
  panel_width = 42,

  -- Status refresh interval in milliseconds
  timer_interval_ms = 250,

  -- Count keystrokes replayed during macro execution individually.
  -- false = macro invocation (@q) counts as 1 keystroke (recommended)
  count_macro_keys = false,

  -- Keybindings (set to false to disable)
  keymaps = {
    submit = "<leader>ks",
    hint   = "<leader>kh",
    quit   = "<leader>kq",
    menu   = "<leader>km",
  },
})
```

## Scoring

Stars are awarded based on keystroke efficiency:

| Ratio (optimal / actual) | Stars |
|--------------------------|-------|
| ≥ 100%                   | ★★★   |
| ≥ 75%                    | ★★    |
| ≥ 50%                    | ★     |
| < 50% or failed          | ☆☆☆  |

A time bonus 🏆 is available for ★★★ runs completed significantly faster
than par (difficulty × optimal keystrokes × time constant).

Using the hint caps the score at ★★.

## Layout

```
┌────────────────────────────────────┬──────────────────────────┐
│                                    │  VIM KATAS               │
│  Practice Buffer                   │  Change inside quotes    │
│  (editable, full vim support)      │  ★★☆  [text_objects]    │
│                                    │                           │
│  msg := "old message"              │  Replace content inside  │
│                                    │  the double quotes with: │
│                                    │  new message             │
│                                    │                           │
│                                    │  Keys: 7    Optimal: 14  │
│                                    │  Time: 0:08              │
│                                    │                           │
│                                    │  <leader>ks  submit      │
│                                    │  <leader>kh  hint        │
│                                    │  <leader>kq  quit        │
└────────────────────────────────────┴──────────────────────────┘
```

## Progress Data

Stored at `~/.local/share/nvim/vim-katas/progress.json`. The last 20
attempts per kata are retained. Fields: `best_stars`, `best_keycount`,
`best_time`, `attempts`, `last_played`.
