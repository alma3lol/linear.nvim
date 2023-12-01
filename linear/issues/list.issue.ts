import { LinearClient } from "@linear/sdk";
import { Command } from "commander";
import { checkApiKey, renderProject, renderTeam, renderUser } from "..";

export const listIssues = new Command("list")
	.description("List issues")
	.option("-t, --teamId <teamId>", "Issues' teamId")
	.option("-s, --stateId <stateId>", "Issues' stateId")
	.option(
		"-S, --states <states>",
		"Issues states' names to filter with (comma seperated)"
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
							state: options.stateId
								? {
										id: { eq: options.state },
								  }
								: options.states
								  ? {
											name: {
												in: options.states
													.split(",")
													.map((state: string) =>
														state.trim()
													),
											},
								    }
								  : {},
						},
				  }
				: {}
		);
		if (json) {
			console.log(
				JSON.stringify({
					issues: await Promise.all(
						issues.nodes.map(async (issue) => {
							let state = undefined;
							if (issue.state) {
								const s = await issue.state;
								state = {
									id: s.id,
									name: s.name,
									type: s.type,
									color: s.color,
									team: await renderTeam(s.team),
								};
							}
							const labels = await issue.labels();
							return {
								id: issue.id,
								title: issue.title,
								identifier: issue.identifier,
								url: issue.url,
								state,
								assignee: await renderUser(issue.assignee),
								priority: issue.priorityLabel,
								project: await renderProject(issue.project),
								labels: labels.nodes.map((label) => ({
									id: label.id,
									name: label.name,
									color: label.color,
								})),
							};
						})
					),
				})
			);
		}
	});
