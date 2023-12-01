vim.api.nvim_create_user_command('Linear', function(opts)
	require('linear').command(opts)
end, {
	nargs = "+",
	complete = function(_, cmdLine)
		local args = vim.split(cmdLine, "%s+")
		local now = #args - 2;
		local cmds = {
			"issues",
			"projects",
			"milestones",
			"priorities",
			"labels",
			"teams",
			"states",
			"users",
		}
		table.sort(cmds)
		if now == 0 then
			return vim.tbl_filter(function(cmd)
				return vim.startswith(cmd, args[2])
			end, cmds)
		end
		if now == 1 then
			local sub_cmds = {
				"create",
				"list",
				"update",
				"delete",
			}
			table.sort(sub_cmds)
			return vim.tbl_filter(function(cmd)
				if args[2] == "priorities" or args[2] == "users" then
					if cmd ~= "list" then
						return false
					end
				end
				return vim.startswith(cmd, args[3])
			end, sub_cmds)
		end
		return {}
	end
})
