local pickers = require('linear.pickers')

local ListStatesViewer = {}
ListStatesViewer.__index = ListStatesViewer

function ListStatesViewer:new(states)
	pickers.states.list:new(states)
end

return ListStatesViewer
