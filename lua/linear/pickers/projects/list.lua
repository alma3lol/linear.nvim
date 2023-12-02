local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local fzy = require "telescope.algos.fzy"

local ListProjectsPicker = {}
ListProjectsPicker.__index = ListProjectsPicker

function ListProjectsPicker:finder(results)
	local displayer = entry_display.create {
		separator = " ",
		items = {
			{ width = 4 },
			{ remaining = true },
		},
	}
	local make_display = function(entry)
		local e = entry.entry
		local hl_name = "Project" .. e.name:gsub("%s+", ""):gsub("-", "")
		vim.cmd("highlight " .. hl_name .. " gui=bold guifg=" .. e.color)
		return displayer {
			{ entry.entry.id,   "TelescopeResultsLineNr" },
			{ entry.entry.name, hl_name },
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

function ListProjectsPicker:sorter()
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

function ListProjectsPicker:previewer()
	local ns_id = vim.api.nvim_create_namespace("LinearApp")
	return previewers.new_buffer_previewer {
		define_preview = function(self, entry)
			vim.api.nvim_buf_call(self.state.bufnr, function()
				local e = entry.entry
				local stateToStateLabel = function(state)
					if state == "backlog" then
						return "Backlog"
					elseif state == "planned" then
						return "Planned"
					elseif state == "started" then
						return "In Progress"
					elseif state == "paused" then
						return "Paused"
					elseif state == "completed" then
						return "Completed"
					elseif state == "canceled" then
						return "Canceled"
					end
					return ""
				end
				local lines = {
					"ID: " .. e.id,
					"Name: " .. e.name,
					"Description: " .. (e.description ~= nil and e.description or ""),
					"State: " .. stateToStateLabel(e.state),
				}
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				local hl_name = "Project" .. e.name:gsub("%s+", ""):gsub("-", "")
				vim.cmd("highlight " .. hl_name .. " gui=bold guifg=" .. e.color)
				vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, hl_name, 1, 6, #e.name + 6)
			end)
		end
	}
end

function ListProjectsPicker:attach_mappings(cb)
	return function(prompt_bufnr, map)
		map({ 'i', 'n' }, '<CR>', function()
			actions.close(prompt_bufnr)
			local selection = action_state.get_selected_entry()
			if type(cb) == "function" then
				cb(selection.entry)
			end
		end)
		return true
	end
end

function ListProjectsPicker:picker(results, cb)
	print(vim.inspect(results))
	return pickers.new({}, {
		prompt_title = "Projects",
		finder = ListProjectsPicker:finder(results),
		sorter = ListProjectsPicker:sorter(),
		previewer = ListProjectsPicker:previewer(),
		attach_mappings = ListProjectsPicker:attach_mappings(cb),
	})
end

function ListProjectsPicker:new(results, cb)
	self:picker(results, cb):find()
end

return ListProjectsPicker
