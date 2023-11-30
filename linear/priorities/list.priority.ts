import { LinearClient } from "@linear/sdk";
import { Command } from "commander";
import { checkApiKey } from "..";

export const listPriorities = new Command("list")
	.description("List priorities")
	.action(async (__, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const priorities = await client.issuePriorityValues;
		if (json) {
			console.log(
				JSON.stringify({
					priorities: await Promise.all(
						priorities.map(async (priority) => ({
							label: priority.label,
							priority: priority.priority,
						}))
					),
				})
			);
		}
	});
