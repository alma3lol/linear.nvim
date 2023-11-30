import { LinearClient } from "@linear/sdk";
import { Command } from "commander";
import { checkApiKey } from "..";

export const createTeam = new Command("create")
	.requiredOption("-n, --name <name>", "Team name")
	.option("-c, --color <color>", "Team color")
	.description("Create an team")
	.action(async (options, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const result = await client.createTeam({
			name: options.name,
			color: options.color,
		});
		const team = await result.team;
		if (!result.success || !team) {
			console.error("Failed creating the team");
			process.exit(1);
		}
		if (json) {
			console.log(
				JSON.stringify({
					id: team.id,
					name: team.name,
					description: team.description,
					color: team.color,
					private: team.private,
					key: team.key,
				})
			);
		}
	});
