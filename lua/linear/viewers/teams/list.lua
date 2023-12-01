local pickers = require('linear.pickers')

local ListTeamsViewer = {}
ListTeamsViewer.__index = ListTeamsViewer

function ListTeamsViewer:new(teams, cb)
	pickers.teams.list:new(teams, cb)
end

return ListTeamsViewer
