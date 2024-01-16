local Job = require 'plenary.job'
local options = require('linear').options

local ListIssuesCommand = {}
ListIssuesCommand.__index = ListIssuesCommand

function ListIssuesCommand:new(parent_cmd)
  self = setmetatable({}, ListIssuesCommand)
  self.parent_cmd = parent_cmd
  return self;
end

function ListIssuesCommand:run()
  if options.no_api_key() then
    return
  end
  local args = { '-s', 'linear', 'issues', '--api-key', options.api_key, '--json', 'list' }
  if options.filters and options.filters.issues then
    if options.filters.issues.states then
      local statesToFilterWith = {}
      for key, value in pairs(options.filters.issues.states) do
        if value == true then
          table.insert(statesToFilterWith, key)
        end
      end
      if #statesToFilterWith > 0 then
        table.insert(args, "-S")
        table.insert(args, table.concat(statesToFilterWith, ","))
      end
    end
  end
  Job:new({
    cwd = options.cwd,
    command = 'yarn',
    args = args,
    on_exit = vim.schedule_wrap(function(j, return_val)
      if (return_val == 0) then
        local issues = vim.json.decode(table.concat(j:result(), ""))
        self.parent_cmd:success(issues)
      else
        -- print(vim.inspect(j))
        print(vim.inspect(j:stderr_result()))
        self.parent_cmd.text = "Failed to fetch issues"
        self.parent_cmd:failed()
      end
    end),
  }):start()
end

return ListIssuesCommand
