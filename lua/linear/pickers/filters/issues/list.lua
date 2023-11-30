local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local options = require('linear').options

local ListIssuesFilterPicker = {}
ListIssuesFilterPicker.__index = ListIssuesFilterPicker

function ListIssuesFilterPicker:new()
	local displayer = entry_display.create {
		separator = " ",
		items = {
			{ width = 2 },
			{ remaining = true },
		},
	}
	local make_display = function(entry)
		return displayer {
			entry.entry.icon,
			entry.entry.name,
		}
	end
	local fzy = require "telescope.algos.fzy"
	local OFFSET = -fzy.get_score_floor()
	local results = {}
	for key, value in pairs(options.filters.issues.states) do
		table.insert(results, { icon = value == true and "" or "", value = value, name = key })
	end
	pickers.new({}, {
		prompt_title = "Filter: Issues",
		finder = finders.new_table {
			results = results,
			entry_maker = function(entry)
				return {
					value = entry.icon .. " " .. entry.name,
					display = make_display,
					ordinal = entry.icon .. " " .. entry.name,
					entry = entry,
				}
			end,
		},
		sorter = sorters.new {
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
		},
		previewer = previewers.new_buffer_previewer {
			define_preview = function(self, entry)
				vim.api.nvim_buf_call(self.state.bufnr, function()
					local lines = {
						entry.entry.name .. ": " .. (entry.entry.value == true and "Enabled" or "Disabled")
					}
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				end)
			end
		},
		attach_mappings = function(prompt_bufnr, map)
			map('i', '<c-r>', function()
				actions.close(prompt_bufnr)
				require('linear.command'):new("issues", "list"):run()
			end)
			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
				if selection.entry.value == true then
					selection.entry.value = false
					options.filters.issues.states[selection.entry.name] = false
				else
					selection.entry.value = true
					options.filters.issues.states[selection.entry.name] = true
				end
				actions.move_selection_next(prompt_bufnr)
				actions.move_selection_previous(prompt_bufnr)
			end)
			return true
		end,
	}):find()
end

return ListIssuesFilterPicker
