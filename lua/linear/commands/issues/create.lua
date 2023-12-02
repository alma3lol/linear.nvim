local options = require('linear').options
local CreateIssuePicker = require('linear.pickers.issues.create')

local CreateIssuesCommand = {}
CreateIssuesCommand.__index = CreateIssuesCommand

function CreateIssuesCommand:new(parent_cmd)
  self = setmetatable({}, CreateIssuesCommand)
  self.parent_cmd = parent_cmd
  return self;
end

function CreateIssuesCommand:run()
  if options.no_api_key() then
    return
  end
  CreateIssuePicker:new(self.parent_cmd)
end

return CreateIssuesCommand
