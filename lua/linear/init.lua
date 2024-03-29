local Job = require 'plenary.job'

local M = {
	options = {}
}

M.defaults = function()
	return {
		api_key_cmd = nil,
		api_key = nil,
		magic_words = {
			yank_register = "+",
			prefix = "closes",
			parenthesis = true,
		},
		icons = {
			states = {
				["Backlog"] = "📦",
				["Todo"] = "📋",
				["In Progress"] = "⏳",
				["Done"] = "✅",
				["Canceled"] = "⛔",
				["Duplicate"] = "⛔",
			}
		},
		filters = {
			issues = {
				states = {
					["Backlog"] = true,
					["Todo"] = true,
					["In Progress"] = true,
					["In Preview"] = true,
					["Done"] = false,
					["Canceled"] = false,
					["Duplicate"] = false,
				}
			},
			states = {
				types = {
					["backlog"] = true,
					["unstarted"] = true,
					["started"] = true,
					["completed"] = true,
					["canceled"] = true,
				}
			}
		}
	}
end

M.setup = function(options)
	options = options or {}
	M.options = vim.tbl_deep_extend("force", {}, M.defaults(), options)
	M.options.no_api_key = function()
		if (M.options.api_key == nil or M.options.api_key == "") then
			vim.notify("No API key was provided!", vim.log.levels.ERROR, { title = "Linear.nvim" })
			return true
		end
		return false
	end
	if (options.api_key_cmd ~= nil) then
		local cmd = {}
		for part in options.api_key_cmd:gmatch("%S+") do
			table.insert(cmd, part)
		end
		Job:new({
			cwd = options.cwd,
			command = cmd[1],
			args = vim.list_slice(cmd, 2, #cmd),
			on_exit = function(j, result)
				if result == 0 or #j:result() > 0 then
					M.options.api_key = j:result()[1]:gsub("%s+$", "")
				end
				M.options.no_api_key();
			end
		}):start()
	end
	local dir = vim.fn.fnamemodify(vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":p:h"), ":p")
	M.options.cwd = dir
end

M.command = function(opts)
	require('linear.command'):new(opts.fargs[1], opts.fargs[2]):run()
end

return M
