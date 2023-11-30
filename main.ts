import { Command, Option } from "commander";
import {
	createLabel,
	createMilestone,
	createProject,
	createState,
	createTeam,
	listIssues,
	listLabels,
	listMilestones,
	listPriorities,
	listProjects,
	listStates,
	listTeams,
} from "./linear";

const program = new Command();
program.name("linear").description("Linear.app cli").version("1.0.0");
program
	.command("issues")
	.description("Manage issues")
	.addCommand(listIssues)
	.addCommand(createState);

program
	.command("states")
	.description("Manage states")
	.addCommand(listStates)
	.addCommand(createState);

program
	.command("teams")
	.description("Manage teams")
	.addCommand(listTeams)
	.addCommand(createTeam);

program
	.command("projects")
	.description("Manage projects")
	.addCommand(listProjects)
	.addCommand(createProject);

program
	.command("priorities")
	.description("Manage priorities")
	.addCommand(listPriorities);

program
	.command("labels")
	.description("Manage labels")
	.addCommand(listLabels)
	.addCommand(createLabel);

program
	.command("milestones")
	.description("Manage milestones")
	.addCommand(listMilestones)
	.addCommand(createMilestone);

program.commands.forEach((cmd) => {
	cmd.requiredOption(
		"--api-key <API_KEY>",
		"Linear API key",
		process.env.LINEAR_API_KEY
	);
	cmd.addOption(new Option("--json", "Print in JSON format"));
});
program.parse();
