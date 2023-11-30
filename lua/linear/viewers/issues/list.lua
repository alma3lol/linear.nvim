local pickers = require('linear.pickers')

local ListIssuesViewer = {}
ListIssuesViewer.__index = ListIssuesViewer

function ListIssuesViewer:new(issues)
	local results = {
		{
			id = "FILTER",
			title = "Filter"
		}
	}
	for _, issue in pairs(issues) do
		table.insert(results, issue)
	end
	pickers.issues.list:new(results)
end

return ListIssuesViewer
