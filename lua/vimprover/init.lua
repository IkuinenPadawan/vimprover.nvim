
local M = {}

M.vimprover_on = false
M.key_presses = {}

local ns_id = vim.api.nvim_create_namespace("vimprover")

local defaults = {
  toggle = '<leader>b',
  system_prompt = require("vimprover.prompt"),
  extra_instructions = nil

}

local config = {}

M.setup = function(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})

  vim.api.nvim_create_user_command("Vimprover", M.toggle_vimprover, {})

  vim.keymap.set('n', config.toggle, M.toggle_vimprover, {
    desc = "Toggle vimprover on/off",
    silent = true
  })


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
  local system_prompt = config.system_prompt .. (config.extra_instructions and "\n" .. config.extra_instructions or "")
  local in_progress = true
  local result = vim.system({"claude", "--system-prompt", system_prompt, "-p", prompt},
                            {},
                            function(out)
                              vim.schedule(function()
                                in_progress = false
                                vim.notify(out.stdout)
                              end)
                            end)
  local statuses = {"Vimcoach Ruminating", "Vimcoach Ruminating.", "Vimcoach Ruminating..", "Vimcoach Ruminating..."}
  local timer = vim.uv.new_timer()
  local i = 1
    timer:start(1000, 500, vim.schedule_wrap(function(moi)
      if in_progress == false then
        timer:stop()
        if not timer:is_closing() then
          timer:close()
        end
      else
        vim.notify(statuses[i])
      if i < 4 then
        i = i + 1
      else
        i = 1
      end
    end
  end))
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

return M
