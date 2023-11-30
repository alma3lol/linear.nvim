import { LinearClient } from "@linear/sdk";
import { Command, Option } from "commander";
import { checkApiKey } from "..";

export const listStates = new Command("list")
	.description("List states")
	.addOption(
		new Option("-t, --team [teamId]", "Team ID to fetch states from")
	)
	.addOption(
		new Option("-s, --state [state]", "State to match when fetching states")
	)
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
							type: options.type
								? {
										eq: options.state,
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
