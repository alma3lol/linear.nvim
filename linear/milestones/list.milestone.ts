import { LinearClient } from "@linear/sdk";
import { Command } from "commander";
import { checkApiKey, renderProject } from "..";

export const listMilestones = new Command("list")
	.description("List milestones")
	.option("-p, --projectId <projectId>", "Milestone's projectId")
	.action(async (options, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		if (options && options.projectId) {
			const project = await client.project(options.projectId);
			const milestones = await project.projectMilestones();
			if (json) {
				console.log(
					JSON.stringify({
						milestones: await Promise.all(
							milestones.nodes.map(async (milestone) => ({
								id: milestone.id,
								name: milestone.name,
								description: milestone.description,
								targetDate: milestone.targetDate,
								project: await renderProject(milestone.project),
							}))
						),
					})
				);
			}
			return;
		}
		const milestones = await client.projectMilestones();
		if (json) {
			console.log(
				JSON.stringify({
					milestones: await Promise.all(
						milestones.nodes.map(async (milestone) => ({
							id: milestone.id,
							name: milestone.name,
							description: milestone.description,
							targetDate: milestone.targetDate,
							project: await renderProject(milestone.project),
						}))
					),
				})
			);
		}
	});
