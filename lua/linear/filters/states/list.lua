local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local options = require('linear').options

local ListStatesFilter = {}
ListStatesFilter.__index = ListStatesFilter

function ListStatesFilter:new()
	local displayer = entry_display.create {
		separator = " ",
		items = {
			{ width = 2 },
			{ remaining = true },
		},
	}
	local make_display = function(entry)
		local icon = entry.entry.value == true and "✅" or "❌"
		return displayer {
			icon,
			entry.entry.name:sub(1, 1):upper() .. entry.entry.name:sub(2),
		}
	end
	local fzy = require "telescope.algos.fzy"
	local OFFSET = -fzy.get_score_floor()
	local results = {}
	for key, value in pairs(options.filters.states.types) do
		table.insert(results, { value = value, name = key })
	end
	pickers.new({}, {
		prompt_title = "Filter: States",
		finder = finders.new_table {
			results = results,
			entry_maker = function(entry)
				local icon = entry.value == true and "✅" or "❌"
				return {
					value = icon .. " " .. entry.name,
					display = make_display,
					ordinal = icon .. " " .. entry.name,
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
						entry.entry.name:sub(1, 1):upper() ..
						entry.entry.name:sub(2) .. ": " .. (entry.entry.value == true and "Enabled" or "Disabled")
					}
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				end)
			end
		},
		attach_mappings = function(prompt_bufnr, map)
			map({ 'i', 'n' }, '<c-r>', function()
				actions.close(prompt_bufnr)
				require('linear.command'):new("states", "list"):run()
			end)
			local picker = action_state.get_current_picker(prompt_bufnr)
			actions.select_default:replace(function()
				local selected_entries = picker:get_multi_selection()
				local selection = action_state.get_selected_entry()
				if #selected_entries > 0 then
					for _, entry in ipairs(selected_entries) do
						if entry.entry.value == true then
							entry.entry.value = false
							options.filters.states.types[entry.entry.name] = false
						else
							entry.entry.value = true
							options.filters.states.types[entry.entry.name] = true
						end
					end
				else
					if selection == nil then
						return
					end
					if selection.entry.value == true then
						selection.entry.value = false
						options.filters.states.types[selection.entry.name] = false
					else
						selection.entry.value = true
						options.filters.states.types[selection.entry.name] = true
					end
					if selection.index == 1 then
						actions.move_selection_next(prompt_bufnr)
						actions.move_selection_previous(prompt_bufnr)
					end
				end
				picker:refresh()
				if selection ~= nil then
					local timer = vim.loop.new_timer()
					timer:start(1, 0, vim.schedule_wrap(function()
						timer:stop()
						timer:close()
						picker:move_selection(selection.index - 1)
					end))
				end
			end)
			return true
		end,
	}):find()
end

return ListStatesFilter
