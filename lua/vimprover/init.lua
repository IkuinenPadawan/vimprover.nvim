local M = {}

M.vimprover_on = false
M.key_presses = {}

local ns_id = vim.api.nvim_create_namespace("vimprover")

function M.system_prompt()
  return [[You are a Neovim expert and vim motion coach. You receive a JSON object:
  - key_presses: ordered list of keys the user pressed (all modes, including mode-switching keys like i, v, Escape, Enter)
  - diff: a unified diff of the edit they made (empty if no text was changed)

  The user always starts in Normal mode. Interpret each key in the context of the current mode as you trace through the sequence.

  Your task: determine if the key sequence was efficient. If a shorter or cleaner sequence exists, show it.

  Output format (use exactly this structure):
  Original: <sequence>
  Suggested: <sequence>  (or "Already optimal" if nothing to improve)
  Why: <one sentence>

  Before suggesting any sequence, verify each keystroke is strictly necessary: mentally remove it and check whether the remaining keys still produce the same edit from the same starting cursor position. If yes, the keystroke is redundant — omit it. Apply this to every motion, especially positioning steps.

  If the user was already efficient, say so. Do not suggest a change just to have something to say.

  Neovim facts (treat as ground truth):
  - Paired delimiter text objects (di(, ci[, da{) search forward from the cursor for the next opening delimiter if the cursor is not inside one. No pre-positioning needed if cursor is before the delimiter on the same line.
  - Word text objects (diw, caw) operate on the word the cursor is on or adjacent to.
  - Change operators (c, cc, cw, ci() drop into Insert mode automatically — no i keystroke needed after.
  - Counts compose with motions and operators: 3dw deletes 3 words, d3w is equivalent.
  - Dot (.) repeats the last change, including its count and text object.
  - f{char}/F{char} jump to the next/previous occurrence of a character on the line — often replaces multiple w/l motions.
  - After an operator, you are back in Normal mode. After c-family operators, you are in Insert mode.
  - Never hedge these behaviors with "may work" or "worth testing". State the correct keystrokes with confidence.]]
end

function M.log_key_presses(key, typed)
  if M.vimprover_on then
    print(vim.fn.keytrans(typed))
    if vim.fn.keytrans(typed) then
      table.insert(M.key_presses, vim.fn.keytrans(typed))
    end
  end
end

function M.write_to_file(filename, text)
  local file = io.open(filename, "w")
  file:write(text)
  file:close()
end

function M.get_diff()
  local handle = io.popen("diff " .. "before" .. " " .. "after")
  local result = handle:read("*a")
  handle:close()
  return result
end

function M.assemble_prompt(key_presses, diff)
  local prompt = { key_presses = key_presses, diff = diff, }

  local json = vim.json.encode(prompt)
  return json
end

function M.send_prompt(prompt)
  local result = vim.system({"claude", "--system-prompt", M.system_prompt(), "-p", prompt},
                            {},
                            function(out)
                              vim.schedule(function()
                                vim.notify(out.stdout)
                              end)
                            end)
end

function M.toggle_vimprover()
  if M.vimprover_on then
    M.vimprover_on = false
    vim.on_key(nil, ns_id)
    M.write_to_file("after", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
    local diff = M.get_diff()
    M.send_prompt(M.assemble_prompt(M.key_presses, diff))
  else
    M.vimprover_on = true
    M.write_to_file("before", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
    M.key_presses = {}
    vim.on_key(M.log_key_presses, ns_id)
  end
end

M.setup = function(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command("Vimprover", M.toggle_vimprover, {})

  local keymap = opts.keymap or '<leader>b'

  vim.keymap.set('n', keymap, M.toggle_vimprover, {
    desc = "Toggle vimprover on/off",
    silent = true
  })
end

return M
