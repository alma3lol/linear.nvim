import { LinearClient, Project } from "@linear/sdk";
import { Command, Option } from "commander";
import { checkApiKey, renderProject, renderUser } from "..";

export const createMilestone = new Command("create")
	.requiredOption("-t, --teamIds <teamIds>", "Milestone teams")
	.requiredOption("-n, --name <name>", "Milestone name")
	.addOption(
		new Option("-s, --state <state>", "Milestone state")
			.default("backlog")
			.choices([
				"backlog",
				"planned",
				"started",
				"paused",
				"completed",
				"canceled",
			])
	)
	.option("-c, --color <color>", "Milestone color")
	.option("-d, --description <description>", "Milestone description")
	.option("-l, --leadIds <leadId>", "Milestone leads (comma sperated)")
	.option("-m, --memberIds <memberId>", "Milestone members (comma sperated)")
	.option("--startDate <startDate>", "Milestone start date")
	.option("--targetDate <targetDate>", "Milestone target date")
	.description("Create an milestone")
	.action(async (options, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const result = await client.createProjectMilestone({
			description: options.description,
			name: options.name,
			projectId: options.projectId,
			targetDate: options.targetDate,
		});
		const project = await client.project(options.projectId);
		const milestones = await project.projectMilestones();
		const milestone = milestones.nodes.find((m) => m.name === options.name);
		if (!result.success || !milestone) {
			console.error("Failed creating the milestone");
			process.exit(1);
		}
		if (json) {
			console.log(
				JSON.stringify({
					id: milestone.id,
					name: milestone.name,
					description: milestone.description,
					targetDate: milestone.targetDate,
					project: await renderProject(milestone.project),
				})
			);
		}
	});
