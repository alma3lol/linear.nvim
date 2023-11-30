import { LinearClient } from "@linear/sdk";
import { Command, Option } from "commander";
import { checkApiKey, renderUser } from "..";

export const listIssues = new Command("list")
	.description("List issues")
	.addOption(
		new Option("-t, --team [teamId]", "Team ID to fetch issues from")
	)
	.addOption(
		new Option("-s, --state [state]", "State to match when fetching issues")
	)
	.action(async (options, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const issues = await client.issues(
			options
				? {
						filter: {
							team: options.teamId
								? {
										id: { eq: options.teamId },
								  }
								: undefined,
							state: options.state
								? {
										id: { eq: options.state },
								  }
								: undefined,
						},
				  }
				: {}
		);
		if (json) {
			console.log(
				JSON.stringify({
					issues: await Promise.all(
						issues.nodes.map(async (issue) => {
							let state = "";
							if (issue.state) {
								const s = await issue.state;
								state = s.name;
							}
							return {
								id: issue.id,
								title: issue.title,
								state,
								assignee: await renderUser(issue.assignee),
							};
						})
					),
				})
			);
		}
	});
