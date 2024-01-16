local Job = require 'plenary.job'
local options = require('linear').options

local ListPrioritiesCommand = {}
ListPrioritiesCommand.__index = ListPrioritiesCommand

function ListPrioritiesCommand:new(parent_cmd)
  self = setmetatable({}, ListPrioritiesCommand)
  self.parent_cmd = parent_cmd
  return self;
end

function ListPrioritiesCommand:run()
  if options.no_api_key() then
    return
  end
  local args = { '-s', 'linear', 'priorities', '--api-key', options.api_key, '--json', 'list' }
  Job:new({
    cwd = options.cwd,
    command = 'yarn',
    args = args,
    on_exit = vim.schedule_wrap(function(j, return_val)
      if (return_val == 0) then
        local priorities = vim.json.decode(table.concat(j:result(), ""))
        self.parent_cmd:success(priorities)
      else
        self.parent_cmd.text = "Failed to fetch priorities"
        self.parent_cmd:failed()
      end
    end),
  }):start()
end

return ListPrioritiesCommand
