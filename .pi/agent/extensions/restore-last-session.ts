/**
 * Restore Last Session Config
 *
 * Carries the model and thinking level of the most recent previous session over to
 * every new session, so a fresh session starts where the last one left off.
 *
 * Lookup order on `session_start` (reason "startup" or "new"):
 *  1. The latest session record in the current project's session directory.
 *  2. If there is no usable record, scan the session history under the agent
 *     directory, newest first, and take the latest model and thinking level found.
 *
 * Sessions opened with `--model` or `--thinking` are left alone, and resumed/forked
 * sessions are skipped because Pi restores their model itself.
 *
 * Load via `pi -e ./restore-last-session.ts` or install it in `<agent-dir>/extensions/`.
 */

import { readdirSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, resolve } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";

type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";

interface SessionPreset {
	provider?: string;
	modelId?: string;
	thinkingLevel?: ThinkingLevel;
}

interface RawEntry {
	type?: string;
	id?: string;
	parentId?: string | null;
	provider?: string;
	modelId?: string;
	thinkingLevel?: string;
}

const THINKING_LEVELS = new Set<string>(["off", "minimal", "low", "medium", "high", "xhigh", "max"]);
const MAX_SCAN_DEPTH = 3;

function isThinkingLevel(value: string): value is ThinkingLevel {
	return THINKING_LEVELS.has(value);
}

function expandHome(path: string): string {
	if (path === "~") return homedir();
	if (path.startsWith("~/")) return join(homedir(), path.slice(2));
	return path;
}

function resolveSessionDir(dir: string, cwd: string): string {
	const expanded = expandHome(dir);
	return isAbsolute(expanded) ? expanded : resolve(cwd, expanded);
}

/** Collect `*.jsonl` files below `dir`, up to MAX_SCAN_DEPTH, skipping duplicates. */
function collectSessionFiles(dir: string, files: string[], seen: Set<string>, depth = 0): void {
	let entries;
	try {
		entries = readdirSync(dir, { withFileTypes: true });
	} catch {
		return;
	}

	for (const entry of entries) {
		const path = join(dir, entry.name);
		if (entry.isDirectory()) {
			if (depth < MAX_SCAN_DEPTH) collectSessionFiles(path, files, seen, depth + 1);
		} else if (entry.isFile() && entry.name.endsWith(".jsonl")) {
			const key = resolve(path);
			if (!seen.has(key)) {
				seen.add(key);
				files.push(key);
			}
		}
	}
}

function sortByModifiedDesc(files: string[]): string[] {
	return files
		.map((file) => {
			try {
				return { file, mtime: statSync(file).mtimeMs };
			} catch {
				return { file, mtime: 0 };
			}
		})
		.sort((a, b) => b.mtime - a.mtime)
		.map((entry) => entry.file);
}

/** Read the model and thinking level recorded on the final branch of one session file. */
function readPresetFromFile(file: string): SessionPreset | null {
	let content: string;
	try {
		content = readFileSync(file, "utf8");
	} catch {
		return null;
	}

	const entries: RawEntry[] = [];
	for (const line of content.split("\n")) {
		const trimmed = line.trim();
		if (!trimmed) continue;
		try {
			const parsed = JSON.parse(trimmed) as RawEntry;
			if (parsed && typeof parsed === "object" && parsed.type !== "session") entries.push(parsed);
		} catch {
			// Ignore a truncated or corrupt trailing line.
		}
	}
	if (entries.length === 0) return null;

	// Follow the parent chain from the last entry so state on abandoned branches is ignored.
	const byId = new Map<string, RawEntry>();
	for (const entry of entries) {
		if (entry.id) byId.set(entry.id, entry);
	}

	const chain: RawEntry[] = [];
	let current: RawEntry | undefined = entries[entries.length - 1];
	const visited = new Set<string>();
	while (current) {
		chain.push(current);
		const parentId = current.parentId;
		if (!parentId || visited.has(parentId)) break;
		visited.add(parentId);
		current = byId.get(parentId);
	}

	const preset: SessionPreset = {};
	const takeModel = (entry: RawEntry) => {
		if (preset.provider !== undefined) return;
		if (entry.type !== "model_change") return;
		if (typeof entry.provider === "string" && typeof entry.modelId === "string") {
			preset.provider = entry.provider;
			preset.modelId = entry.modelId;
		}
	};
	const takeThinking = (entry: RawEntry) => {
		if (preset.thinkingLevel !== undefined) return;
		if (entry.type !== "thinking_level_change") return;
		if (typeof entry.thinkingLevel === "string" && isThinkingLevel(entry.thinkingLevel)) {
			preset.thinkingLevel = entry.thinkingLevel;
		}
	};

	for (const entry of chain) {
		takeModel(entry);
		takeThinking(entry);
	}
	// Older session formats may lack usable parent links; fall back to file order.
	if (preset.provider === undefined || preset.thinkingLevel === undefined) {
		for (let i = entries.length - 1; i >= 0; i--) {
			takeModel(entries[i]);
			takeThinking(entries[i]);
		}
	}

	return preset.provider !== undefined || preset.thinkingLevel !== undefined ? preset : null;
}

