local Spinner = require('linear.spinner');
local commands = require('linear.commands')
local pickers = require('linear.pickers')

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
		users = {
			create = "Creating a user...",
			list = "Fetching users...",
			update = "Updating a user..",
			delete = "Deleting a user..",
		},
		projects = {
			create = "Creating a project...",
			list = "Fetching projects...",
			update = "Updating a project..",
			delete = "Deleting a project..",
		},
		labels = {
			create = "Creating a label...",
			list = "Fetching labels...",
			update = "Updating a label..",
			delete = "Deleting a label..",
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
		local results = {}
		if self.sub_cmd == "list" then
			if self.cmd ~= "teams" and self.cmd ~= "users" and self.cmd ~= "projects" and self.cmd ~= "labels" then
				table.insert(results, { id = "FILTER", title = "Filter", name = "Filter" })
			end
		end
		for _, entry in ipairs(data[self.cmd]) do
			table.insert(results, entry)
		end
		pickers[self.cmd][self.sub_cmd]:new(results, self.cb)
	end
end

function Command:failed()
	self.spinner:stop()
	vim.notify(self.text, vim.log.levels.ERROR, { title = "Linear.nvim", replace = { id = self.id }, icon = "" })
	if type(self.cb) == "function" then
		self.cb()
	end
end

return Command
