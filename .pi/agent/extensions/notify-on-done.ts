/**
 * Notify When Done
 *
 * Sends a notification when Pi has finished a run and is waiting for input.
 *
 * `agent_settled` is used instead of `agent_end`: it is the final, notification-only
 * boundary and fires only after retries, compaction, and queued follow-ups are done,
 * so a single notification is sent per settled run.
 *
 * Backends (override with `PI_NOTIFY_BACKEND`):
 *  - auto     (default): pick the best backend for the current environment
 *  - terminal: OSC 777 (Ghostty, iTerm2, WezTerm, rxvt) / OSC 99 (Kitty),
 *              wrapped in a tmux DCS passthrough when running inside tmux
 *  - desktop:  notify-send (Linux/BSD) or a PowerShell toast (Windows Terminal)
 *  - bell:     BEL character
 *  - off:      disabled
 *
 * Set `PI_NOTIFY_MIN_MS` to skip notifications for runs shorter than that many
 * milliseconds (useful to avoid a notification for every quick reply).
 */

import { execFile } from "node:child_process";
import { basename } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Backend = "auto" | "terminal" | "desktop" | "bell" | "off";

const BACKEND = (process.env.PI_NOTIFY_BACKEND ?? "auto") as Backend;
const MIN_DURATION_MS = Number(process.env.PI_NOTIFY_MIN_MS ?? 0);

function write(sequence: string): void {
	process.stdout.write(sequence);
}

/** tmux only forwards DCS-wrapped sequences by default; ESC inside must be doubled. */
function tmuxPassthrough(sequence: string): string {
	return `\x1bPtmux;\x1b${sequence}\x1b\\`;
}

function emit(sequence: string): void {
	write(process.env.TMUX ? tmuxPassthrough(sequence) : sequence);
}

function notifyOsc777(title: string, body: string): void {
	emit(`\x1b]777;notify;${title};${body}\x07`);
}

function notifyOsc99(title: string, body: string): void {
	// Kitty OSC 99: i=notification id, d=0 means not done yet, p=body for the second part.
	emit(`\x1b]99;i=1:d=0;${title}\x1b\\`);
	emit(`\x1b]99;i=1:p=body;${body}\x1b\\`);
}

function notifyDesktop(title: string, body: string): void {
	execFile("notify-send", ["-a", "Pi", "-u", "normal", title, body], (error) => {
		if (error) process.stderr.write(`[notify-on-done] notify-send failed: ${error.message}\n`);
	});
}

function windowsToastScript(title: string, body: string): string {
	const type = "Windows.UI.Notifications";
	const mgr = `[${type}.ToastNotificationManager, ${type}, ContentType = WindowsRuntime]`;
	const template = `[${type}.ToastTemplateType]::ToastText01`;
	const toast = `[${type}.ToastNotification]::new($xml)`;
	return [
		`${mgr} > $null`,
		`$xml = [${type}.ToastNotificationManager]::GetTemplateContent(${template})`,
		`$xml.GetElementsByTagName('text')[0].AppendChild($xml.CreateTextNode('${body}')) > $null`,
		`[${type}.ToastNotificationManager]::CreateToastNotifier('${title}').Show(${toast})`,
	].join("; ");
}

function notifyWindows(title: string, body: string): void {
	execFile("powershell.exe", ["-NoProfile", "-Command", windowsToastScript(title, body)], (error) => {
		if (error) process.stderr.write(`[notify-on-done] Windows toast failed: ${error.message}\n`);
	});
}

function isKitty(): boolean {
	return Boolean(process.env.KITTY_WINDOW_ID) || process.env.TERM?.includes("kitty") === true;
}

function isKnownTerminal(): boolean {
	const program = process.env.TERM_PROGRAM ?? "";
	if (/ghostty|wezterm|iterm|apple_terminal|rxvt/i.test(program)) return true;
	const term = process.env.TERM ?? "";
	return /ghostty|wezterm|rxvt/i.test(term);
}

function hasDesktopSession(): boolean {
	return Boolean(process.env.DISPLAY || process.env.WAYLAND_DISPLAY);
}

function deliverAuto(title: string, body: string): void {
	if (process.env.WT_SESSION) return notifyWindows(title, body);
	if (isKitty()) return notifyOsc99(title, body);
	if (isKnownTerminal()) return notifyOsc777(title, body);
	// Inside tmux we cannot see the outer terminal's identity; OSC 777 is the
	// common denominator for modern terminals (Ghostty, WezTerm, iTerm2).
	if (process.env.TMUX) return notifyOsc777(title, body);
	if (process.platform !== "win32" && hasDesktopSession()) return notifyDesktop(title, body);
	write("\x07");
}

function deliver(title: string, body: string): void {
	switch (BACKEND) {
		case "off":
			return;
		case "bell":
			return write("\x07");
		case "terminal":
			return isKitty() ? notifyOsc99(title, body) : notifyOsc777(title, body);
		case "desktop":
			return process.env.WT_SESSION ? notifyWindows(title, body) : notifyDesktop(title, body);
		default:
			return deliverAuto(title, body);
	}
}

export default function notifyOnDone(pi: ExtensionAPI) {
	let runStartedAt = 0;

	pi.on("agent_start", async () => {
		runStartedAt = Date.now();
	});

	pi.on("agent_settled", async (event, ctx) => {
		if (BACKEND === "off") return;
		// Escape sequences and toasts belong to the interactive TUI only; in
		// print/JSON/RPC modes stdout carries machine-readable output.
		if (ctx.mode !== "tui") return;
		if (MIN_DURATION_MS > 0 && Date.now() - runStartedAt < MIN_DURATION_MS) return;

		const project = basename(ctx.cwd) || ctx.cwd;
		const body = event.aborted ? `Stopped · ${project}` : `Ready for input · ${project}`;
		deliver("Pi", body);
	});
}
