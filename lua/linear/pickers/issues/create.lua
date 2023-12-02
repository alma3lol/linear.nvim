local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require "telescope.sorters"
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local options = require('linear').options
local fzy = require "telescope.algos.fzy"
local Job = require 'plenary.job'

local CreateIssuePicker = {}
CreateIssuePicker.__index = CreateIssuePicker

function CreateIssuePicker:title()
	return "Create a new issue"
end

function CreateIssuePicker:finder(results)
	local displayer = entry_display.create {
		separator = " ",
		items = {
			{ width = 9 },
			{ width = 1 },
			{ remaining = true },
		},
	}
	local make_display = function(entry)
		local e = entry.entry
		local hl_name = ""
		if type(e.value) == "table" then
			if e.id == "labelIds" then
				for _, label in ipairs(e.value) do
					vim.cmd("highlight IssuesLabel" ..
						label.name:gsub("%s+", ""):gsub("-", "") .. " gui=bold guifg=" .. label.color)
				end
			elseif e.id ~= "priority" then
				local name = e.value.name:gsub("%s+", ""):gsub("-", "")
				if e.id == "stateId" then
					hl_name = "IssuesState" .. name
				elseif e.id == "teamId" then
					hl_name = "Team" .. name
				elseif e.id == "projectId" then
					hl_name = "Project" .. name
				end
			end
		end
		if hl_name ~= "" then
			vim.cmd("highlight " .. hl_name .. " gui=bold guifg=" .. e.value.color)
		end
		return displayer {
			e.title,
			":",
			{ e.displayedValue ~= "" and e.displayedValue or e.value, hl_name },
		}
	end
	return finders.new_table {
		results = results,
		entry_maker = function(entry)
			return {
				value = entry.title .. " " .. entry.displayedValue,
				display = make_display,
				ordinal = entry.title .. " " .. entry.displayedValue,
				entry = entry,
			}
		end,
	}
end

