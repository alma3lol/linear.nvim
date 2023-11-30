import { LinearClient } from "@linear/sdk";
import { Command } from "commander";
import { checkApiKey, renderLabel, renderTeam, renderUser } from "..";

export const createLabel = new Command("create")
	.requiredOption("-n, --name <name>", "Label's name")
	.option("-c, --color <color>", "Label's color")
	.option("-d, --description <description>", "Label's description")
	.option("-t, --teamId <teamId>", "Label's teamId")
	.option("-p, --parentId <parentId>", "Label's parentId")
	.description("Create a label")
	.action(async (options, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const result = await client.createIssueLabel({
			name: options.name,
			color: options.color,
			description: options.description,
			teamId: options.teamId,
			parentId: options.parentId,
		});
		const label = await result.issueLabel;
		if (!result.success || !label) {
			console.error("Failed creating the label");
			process.exit(1);
		}
		if (json) {
			console.log(
				JSON.stringify({
					id: label.id,
					name: label.name,
					description: label.description,
					color: label.color,
					creator: await renderUser(label.creator),
					team: await renderTeam(label.team),
					parent: await renderLabel(label.parent),
				})
			);
		}
	});
