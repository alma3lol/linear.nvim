local Job = require 'plenary.job'
local options = require('linear').options

local ListUsersCommand = {}
ListUsersCommand.__index = ListUsersCommand

function ListUsersCommand:new(parent_cmd)
  self = setmetatable({}, ListUsersCommand)
  self.parent_cmd = parent_cmd
  return self;
end

function ListUsersCommand:run()
  if options.no_api_key() then
    return
  end
  local args = { '-s', 'linear', 'users', '--api-key', options.api_key, '--json', 'list' }
  Job:new({
    command = 'yarn',
    args = args,
    on_exit = vim.schedule_wrap(function(j, return_val)
      if (return_val == 0) then
        local users = vim.json.decode(table.concat(j:result(), ""))
        self.parent_cmd:success(users)
      else
        self.parent_cmd.text = "Failed to fetch users"
        self.parent_cmd:failed()
      end
    end),
  }):start()
end

return ListUsersCommand
