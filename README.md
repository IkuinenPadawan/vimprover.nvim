# vimprover.nvim

An AI-powered Neovim motion coach. Record what you type, then get feedback on whether you could have done it faster.

## How it works

1. Toggle vimprover on before making an edit
2. Make your edit however you naturally would
3. Toggle it off — vimprover captures your keystrokes and the diff, sends them to Claude, and notifies you with a suggestion

```
Original: 19l a someparam <Esc>
Suggested: ci(someparam<Esc>
Why: The 19 l presses were dead weight — ci( scans forward to the nearest ( on the line and drops you into Insert mode inside it from any column, including column 0.
Remember: ci( — change inner parens, no pre-positioning needed
```

If you nailed it, it says so.

## Requirements

- Neovim
- [Claude CLI](https://github.com/anthropics/claude-code) (`claude` available in `$PATH`) with an active Claude subscription

> **Note:** This is an MVP. Feedback takes a few seconds since it shells out to the Claude CLI, expect a short wait after toggling off.

## Installation

### lazy.nvim

```lua
{
  "IkuinenPadawan/vimprover.nvim",
  config = function()
    require("vimprover").setup()
  end
}
```

## Configuration

```lua
require("vimprover").setup({
  toggle = "<leader>vp",         -- default: <leader>vp
  system_prompt = "...",         -- replace the default prompt entirely
  extra_instructions = "...",    -- append to the default prompt
})
```

## Usage

| Key            | Action                        |
|----------------|-------------------------------|
| `<leader>vp`   | Toggle vimprover on/off       |
| `:Vimprover`   | Same, via command             |

**Typical workflow:**

- Position your cursor, hit `<leader>vp` to start recording
- Make your edit
- Hit `<leader>vp` again, feedback appears as a notification

## What it catches

- Redundant positioning motions before text objects
- `w`/`l` spam where `f{char}` or a text object would do
- Unnecessary mode switches
- Missing dot-repeat opportunities
- Over-specified counts

## Planned

- Direct API support — send prompts to any OpenAI-compatible endpoint (local models via Ollama, cloud providers) instead of requiring the Claude CLI
- Session tracker — persist every coaching result locally and show a `:VimproverStats` report showing which idioms you miss most and how your optimality rate trends over time

## License

MIT
