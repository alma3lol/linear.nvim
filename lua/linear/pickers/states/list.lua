local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local options = require('linear').options

local ListStatesPicker = {}
ListStatesPicker.__index = ListStatesPicker

function ListStatesPicker:new(results)
	local displayer = entry_display.create {
		separator = " ",
		items = {
			{ width = 4 },
			{ width = 2 },
			{ remaining = true },
		},
	}
	local make_display = function(entry)
		return displayer {
			{ entry.entry.id, "TelescopeResultsLineNr" },
			entry.entry.id == "FILTER" and "🔍" or options.icons.states[entry.entry.name],
			entry.entry.name,
		}
	end
	local fzy = require "telescope.algos.fzy"
	local OFFSET = -fzy.get_score_floor()
	local ns_id = vim.api.nvim_create_namespace("LinearApp")
	pickers.new({}, {
		prompt_title = "States",
		finder = finders.new_table {
			results = results,
			entry_maker = function(entry)
				return {
					value = entry.id .. " " .. entry.name,
					display = make_display,
					ordinal = entry.id .. " " .. entry.name,
					entry = entry,
				}
			end,
		},
		sorter = sorters.new {
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
		},
		previewer = previewers.new_buffer_previewer {
			define_preview = function(self, entry)
				vim.api.nvim_buf_call(self.state.bufnr, function()
					vim.api.nvim_set_hl(0, "IssuesState" .. entry.entry.name:gsub("%s+", ""),
						{ fg = entry.entry.color, bold = true })
					local lines = {
						"ID: " .. entry.entry.id,
						"Name: " .. entry.entry.name,
						"Type: " .. entry.entry.type:sub(1, 1):upper() .. entry.entry.type:sub(2),
						"Team: " .. (entry.entry.team and entry.entry.team.name or "No team"),
					}
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id,
						"IssuesState" .. entry.entry.name:gsub("%s+", ""), 1, 6, #entry.entry.name + 6)
				end)
			end
		},
		attach_mappings = function(prompt_bufnr, map)
			map({ 'i', 'n' }, '<CR>', function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				print(vim.inspect(selection))
			end)
			return true
		end,
	}):find()
end

return ListStatesPicker