function CreateIssuePicker:sorter()
	local OFFSET = -fzy.get_score_floor()
	return sorters.new {
		discard = true,
		scoring_function = function(_, prompt, _, entry)
			local e = entry.entry
			if e.id == "FILTER" then
				return 0
			end
			if not fzy.has_match(prompt, e.title) then
				return -1
			end
			local fzy_score = fzy.score(prompt, e.title)
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

function CreateIssuePicker:previewer()
	local ns_id = vim.api.nvim_create_namespace("LinearApp")
	return previewers.new_buffer_previewer {
		define_preview = function(self, entry)
			local e = entry.entry
			local lines = {}
			local hl_lines = {}
			if type(e.value) == "table" then
				if e.id == "labelIds" then
					table.insert(lines, "Labels:")
					for _, label in ipairs(e.value) do
						local hl_name = "IssuesLabel" .. label.name:gsub("%s+", ""):gsub("-", "")
						table.insert(lines, " - " .. label.name)
						table.insert(hl_lines, { hl_name, label.color, #lines - 1, 3, #label.name + 3 })
					end
				elseif e.id ~= "priority" then
					local hl_name = ""
					local name = e.value.name:gsub("%s+", ""):gsub("-", "")
					if e.id == "stateId" then
						hl_name = "IssuesState" .. name
					elseif e.id == "teamId" then
						hl_name = "Team" .. name
					elseif e.id == "projectId" then
						hl_name = "Project" .. name
					end
					local v = (e.displayedValue ~= "" and e.displayedValue or e.value)
					if hl_name ~= "" then
						table.insert(hl_lines, { hl_name, e.value.color, 0, #e.title + 2, #e.title + 2 + #v })
					end
					table.insert(lines, e.title .. ": " .. v)
				end
			end
			vim.api.nvim_buf_call(self.state.bufnr, function()
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
			end)
			for _, hl_line in ipairs(hl_lines) do
				vim.cmd("highlight " .. hl_line[1] .. " gui=bold guifg=" .. hl_line[2])
				vim.api.nvim_buf_add_highlight(self.state.bufnr, ns_id, hl_line[1], hl_line[3], hl_line[4], hl_line[5])
			end
		end
	}
end

function CreateIssuePicker:attach_mappings(parent_cmd)
	return function(prompt_bufnr, map)
		local picker = action_state.get_current_picker(prompt_bufnr)
		actions.select_default:replace(function()
			local selection = action_state.get_selected_entry()
			if selection == nil then
				return
			end
			local e = selection.entry
			local id = e.id
			local value = e.value
			local update_value_and_refresh = function(newValue)
				selection.entry.value = newValue
				picker:refresh()
				if selection.index == 1 then
					actions.move_selection_next(prompt_bufnr)
					actions.move_selection_previous(prompt_bufnr)
				else
					local timer = vim.loop.new_timer()
					timer:start(5, 0, vim.schedule_wrap(function()
						timer:stop()
						timer:close()
						picker:move_selection(selection.index - 1)
					end))
				end
			end
			if id == "stateId" then
				local issue = {}
				for entry in picker.manager:iter() do
					table.insert(issue, entry.entry)
				end
				actions.close(prompt_bufnr)
				require("linear.command"):new("states", "list", {
					callback = function(state)
						local updated_issue = {}
						for _, entry in ipairs(issue) do
							if state ~= nil and entry.id == "stateId" then
								entry.value = state
								entry.displayedValue = state.name
							end
							table.insert(updated_issue, entry)
						end
						CreateIssuePicker:picker(parent_cmd, updated_issue):find()
					end
				}):run()
			elseif id == "teamId" then
				local issue = {}
				for entry in picker.manager:iter() do
					table.insert(issue, entry.entry)
				end
				actions.close(prompt_bufnr)
				require("linear.command"):new("teams", "list", {
					callback = function(team)
						local updated_issue = {}
						for _, entry in ipairs(issue) do
							if team ~= nil and entry.id == "teamId" then
								entry.value = team
								entry.displayedValue = team.name
							end
							table.insert(updated_issue, entry)
						end
						CreateIssuePicker:picker(parent_cmd, updated_issue):find()
					end
				}):run()
			elseif id == "assigneeId" then
				local issue = {}
				for entry in picker.manager:iter() do
					table.insert(issue, entry.entry)
				end
				actions.close(prompt_bufnr)
				require("linear.command"):new("users", "list", {
					callback = function(user)
						local updated_issue = {}
						for _, entry in ipairs(issue) do
							if user ~= nil and entry.id == "assigneeId" then
								entry.value = user
								entry.displayedValue = user.name
							end
							table.insert(updated_issue, entry)
						end
						CreateIssuePicker:picker(parent_cmd, updated_issue):find()
					end
				}):run()
			elseif id == "projectId" then
				local issue = {}
				for entry in picker.manager:iter() do
					table.insert(issue, entry.entry)
				end
				actions.close(prompt_bufnr)
				require("linear.command"):new("projects", "list", {
					callback = function(project)
						local updated_issue = {}
						for _, entry in ipairs(issue) do
							if project ~= nil and entry.id == "projectId" then
								entry.value = project
								entry.displayedValue = project.name
							end
							table.insert(updated_issue, entry)
						end
						CreateIssuePicker:picker(parent_cmd, updated_issue):find()
					end
				}):run()
			elseif id == "priority" then
				local issue = {}
				for entry in picker.manager:iter() do
					table.insert(issue, entry.entry)
				end
				actions.close(prompt_bufnr)
				require("linear.command"):new("priorities", "list", {
					callback = function(priority)
						local updated_issue = {}
						for _, entry in ipairs(issue) do
							if priority ~= nil and entry.id == "priority" then
								entry.value = priority
								entry.displayedValue = priority.label
							end
							table.insert(updated_issue, entry)
						end
						CreateIssuePicker:picker(parent_cmd, updated_issue):find()
					end
				}):run()
			elseif id == "labelIds" then
				local issue = {}
				for entry in picker.manager:iter() do
					table.insert(issue, entry.entry)
				end
				actions.close(prompt_bufnr)
				require("linear.command"):new("labels", "list", {
					callback = function(labels)
						local updated_issue = {}
						for _, entry in ipairs(issue) do
							if labels ~= nil and entry.id == "labelIds" then
								entry.value = labels
								entry.displayedValue = tostring(#labels)
							end
							table.insert(updated_issue, entry)
						end
						CreateIssuePicker:picker(parent_cmd, updated_issue):find()
					end
				}):run()
			elseif id == "milestoneId" then
				local project = {}
				local issue = {}
				for entry in picker.manager:iter() do
					if entry.entry.id == "projectId" then
						if entry.entry.displayedValue == "" then
							vim.notify("Select a project first!", vim.log.levels.WARN, { title = "Linear.nvim" })
							return
						else
							project = entry.entry.value
						end
					end
					table.insert(issue, entry.entry)
				end
				actions.close(prompt_bufnr)
				require("linear.command"):new("milestones", "list", {
					callback = function(milestone)
						local updated_issue = {}
						for _, entry in ipairs(issue) do
							if milestone ~= nil and entry.id == "milestoneId" then
								entry.value = milestone
								entry.displayedValue = milestone.name
							end
							table.insert(updated_issue, entry)
						end
						CreateIssuePicker:picker(parent_cmd, updated_issue):find()
					end,
					filtering_allowed = false,
					filtering_entry = project,
				}):run()
			else
				local newValue = vim.fn.input({ prompt = "> ", default = value })
				update_value_and_refresh(newValue)
			end
		end)
		map({ 'i', 'n' }, '<s-cr>', function()
			local args = { '-s', 'linear', 'issues', '--api-key', options.api_key, '--json', 'create' }
			for entry in picker.manager:iter() do
				local e = entry.entry
				local id = e.id
				local value = e.value
				if id == "teamId" then
					if value == "" then
						vim.notify("You must select a team!", vim.log.levels.WARN,
							{ title = "Linear.nvim" })
						return
					end
					table.insert(args, "-T")
					table.insert(args, value.id)
				elseif id == "title" then
					if value == "" then
						vim.notify("Title cannot be empty!", vim.log.levels.WARN,
							{ title = "Linear.nvim" })
						return
					end
					table.insert(args, "-t")
					table.insert(args, value)
				elseif id == "stateId" then
					if value == "" then
						vim.notify("You must select a state!", vim.log.levels.WARN,
							{ title = "Linear.nvim" })
						return
					end
					table.insert(args, "-s")
					table.insert(args, value.id)
				elseif id == "assigneeId" then
					if value ~= "" then
						table.insert(args, "-a")
						table.insert(args, value.id)
					end
				elseif id == "priority" then
					if value ~= "" then
						table.insert(args, "-p")
						table.insert(args, value.priority)
					end
				elseif id == "projectId" then
					if value ~= "" then
						table.insert(args, "-P")
						table.insert(args, value.id)
					end
				elseif id == "milestoneId" then
					if value ~= "" then
						table.insert(args, "-m")
						table.insert(args, value.id)
					end
				elseif id == "labelIds" then
					if #value > 0 then
						table.insert(args, "-l")
						local labelIds = {}
						for _, label in ipairs(value) do
							table.insert(labelIds, label.id)
						end
						table.insert(args, table.concat(labelIds, ","))
					end
				end
			end
			actions.close(prompt_bufnr)
			parent_cmd:show_spinner()
			Job:new({
				command = 'yarn',
				args = args,
				on_exit = vim.schedule_wrap(function(j, return_val)
					print(vim.inspect(j:result()))
					if (return_val == 0) then
						local data = vim.json.decode(table.concat(j:result(), ""))
						parent_cmd:success(data)
					else
						parent_cmd.text = "Failed to create the issue"
						parent_cmd:failed()
					end
				end),
			}):start()
		end)
		return true
	end
end

function CreateIssuePicker:picker(parent_cmd, issue)
	return pickers.new({}, {
		prompt_title = CreateIssuePicker:title(),
		finder = CreateIssuePicker:finder(issue),
		sorter = CreateIssuePicker:sorter(),
		previewer = CreateIssuePicker:previewer(),
		attach_mappings = CreateIssuePicker:attach_mappings(parent_cmd),
	})
end

function CreateIssuePicker:new(parent_cmd)
	local issue = {
		{ id = "title",       title = "Title",     value = "", displayedValue = "" },
		{ id = "stateId",     title = "State",     value = "", displayedValue = "" },
		{ id = "teamId",      title = "Team",      value = "", displayedValue = "" },
		{ id = "labelIds",    title = "Labels",    value = {}, displayedValue = "0" },
		{ id = "assigneeId",  title = "Assignee",  value = "", displayedValue = "" },
		{ id = "priority",    title = "Priority",  value = "", displayedValue = "" },
		{ id = "projectId",   title = "Project",   value = "", displayedValue = "" },
		{ id = "milestoneId", title = "Milestone", value = "", displayedValue = "" },
	}
	self:picker(parent_cmd, issue):find()
end

return CreateIssuePicker
