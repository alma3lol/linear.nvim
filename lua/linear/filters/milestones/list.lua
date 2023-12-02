local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"

local ListMilestonesFilter = {}
ListMilestonesFilter.__index = ListMilestonesFilter

function ListMilestonesFilter:finder(project)
	local displayer = entry_display.create {
		separator = " ",
		items = {
			{ width = 7 },
			{ width = 1 },
			{ remaining = true },
		},
	}
	local make_display = function(entry)
		local e = entry.entry
		local name = "No project"
		local hl_name = ""
		if e.project ~= nil then
			name = e.project.name
			hl_name = "Project" .. e.project.name:gsub("%s+", ""):gsub("-", "")
			vim.cmd("highlight " .. hl_name .. " gui=bold guifg=" .. e.project.color)
		end
		return displayer {
			"Project",
			":",
			{ name, hl_name },
		}
	end
	return finders.new_table {
		results = { { id = "projectId", project = project, name = "Project" } },
		entry_maker = function(entry)
			return {
				value = entry.id,
				display = make_display,
				ordinal = entry.id,
				entry = entry,
			}
		end,
	}
end

function ListMilestonesFilter:sorter()
	local fzy = require "telescope.algos.fzy"
	local OFFSET = -fzy.get_score_floor()
	return sorters.new {
		discard = true,
		scoring_function = function(_, prompt, _, entry)
			if not fzy.has_match(prompt, entry.entry.name) then
				return -1
			end
			local fzy_score = fzy.score(prompt, entry.entry.name)
			if fzy_score == fzy.get_score_min() then
				return 1
			end
			return 1 / (fzy_score + OFFSET)
		end,
		highlighter = function(_, prompt, display)
			return fzy.positions(prompt, display)
		end,
	}
end

function ListMilestonesFilter:previewer()
	return previewers.new_buffer_previewer {
		define_preview = function(self, entry)
			local ns_id = vim.api.nvim_create_namespace("LinearApp")
			vim.api.nvim_buf_call(self.state.bufnr, function()
				local e = entry.entry
				local lines = {
					"Project: " .. (e.project ~= nil and e.project.name or "No project"),
				}
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				if e.project ~= nil then
					local hl_name = "Project" .. e.project.name:gsub("%s+", ""):gsub("-", "")
					vim.cmd("highlight " .. hl_name .. " gui=bold guifg=" .. e.project.color)
					vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, hl_name, 0, 9, #e.project.name + 9)
				end
			end)
		end
	}
end

function ListMilestonesFilter:attach_mappings()
	return function(prompt_bufnr)
		-- local picker = action_state.get_current_picker(prompt_bufnr)
		actions.select_default:replace(function()
			local selection = action_state.get_selected_entry()
			if selection == nil then
				return
			end
			-- TODO: OPEN PROJECTS SELECTION
			actions.close(prompt_bufnr)
			require("linear.command"):new("projects", "list", {
				callback = function(project)
					require("linear.command"):new("milestones", "list", { filtering_entry = project }):run()
				end
			}):run()
		end)
		return true
	end
end

function ListMilestonesFilter:new(project)
	pickers.new({}, {
		prompt_title = "Filter: Milestones",
		finder = ListMilestonesFilter:finder(project),
		sorter = ListMilestonesFilter:sorter(),
		previewer = ListMilestonesFilter:previewer(),
		attach_mappings = ListMilestonesFilter:attach_mappings(),
	}):find()
end

return ListMilestonesFilter
