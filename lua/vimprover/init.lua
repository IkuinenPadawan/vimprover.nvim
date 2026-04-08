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

function M.write_to_file(filename, text)
  local file = io.open(filename, "w")
  file:write(text)
  file:close()
end

function M.send_prompt()
  local result = vim.system({"claude", "-p", "Hi claude"},
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
    vim.print(M.key_presses)
    M.write_to_file("after", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
--    M.send_prompt()
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
