local Job = require 'plenary.job'
local options = require('linear').options

local ListProjectsCommand = {}
ListProjectsCommand.__index = ListProjectsCommand

function ListProjectsCommand:new(parent_cmd)
  self = setmetatable({}, ListProjectsCommand)
  self.parent_cmd = parent_cmd
  return self;
end

function ListProjectsCommand:run()
  if options.no_api_key() then
    return
  end
  local args = { '-s', 'linear', 'projects', '--api-key', options.api_key, '--json', 'list' }
  Job:new({
    command = 'yarn',
    args = args,
    on_exit = vim.schedule_wrap(function(j, return_val)
      if (return_val == 0) then
        local projects = vim.json.decode(table.concat(j:result(), ""))
        self.parent_cmd:success(projects)
      else
        self.parent_cmd.text = "Failed to fetch projects"
        self.parent_cmd:failed()
      end
    end),
  }):start()
end

return ListProjectsCommand
