import { LinearClient } from "@linear/sdk";
import { Command } from "commander";
import { checkApiKey } from "..";

export const listTeams = new Command("list")
	.description("List teams")
	.action(async (__, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const teams = await client.teams();
		if (json) {
			console.log(
				JSON.stringify({
					teams: await Promise.all(
						teams.nodes.map(async (team) => ({
							id: team.id,
							name: team.name,
							description: team.description,
							color: team.color,
							private: team.private,
							key: team.key,
						}))
					),
				})
			);
		}
	});
