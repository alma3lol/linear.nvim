local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local fzy = require "telescope.algos.fzy"

local ListPrioritiesPicker = {}
ListPrioritiesPicker.__index = ListPrioritiesPicker

function ListPrioritiesPicker:finder(results)
	local displayer = entry_display.create {
		separator = " ",
		items = {
			{ width = 1 },
			{ remaining = true },
		},
	}
	local make_display = function(entry)
		return displayer {
			{ tostring(entry.entry.priority), "TelescopeResultsLineNr" },
			entry.entry.label,
		}
	end
	return finders.new_table {
		results = results,
		entry_maker = function(entry)
			return {
				value = entry.label .. " " .. tostring(entry.priority),
				display = make_display,
				ordinal = entry.label .. " " .. tostring(entry.priority),
				entry = entry,
			}
		end,
	}
end

function ListPrioritiesPicker:sorter()
	local OFFSET = -fzy.get_score_floor()
	return sorters.new {
		discard = true,
		scoring_function = function(_, prompt, _, entry)
			if entry.entry.id == "FILTER" then
				return 0
			end
			if not fzy.has_match(prompt, entry.entry.label) then
				return -1
			end
			local fzy_score = fzy.score(prompt, entry.entry.label)
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

function ListPrioritiesPicker:previewer()
	return previewers.new_buffer_previewer {
		define_preview = function(self, entry)
			vim.api.nvim_buf_call(self.state.bufnr, function()
				local lines = {
					"Label: " .. entry.entry.label,
					"Priority: " .. tostring(entry.entry.priority),
				}
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
			end)
		end
	}
end

function ListPrioritiesPicker:attach_mappings(cb)
	return function(prompt_bufnr, map)
		map({ 'i', 'n' }, '<CR>', function()
			actions.close(prompt_bufnr)
			local selection = action_state.get_selected_entry()
			-- TODO: SHOW UPDATE PRIORITY PICKER
			if type(cb) == "function" then
				cb(selection.entry)
			end
		end)
		return true
	end
end

function ListPrioritiesPicker:picker(results, cb)
	return pickers.new({}, {
		prompt_title = "Priorities",
		finder = ListPrioritiesPicker:finder(results),
		sorter = ListPrioritiesPicker:sorter(),
		previewer = ListPrioritiesPicker:previewer(),
		attach_mappings = ListPrioritiesPicker:attach_mappings(cb),
	})
end

function ListPrioritiesPicker:new(results, cb)
	self:picker(results, cb):find()
end

return ListPrioritiesPicker
