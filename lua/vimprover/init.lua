local M = {}

M.vimprover_on = false
M.key_presses = {}

local ns_id = vim.api.nvim_create_namespace("vimprover")

function M.log_key_presses(key, typed)
  if M.vimprover_on then
    print(vim.fn.keytrans(typed))
    if vim.fn.keytrans(typed) then
      table.insert(M.key_presses, vim.fn.keytrans(typed))
    end
  end
end

function M.toggle_vimprover()
  if M.vimprover_on then
    M.vimprover_on = false
    vim.print(M.key_presses)
  else
    M.vimprover_on = true
    M.key_presses = {}
    vim.on_key(M.log_key_presses)
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
