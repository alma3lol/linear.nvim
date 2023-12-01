local pickers = require('linear.pickers')

local ListStatesViewer = {}
ListStatesViewer.__index = ListStatesViewer

function ListStatesViewer:new(states)
	local results = {
		{
			id = "FILTER",
			name = "Filter"
		}
	}
	for _, state in pairs(states) do
		table.insert(results, state)
	end
	pickers.states.list:new(results)
end

return ListStatesViewer
