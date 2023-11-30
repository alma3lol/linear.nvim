import { LinearClient } from "@linear/sdk";
import { Command, Option } from "commander";
import { checkApiKey, renderUser } from "..";

export const createProject = new Command("create")
	.requiredOption("-t, --teamIds <teamIds>", "Project teams")
	.requiredOption("-n, --name <name>", "Project name")
	.addOption(
		new Option("-s, --state <state>", "Project state")
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
	.option("-c, --color <color>", "Project color")
	.option("-d, --description <description>", "Project description")
	.option("-l, --leadIds <leadId>", "Project leads (comma sperated)")
	.option("-m, --memberIds <memberId>", "Project members (comma sperated)")
	.option("--startDate <startDate>", "Project start date")
	.option("--targetDate <targetDate>", "Project target date")
	.description("Create an project")
	.action(async (options, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const result = await client.createProject({
			description: options.description,
			name: options.name,
			teamIds: options.teamIds
				.split(",")
				.map((teamId: string) => teamId.trim()),
			color: options.color,
			leadId: options.leadId,
			state: options.state,
			memberIds: options.memberIds
				.split(",")
				.map((memberId: string) => memberId.trim()),
			startDate: options.startDate,
			targetDate: options.targetDate,
		});
		const project = await result.project;
		if (!result.success || !project) {
			console.error("Failed creating the project");
			process.exit(1);
		}
		if (json) {
			console.log(
				JSON.stringify({
					id: project.id,
					name: project.name,
					description: project.description,
					color: project.color,
					lead: await renderUser(project.lead),
					creator: await renderUser(project.creator),
					state: project.state,
					startDate: project.startDate,
					targetDate: project.targetDate,
					scope: project.scope,
					progress: project.progress,
					slugId: project.slugId,
					url: project.url,
				})
			);
		}
	});
