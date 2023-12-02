local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local fzy = require "telescope.algos.fzy"
local filters = require("linear.filters")

local ListMilestonesPicker = {}
ListMilestonesPicker.__index = ListMilestonesPicker

function ListMilestonesPicker:finder(results)
	local displayer = entry_display.create {
		separator = " ",
		items = {
			{ width = 4 },
			{ remaining = true },
		},
	}
	local make_display = function(entry)
		return displayer {
			{ entry.entry.id, "TelescopeResultsLineNr" },
			entry.entry.name,
		}
	end
	return finders.new_table {
		results = results,
		entry_maker = function(entry)
			return {
				value = entry.id .. " " .. entry.name,
				display = make_display,
				ordinal = entry.id .. " " .. entry.name,
				entry = entry,
			}
		end,
	}
end

function ListMilestonesPicker:sorter()
	local OFFSET = -fzy.get_score_floor()
	return sorters.new {
		discard = true,
		scoring_function = function(_, prompt, _, entry)
			if entry.entry.id == "FILTER" then
				return 0
			end
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

function ListMilestonesPicker:previewer(parent_cmd)
	local ns_id = vim.api.nvim_create_namespace("LinearApp")
	return previewers.new_buffer_previewer {
		define_preview = function(self, entry)
			vim.api.nvim_buf_call(self.state.bufnr, function()
				local e = entry.entry
				if e.id == "FILTER" then
					local project = "No project"
					local hl_line = ""
					if parent_cmd.args.filtering_entry then
						project = parent_cmd.args.filtering_entry.name
						hl_line = "Project" .. project:gsub("%s+", ""):gsub("-", "")
						vim.cmd("highlight " .. hl_line .. " gui=bold guifg=" .. parent_cmd.args.filtering_entry.color)
					end
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Project: " .. project })
					if hl_line ~= "" then
						vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, hl_line, 0, 9, #project + 9)
					end
				else
					local lines = {
						"ID: " .. e.id,
						"Name: " .. e.name,
						"Description: " .. (e.description ~= nil and e.description or ""),
						"Target date: " .. (e.targetDate ~= nil and e.targetDate or "No target date"),
						"Project: " .. (e.project ~= nil and e.project.name or "No project"),
					}
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					if e.project ~= nil then
						local hl = "Project" .. e.project.name:gsub("%s+", ""):gsub("-", "")
						vim.cmd("highlight " .. hl .. " gui=bold guifg=" .. e.project.color)
						vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, hl, 4, 9, #e.project.name + 9)
					end
				end
			end)
		end
	}
end

function ListMilestonesPicker:attach_mappings(parent_cmd)
	return function(prompt_bufnr, map)
		map({ 'i', 'n' }, '<CR>', function()
			local selection = action_state.get_selected_entry()
			if selection.entry.id == "FILTER" then
				if parent_cmd.args.filtering_allowed == false then
					vim.notify("Filtering is not allowed", vim.log.levels.WARN, { title = "Linear.nvim" })
				else
					actions.close(prompt_bufnr)
					filters.milestones.list:new()
				end
			else
				actions.close(prompt_bufnr)
				-- TODO: SHOW UPDATE MILESTONE PICKER
				if type(parent_cmd.args.callback) == "function" then
					parent_cmd.args.callback(selection.entry)
				end
			end
		end)
		return true
	end
end

function ListMilestonesPicker:picker(results, parent_cmd)
	return pickers.new({}, {
		prompt_title = "Milestones",
		finder = ListMilestonesPicker:finder(results),
		sorter = ListMilestonesPicker:sorter(),
		previewer = ListMilestonesPicker:previewer(parent_cmd),
		attach_mappings = ListMilestonesPicker:attach_mappings(parent_cmd),
	})
end

function ListMilestonesPicker:new(results, parent_cmd)
	self:picker(results, parent_cmd):find()
end

return ListMilestonesPicker
