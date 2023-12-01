import { LinearClient } from "@linear/sdk";
import { Command } from "commander";
import { checkApiKey, renderProject, renderUser } from "..";

export const createIssue = new Command("create")
	.requiredOption("-t, --team <teamId>", "Issue's teamId")
	.requiredOption("--title <title>", "Issue's title")
	.requiredOption("-s, --state <state>", "Issue's state")
	.option("-a, --assignee <assignee>", "Issue's assignee")
	.option("-p, --priority <priority>", "Issue's priority")
	.option("-P, --projectId <projectId>", "Issue's projectId")
	.option("-m, --milestoneId <milestoneId>", "Issue's milestoneId")
	.description("Create an issue")
	.action(async (options, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const result = await client.createIssue({
			teamId: options.teamId,
			title: options.title,
			stateId: options.state,
			assigneeId: options.assignee,
			priority: options.priority,
			projectId: options.projectId,
			projectMilestoneId: options.milestoneId,
		});
		const issue = await result.issue;
		if (!result.success || !issue) {
			console.error("Failed creating the issue");
			process.exit(1);
		}
		const labels = await issue.labels();
		if (json) {
			console.log(
				JSON.stringify({
					id: issue.id,
					title: issue.title,
					identifier: issue.identifier,
					url: issue.url,
					state: (await issue.state)?.name || "",
					assignee: await renderUser(issue.assignee),
					priority: issue.priorityLabel,
					project: await renderProject(issue.project),
					labels: labels.nodes.map((label) => ({
						id: label.id,
						name: label.name,
						color: label.color,
					})),
				})
			);
		}
	});
