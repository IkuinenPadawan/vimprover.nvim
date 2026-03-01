local M = {}

function M.log_key_presses(key, typed)
  print(vim.fn.keytrans(typed))
end

function M.start_vimprover()
    vim.on_key(M.log_key_presses)
end

M.setup = function(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command("Vimprover", M.start_vimprover, {})

  local keymap = opts.keymap or '<leader>b'

  vim.keymap.set('n', keymap, M.start_vimprover, {
    desc = "Start vimprover",
    silent = true
  })
end

return M
