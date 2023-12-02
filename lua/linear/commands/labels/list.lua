local Job = require 'plenary.job'
local options = require('linear').options

local ListLabelsCommand = {}
ListLabelsCommand.__index = ListLabelsCommand

function ListLabelsCommand:new(parent_cmd)
  self = setmetatable({}, ListLabelsCommand)
  self.parent_cmd = parent_cmd
  return self;
end

function ListLabelsCommand:run()
  if options.no_api_key() then
    return
  end
  local args = { '-s', 'linear', 'labels', '--api-key', options.api_key, '--json', 'list' }
  Job:new({
    command = 'yarn',
    args = args,
    on_exit = vim.schedule_wrap(function(j, return_val)
      if (return_val == 0) then
        local labels = vim.json.decode(table.concat(j:result(), ""))
        self.parent_cmd:success(labels)
      else
        self.parent_cmd.text = "Failed to fetch labels"
        self.parent_cmd:failed()
      end
    end),
  }):start()
end

return ListLabelsCommand
