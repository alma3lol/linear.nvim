import { LinearClient } from "@linear/sdk";
import { Command } from "commander";
import { checkApiKey } from "..";

export const listUsers = new Command("list")
	.description("List users")
	.action(async (__, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const users = await client.users();
		if (json) {
			console.log(
				JSON.stringify({
					users: await Promise.all(
						users.nodes.map(async (user) => {
							return {
								id: user.id,
								name: user.name,
								email: user.email,
								isMe: user.isMe,
								admin: user.admin,
								displayName: user.displayName,
							};
						})
					),
				})
			);
		}
	});
