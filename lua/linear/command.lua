local Spinner = require('linear.spinner');
local commands = require('linear.commands')
local viewers = require('linear.viewers')

local Command = {}
Command.__index = Command

function Command:new(cmd, sub_cmd)
	self = setmetatable({}, Command)
	self.cmd = cmd
	self.sub_cmd = sub_cmd
	self.id = nil
	local texts = {
		issues = {
			create = "Creating an issue...",
			list = "Fetching issues...",
			update = "Updating an issue..",
			delete = "Deleting an issue..",
		},
	}
	self.text = texts[cmd][sub_cmd]
	self.command = commands[cmd][sub_cmd]:new(self)
	self.spinner = Spinner:new(function(text)
		vim.schedule(function()
			if self.id ~= nil then
				local result = vim.notify(self.text, vim.log.levels.INFO,
					{ title = "Linear.nvim", replace = { id = self.id }, icon = text })
				if result ~= nil then
					self.id = result.id
				end
			end
		end)
	end)
	return self
end

function Command:run()
	local ok, result = pcall(vim.notify, self.text, vim.log.levels.INFO,
		{ title = "Linear.nvim", icon = self.spinner:to_string() })
	if ok and result ~= nil then
		self.id = result.id
		self.spinner:start()
		self.command:run()
	end
end

function Command:success(data)
	self.spinner:stop()
	vim.notify("Done", vim.log.levels.INFO, { title = "Linear.nvim", replace = { id = self.id }, icon = "✓" })
	if (data ~= nil and data[self.cmd] ~= nil) then
		viewers[self.cmd][self.sub_cmd]:new(data[self.cmd])
	end
end

function Command:failed()
	self.spinner:stop()
	vim.notify("Failed", vim.log.levels.ERROR, { title = "Linear.nvim", replace = { id = self.id }, icon = "❗" })
end

return Command
