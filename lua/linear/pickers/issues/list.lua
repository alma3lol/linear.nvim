local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local options = require('linear').options
local filters = require('linear.filters')


local ListIssuesPicker = {}
ListIssuesPicker.__index = ListIssuesPicker

function ListIssuesPicker:new(results)
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
			entry.entry.id == "FILTER" and "🔍" or options.icons.states[entry.entry.state.name],
			entry.entry.title,
		}
	end
	local fzy = require "telescope.algos.fzy"
	local OFFSET = -fzy.get_score_floor()
	local ns_id = vim.api.nvim_create_namespace("LinearApp")
	pickers.new({}, {
		prompt_title = "Issues",
		finder = finders.new_table {
			results = results,
			entry_maker = function(entry)
				return {
					value = entry.id .. " " .. entry.title,
					display = make_display,
					ordinal = entry.id .. " " .. entry.title,
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
				if not fzy.has_match(prompt, entry.entry.title) then
					return -1
				end
				local fzy_score = fzy.score(prompt, entry.entry.title)
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
					if entry.entry.id == "FILTER" then
						local lines = {
							"Status: "
						}
						if options.filters and options.filters.issues and options.filters.issues.states then
							for key, value in pairs(options.filters.issues.states) do
								table.insert(lines, " - " .. (value == true and "✅ " or "❌ ") .. key)
							end
						else
							table.insert(lines, " - ✅ All")
						end
						vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
						return
					end
					vim.api.nvim_set_hl(0, "IssuesState" .. entry.entry.state.name:gsub("%s+", ""),
						{ fg = entry.entry.state.color, bold = true })
					local lines = {
						"ID: " .. entry.entry.id, "Title: " .. entry.entry.title,
						"Status: " .. entry.entry.state.name,
						"Assignee: " .. (entry.entry.assignee and entry.entry.assignee.name or "NO assignee"),
						"Priority: " .. entry.entry.priority,
						"Project: " .. (entry.entry.project and entry.entry.project.name or "No project"),
						"Labels: " .. (#entry.entry.labels > 0 and "" or "No labels"),
					}
					for _, label in pairs(entry.entry.labels) do
						vim.api.nvim_set_hl(0, "IssuesLabel" .. label.name, { fg = label.color, bold = true })
						table.insert(lines, " - " .. label.name)
					end
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id,
						"IssuesState" .. entry.entry.state.name:gsub("%s+", ""), 2, 8, #entry.entry.state.name + 8)
					local labelC = #entry.entry.labels
					for _, label in pairs(entry.entry.labels) do
						vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, "IssuesLabel" .. label.name,
							#lines - labelC,
							3, #label.name + 3)
						labelC = labelC - 1
					end
				end)
			end
		},
		attach_mappings = function(prompt_bufnr, map)
			map({ 'i', 'n' }, '<c-m>', function()
				local picker = action_state.get_current_picker(prompt_bufnr)
				local selected_entries = picker:get_multi_selection()
				if #selected_entries > 0 then
					local magic_words = (options.magic_words.prefix or "closes") .. " "
					local identifiers = {}
					for _, entry in ipairs(selected_entries) do
						table.insert(identifiers, entry.entry.identifier)
					end
					magic_words = magic_words .. table.concat(identifiers, ", ")
					if options.magic_words.parenthesis then
						magic_words = "(" .. magic_words .. ")"
					end
					vim.fn.setreg(options.magic_words.yank_register or "", magic_words)
					vim.notify("Magic words copied to register (" .. (options.yank_register or '"') .. ")",
						vim.log.levels.INFO, { title = "Linear.nvim" })
				else
					local selection = action_state.get_selected_entry()
					if selection == nil or selection.entry.id == "FILTER" then
						vim.notify("Can't use magic words without entries",
							vim.log.levels.WARN, { title = "Linear.nvim" })
						return
					end
					local magic_words = (options.magic_words.prefix or "closes") .. " "
					magic_words = magic_words .. selection.entry.identifier
					if options.magic_words.parenthesis then
						magic_words = "(" .. magic_words .. ")"
					end
					vim.fn.setreg(options.magic_words.yank_register or "", magic_words)
					vim.notify("Magic words copied to register (" .. (options.yank_register or '"') .. ")",
						vim.log.levels.INFO, { title = "Linear.nvim" })
				end
			end)
			map({ 'i', 'n' }, '<CR>', function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection.entry.id == "FILTER" then
					filters.issues.list:new()
				else
					-- TODO: SHOW UPDATE ISSUE PICKER
					print(vim.inspect(selection))
				end
			end)
			return true
		end,
	}):find()
end

return ListIssuesPicker
