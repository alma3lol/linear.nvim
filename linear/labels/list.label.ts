import { LinearClient } from "@linear/sdk";
import { Command } from "commander";
import { checkApiKey, renderLabel, renderTeam, renderUser } from "..";

export const listLabels = new Command("list")
	.description("List labels")
	.action(async (__, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const labels = await client.issueLabels();
		if (json) {
			console.log(
				JSON.stringify({
					labels: await Promise.all(
						labels.nodes.map(async (label) => ({
							id: label.id,
							name: label.name,
							description: label.description,
							color: label.color,
							creator: await renderUser(label.creator),
							team: await renderTeam(label.team),
							parent: await renderLabel(label.parent),
						}))
					),
				})
			);
		}
	});
