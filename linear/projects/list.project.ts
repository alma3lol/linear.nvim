import { LinearClient } from "@linear/sdk";
import { Command } from "commander";
import { checkApiKey, renderUser } from "..";

export const listProjects = new Command("list")
	.description("List projects")
	.action(async (__, cmd: Command) => {
		if (cmd.parent === null) return;
		const apiKey = cmd.parent.getOptionValue("apiKey");
		const json = cmd.parent.getOptionValue("json");
		checkApiKey(apiKey);
		const client = new LinearClient({
			apiKey,
		});
		const projects = await client.projects();
		if (json) {
			console.log(
				JSON.stringify({
					projects: await Promise.all(
						projects.nodes.map(async (project) => ({
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
						}))
					),
				})
			);
		}
	});
