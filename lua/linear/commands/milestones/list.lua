local Job = require 'plenary.job'
local options = require('linear').options

local ListMilestonesCommand = {}
ListMilestonesCommand.__index = ListMilestonesCommand

function ListMilestonesCommand:new(parent_cmd)
  self = setmetatable({}, ListMilestonesCommand)
  self.parent_cmd = parent_cmd
  return self;
end

function ListMilestonesCommand:run()
  if options.no_api_key() then
    return
  end
  local args = { '-s', 'linear', 'milestones', '--api-key', options.api_key, '--json', 'list' }
  if self.parent_cmd.args.filtering_entry ~= nil then
    table.insert(args, "-p")
    table.insert(args, self.parent_cmd.args.filtering_entry.id)
  end
  Job:new({
    command = 'yarn',
    args = args,
    on_exit = vim.schedule_wrap(function(j, return_val)
      if (return_val == 0) then
        local milestones = vim.json.decode(table.concat(j:result(), ""))
        self.parent_cmd:success(milestones)
      else
        self.parent_cmd.text = "Failed to fetch milestones"
        self.parent_cmd:failed()
      end
    end),
  }):start()
end

return ListMilestonesCommand
