import { LinearClient } from "@linear/sdk";
import { Command, Option } from "commander";
import { checkApiKey } from "..";

export const createState = new Command("create")
	.requiredOption("-t, --team <teamId>", "Team ID to create state in")
	.requiredOption("-n, --name <name>", "State name")
	.requiredOption("-c, --color <color>", "State color")
	.addOption(
		new Option("--type <type>", "State type")
			.choices([
				"backlog",
				"unstarted",
				"started",
				"completed",
				"canceled",
			])
			.makeOptionMandatory(true)
	)
	.option("-a, --assignee [assignee]", "State's assignee")
	.description("Create an state")
	.action(async (options, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const result = await client.createWorkflowState({
			teamId: options.teamId,
			name: options.name,
			type: options.type,
			color: options.color,
		});
		const state = await result.workflowState;
		if (!result.success || !state) {
			console.error("Failed creating the state");
			process.exit(1);
		}
		if (json) {
			console.log(
				JSON.stringify({
					id: state.id,
					name: state.name,
					type: state.type,
					color: state.color,
					team: (await state.team)?.name || "",
				})
			);
		}
	});
