local Job = require 'plenary.job'
local options = require('linear').options

local ListStatesCommand = {}
ListStatesCommand.__index = ListStatesCommand

function ListStatesCommand:new(parent_cmd)
  self = setmetatable({}, ListStatesCommand)
  self.parent_cmd = parent_cmd
  return self;
end

function ListStatesCommand:run()
  if options.no_api_key() then
    return
  end
  local args = { '-s', 'linear', 'states', '--api-key', options.api_key, '--json', 'list' }
  if options.filters and options.filters.states then
    if options.filters.states.types then
      local stateTypesToFilterWith = {}
      for key, value in pairs(options.filters.states.types) do
        if value == true then
          table.insert(stateTypesToFilterWith, key)
        end
      end
      if #stateTypesToFilterWith > 0 then
        table.insert(args, "-T")
        table.insert(args, table.concat(stateTypesToFilterWith, ","))
      end
    end
  end
  Job:new({
    command = 'yarn',
    args = args,
    on_exit = vim.schedule_wrap(function(j, return_val)
      if (return_val == 0) then
        local states = vim.json.decode(table.concat(j:result(), ""))
        self.parent_cmd:success(states)
      else
        self.parent_cmd.text = "Failed to fetch issues"
        self.parent_cmd:failed()
      end
    end),
  }):start()
end

return ListStatesCommand
