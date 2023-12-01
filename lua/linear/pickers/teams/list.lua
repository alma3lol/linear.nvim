local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local options = require('linear').options
local fzy = require "telescope.algos.fzy"

local ListTeamsPicker = {}
ListTeamsPicker.__index = ListTeamsPicker

function ListTeamsPicker:finder(results)
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

function ListTeamsPicker:sorter()
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

function ListTeamsPicker:previewer()
	local ns_id = vim.api.nvim_create_namespace("LinearApp")
	return previewers.new_buffer_previewer {
		define_preview = function(self, entry)
			vim.api.nvim_buf_call(self.state.bufnr, function()
				local hl_name = "Team" .. entry.entry.name:gsub("%s+", ""):gsub("-", "")
				vim.api.nvim_set_hl(0, hl_name, { fg = entry.entry.color, bold = true })
				local lines = {
					"ID: " .. entry.entry.id,
					"Name: " .. entry.entry.name,
					"Description: " .. (entry.entry.description or ""),
					"Private: " .. (entry.entry.private and "Yes" or "No"),
					"Key: " .. entry.entry.key,
				}
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, hl_name, 1, 6, #entry.entry.name + 6)
				vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, entry.entry.private and "DiagnosticOk" or "Error",
					3, 9, (entry.entry.private and 3 or 2) + 9)
			end)
		end
	}
end

function ListTeamsPicker:attach_mappings(cb)
	return function(prompt_bufnr, map)
		map({ 'i', 'n' }, '<CR>', function()
			actions.close(prompt_bufnr)
			local selection = action_state.get_selected_entry()
			cb(selection.entry)
			print(vim.inspect(selection))
		end)
		return true
	end
end

function ListTeamsPicker:picker(results, cb)
	return pickers.new({}, {
		prompt_title = "Teams",
		finder = ListTeamsPicker:finder(results),
		sorter = ListTeamsPicker:sorter(),
		previewer = ListTeamsPicker:previewer(),
		attach_mappings = ListTeamsPicker:attach_mappings(cb),
	})
end

function ListTeamsPicker:new(results, cb)
	self:picker(results, cb):find()
end

return ListTeamsPicker
