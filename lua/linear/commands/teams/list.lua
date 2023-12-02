local Job = require 'plenary.job'
local options = require('linear').options

local ListTeamsCommand = {}
ListTeamsCommand.__index = ListTeamsCommand

function ListTeamsCommand:new(parent_cmd)
  self = setmetatable({}, ListTeamsCommand)
  self.parent_cmd = parent_cmd
  return self;
end

function ListTeamsCommand:run()
  if options.no_api_key() then
    return
  end
  local args = { '-s', 'linear', 'teams', '--api-key', options.api_key, '--json', 'list' }
  Job:new({
    command = 'yarn',
    args = args,
    on_exit = vim.schedule_wrap(function(j, return_val)
      if (return_val == 0) then
        local teams = vim.json.decode(table.concat(j:result(), ""))
        self.parent_cmd:success(teams)
      else
        self.parent_cmd.text = "Failed to fetch teams"
        self.parent_cmd:failed()
      end
    end),
  }):start()
end

return ListTeamsCommand
