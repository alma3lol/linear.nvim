local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local fzy = require "telescope.algos.fzy"

local ListUsersPicker = {}
ListUsersPicker.__index = ListUsersPicker

function ListUsersPicker:finder(results)
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

function ListUsersPicker:sorter()
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

function ListUsersPicker:previewer()
	local ns_id = vim.api.nvim_create_namespace("LinearApp")
	return previewers.new_buffer_previewer {
		define_preview = function(self, entry)
			vim.api.nvim_buf_call(self.state.bufnr, function()
				local lines = {
					"ID: " .. entry.entry.id,
					"Name: " .. entry.entry.name,
					"Email: " .. (entry.entry.email ~= nil and entry.entry.email or "No email"),
					"Is Me: " .. (entry.entry.isMe == true and "Yes" or "No"),
					"Admin: " .. (entry.entry.admin == true and "Yes" or "No"),
					"Display name: " .. entry.entry.displayName,
				}
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
			end)
		end
	}
end

function ListUsersPicker:attach_mappings(cb)
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

function ListUsersPicker:picker(results, cb)
	print(vim.inspect(results))
	return pickers.new({}, {
		prompt_title = "Users",
		finder = ListUsersPicker:finder(results),
		sorter = ListUsersPicker:sorter(),
		previewer = ListUsersPicker:previewer(),
		attach_mappings = ListUsersPicker:attach_mappings(cb),
	})
end

function ListUsersPicker:new(results, cb)
	self:picker(results, cb):find()
end

return ListUsersPicker
