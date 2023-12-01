local Spinner = require('linear.spinner');
local commands = require('linear.commands')
local viewers = require('linear.viewers')

local Command = {}
Command.__index = Command

function Command:new(cmd, sub_cmd, cb)
	self = setmetatable({}, Command)
	self.cmd = cmd
	self.sub_cmd = sub_cmd
	self.cb = cb
	self.id = nil
	local texts = {
		issues = {
			create = "Creating an issue...",
			list = "Fetching issues...",
			update = "Updating an issue..",
			delete = "Deleting an issue..",
		},
		states = {
			create = "Creating a state...",
			list = "Fetching states...",
			update = "Updating a state..",
			delete = "Deleting a state..",
		},
		teams = {
			create = "Creating a team...",
			list = "Fetching teams...",
			update = "Updating a team..",
			delete = "Deleting a team..",
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

function Command:show_spinner()
	local ok, result = pcall(vim.notify, self.text, vim.log.levels.INFO,
		{ title = "Linear.nvim", icon = self.spinner:to_string() })
	if ok and result ~= nil then
		self.id = result.id
		self.spinner:start()
	end
end

function Command:run()
	if self.sub_cmd == "list" then
		self:show_spinner()
	end
	self.command:run()
end

function Command:success(data)
	self.spinner:stop()
	vim.notify("Done", vim.log.levels.INFO, { title = "Linear.nvim", replace = { id = self.id }, icon = "✓" })
	if (data ~= nil and data[self.cmd] ~= nil) then
		viewers[self.cmd][self.sub_cmd]:new(data[self.cmd], self.cb)
	end
end

function Command:failed()
	self.spinner:stop()
	vim.notify(self.text, vim.log.levels.ERROR, { title = "Linear.nvim", replace = { id = self.id }, icon = "" })
end

return Command
