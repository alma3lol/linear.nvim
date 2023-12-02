local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local fzy = require "telescope.algos.fzy"

local ListLabelsPicker = {}
ListLabelsPicker.__index = ListLabelsPicker

function ListLabelsPicker:finder(results)
	local displayer = entry_display.create {
		separator = " ",
		items = {
			{ width = 4 },
			{ remaining = true },
		},
	}
	local make_display = function(entry)
		local e = entry.entry
		local hl_name = "Label" .. e.name:gsub("%s+", ""):gsub("-", "")
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

function ListLabelsPicker:sorter()
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

function ListLabelsPicker:previewer()
	local ns_id = vim.api.nvim_create_namespace("LinearApp")
	return previewers.new_buffer_previewer {
		define_preview = function(self, entry)
			vim.api.nvim_buf_call(self.state.bufnr, function()
				local e = entry.entry
				local lines = {
					"ID: " .. e.id,
					"Name: " .. e.name,
					"Description: " .. (e.description ~= nil and e.description or ""),
					"Creator: " .. (e.creator ~= nil and e.creator.name or "No creator"),
					"Team: " .. (e.team ~= nil and e.team.name or "No team"),
					"Parent: " .. (e.parent ~= nil and e.parent.name or "No parent"),
				}
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				local hl_name = "Label" .. e.name:gsub("%s+", ""):gsub("-", "")
				vim.cmd("highlight " .. hl_name .. " gui=bold guifg=" .. e.color)
				if e.team ~= nil then
					local hl = "Team" .. e.team.name:gsub("%s+", ""):gsub("-", "")
					vim.cmd("highlight " .. hl .. " gui=bold guifg=" .. e.team.color)
					vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, hl, 4, 6, #e.team.name + 6)
				end
				if e.parent ~= nil then
					local hl = "Label" .. e.parent.name:gsub("%s+", ""):gsub("-", "")
					vim.cmd("highlight " .. hl .. " gui=bold guifg=" .. e.parent.color)
					vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, hl, 5, 8, #e.parent.name + 8)
				end
				vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, hl_name, 1, 6, #e.name + 6)
			end)
		end
	}
end

function ListLabelsPicker:attach_mappings(parent_cmd)
	return function(prompt_bufnr, map)
		map({ 'i', 'n' }, '<CR>', function()
			local picker = action_state.get_current_picker(prompt_bufnr)
			local selections = {}
			for _, entry in ipairs(picker:get_multi_selection()) do
				table.insert(selections, entry.entry)
			end
			local selection = action_state.get_selected_entry()
			actions.close(prompt_bufnr)
			if type(parent_cmd.args.callback) == "function" then
				if #selections > 0 then
					parent_cmd.args.callback(selections)
				else
					parent_cmd.args.callback({ selection.entry })
				end
			end
		end)
		map({ 'i', 'n' }, '<s-cr>', function()
			actions.close(prompt_bufnr)
			if type(parent_cmd.args.callback) == "function" then
				parent_cmd.args.callback({})
			end
		end)
		return true
	end
end

function ListLabelsPicker:picker(results, parent_cmd)
	print(vim.inspect(results))
	return pickers.new({}, {
		prompt_title = "Labels",
		finder = ListLabelsPicker:finder(results),
		sorter = ListLabelsPicker:sorter(),
		previewer = ListLabelsPicker:previewer(),
		attach_mappings = ListLabelsPicker:attach_mappings(parent_cmd),
	})
end

function ListLabelsPicker:new(results, parent_cmd)
	self:picker(results, parent_cmd):find()
end

return ListLabelsPicker
