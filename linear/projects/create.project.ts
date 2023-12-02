import { LinearClient } from "@linear/sdk";
import { Command, Option } from "commander";
import { checkApiKey, renderUser } from "..";

export const createProject = new Command("create")
	.requiredOption("-t, --teamIds <teamIds>", "Project's teams")
	.requiredOption("-n, --name <name>", "Project's name")
	.addOption(
		new Option("-s, --state <state>", "Project's state")
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
	.option("-c, --color <color>", "Project's color")
	.option("-d, --description <description>", "Project's description")
	.option("-l, --leadIds <leadId>", "Project's leads (comma sperated)")
	.option("-m, --memberIds <memberId>", "Project's members (comma sperated)")
	.option("--startDate <startDate>", "Project's start date")
	.option("--targetDate <targetDate>", "Project's target date")
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
