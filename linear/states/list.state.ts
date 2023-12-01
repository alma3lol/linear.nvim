import { LinearClient } from "@linear/sdk";
import { Command } from "commander";
import { checkApiKey } from "..";

export const listStates = new Command("list")
	.description("List states")
	.option("-t, --teamId <teamId>", "State's teamId")
	.option("-n, --name <name>", "State's name")
	.option("-T, --types <types>", "State's types (comma seperated)")
	.action(async (options, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const states = await client.workflowStates(
			options
				? {
						filter: {
							team: options.teamId
								? {
										id: { eq: options.teamId },
								  }
								: undefined,
							name: options.name
								? {
										eq: options.name,
								  }
								: undefined,
							type: options.types
								? {
										in: options.types
											.split(",")
											.map((type: string) => type.trim()),
								  }
								: undefined,
						},
				  }
				: {}
		);
		if (json) {
			console.log(
				JSON.stringify({
					states: await Promise.all(
						states.nodes.map(async (state) => ({
							id: state.id,
							name: state.name,
							type: state.type,
							color: state.color,
							team: (await state.team)?.name || "",
						}))
					),
				})
			);
		}
	});
