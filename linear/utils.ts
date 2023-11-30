import {
	IssueLabel,
	LinearFetch,
	Organization,
	Project,
	Team,
	User,
} from "@linear/sdk";

export const renderUser = async (assignee?: LinearFetch<User>) => {
	if (!!!assignee) return undefined;
	try {
		const user = await assignee;
		return {
			id: user.id,
			name: user.name,
			email: user.email,
			isMe: user.isMe,
			admin: user.admin,
			displayName: user.displayName,
		};
	} catch (__) {
		return undefined;
	}
};

export const checkApiKey = (apiKey?: string) => {
	if (!!!apiKey) {
		console.error("No API key was provided!");
		process.exit(1);
	}
};

export const renderProject = async (project?: LinearFetch<Project>) => {
	if (!!!project) return undefined;
	try {
		const p = await project;
		return {
			id: p.id,
			name: p.name,
			description: p.description,
			state: p.state,
			startDate: p.startDate,
			targetDate: p.targetDate,
			color: p.color,
			scope: p.scope,
			progress: p.progress,
			slugId: p.slugId,
			url: p.url,
			creator: await renderUser(p.creator),
			lead: await renderUser(p.lead),
		};
	} catch (__) {
		return undefined;
	}
};

export const renderTeam = async (team?: LinearFetch<Team>) => {
	if (!!!team) return undefined;
	try {
		const t = await team;
		return {
			id: t.id,
			name: t.name,
			description: t.description,
			color: t.color,
			key: t.key,
			private: t.private,
			organization: await renderOrganization(t.organization),
		};
	} catch (__) {
		return undefined;
	}
};

export const renderOrganization = async (
	organization?: LinearFetch<Organization>
) => {
	if (!!!organization) return undefined;
	try {
		const o = await organization;
		return {
			id: o.id,
			name: o.name,
			urlKey: o.urlKey,
			logoUrl: o.logoUrl,
			samlEnabled: o.samlEnabled,
			scimEnabled: o.scimEnabled,
			subscription: o.subscription,
			allowMembersToInvite: o.allowMembersToInvite,
			userCount: o.userCount,
			trailEndsAt: o.trialEndsAt,
		};
	} catch (__) {
		return undefined;
	}
};

export const renderLabel = async (label?: LinearFetch<IssueLabel>) => {
	if (!!!label) return undefined;
	try {
		const l = await label;
		return {
			id: l.id,
			name: l.name,
			color: l.color,
			description: l.description,
			creator: await renderUser(l.creator),
			team: await renderTeam(l.team),
		};
	} catch (__) {
		return undefined;
	}
};