/**
 * Find the most recent model/thinking config:
 * current project's sessions first, then the whole session history.
 */
function findLastSessionPreset(ctx: ExtensionContext, pi: ExtensionAPI): SessionPreset | null {
	const result: SessionPreset = {};
	const currentFile = ctx.sessionManager.getSessionFile();
	const current = currentFile ? resolve(currentFile) : undefined;
	const seen = new Set<string>();

	const consume = (files: string[]): boolean => {
		for (const file of sortByModifiedDesc(files)) {
			if (current && file === current) continue;
			const preset = readPresetFromFile(file);
			if (!preset) continue;
			if (result.provider === undefined && preset.provider && preset.modelId) {
				result.provider = preset.provider;
				result.modelId = preset.modelId;
			}
			if (result.thinkingLevel === undefined && preset.thinkingLevel) {
				result.thinkingLevel = preset.thinkingLevel;
			}
			if (result.provider !== undefined && result.thinkingLevel !== undefined) return true;
		}
		return false;
	};

	// 1. Latest record in the session directory for this project.
	const projectFiles: string[] = [];
	collectSessionFiles(ctx.sessionManager.getSessionDir(), projectFiles, seen);
	if (consume(projectFiles)) return result;

	// 2. No usable record: scan the rest of the session history, newest first.
	const historyDirs = new Set<string>();
	const settings = pi.getSettings();
	if (settings.sessionDir) historyDirs.add(resolveSessionDir(settings.sessionDir, ctx.cwd));
	historyDirs.add(join(getAgentDir(), "sessions"));
	for (const dir of historyDirs) {
		const files: string[] = [];
		collectSessionFiles(dir, files, seen);
		if (consume(files)) break;
	}

	return result.provider !== undefined || result.thinkingLevel !== undefined ? result : null;
}

function hasCliArg(flag: string): boolean {
	return process.argv.some((arg) => arg === flag || arg.startsWith(`${flag}=`));
}

export default function restoreLastSessionConfig(pi: ExtensionAPI) {
	pi.on("session_start", async (event, ctx) => {
		if (event.reason !== "startup" && event.reason !== "new") return;

		const preset = findLastSessionPreset(ctx, pi);
		if (!preset) return;

		const applied: string[] = [];

		if (preset.provider && preset.modelId && !hasCliArg("--model")) {
			const currentModel = ctx.model;
			const alreadyActive = currentModel?.provider === preset.provider && currentModel.id === preset.modelId;
			if (!alreadyActive) {
				const model = ctx.modelRegistry.find(preset.provider, preset.modelId);
				if (model) {
					if (await pi.setModel(model)) {
						applied.push(`${model.provider}/${model.id}`);
					} else if (ctx.hasUI) {
						ctx.ui.notify(`Last session model ${preset.provider}/${preset.modelId} is not authenticated`, "warning");
					}
				}
			}
		}

		if (preset.thinkingLevel && !hasCliArg("--thinking") && pi.getThinkingLevel() !== preset.thinkingLevel) {
			pi.setThinkingLevel(preset.thinkingLevel);
			applied.push(`thinking ${preset.thinkingLevel}`);
		}

		if (applied.length > 0) {
			const message = `Restored from last session: ${applied.join(" · ")}`;
			if (ctx.hasUI) ctx.ui.notify(message, "info");
			console.log(`[restore-last-session] ${applied.join(", ")}`);
		}
	});
}
