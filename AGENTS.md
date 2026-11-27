# Working on Agent Baby Names

Read [CONTRIBUTING](CONTRIBUTING.md) and [DESIGN](DESIGN.md) first.

## Project

Agent Baby Names is a Claude Code and GitHub Copilot CLI plugin that names a new session on its first prompt, with a configurable naming strategy. Non-goals: other agents, renaming sessions that already have a name, and plugin settings screens.

- `bin/agent-baby-names` is the core; `hosts/` holds the per-host hooks, `strategies/` the bundled strategies, `lib/strategy` the input, options, and model helpers that the bundled strategies share, `lib/repos` the code that the `git-clone` and `github-repo` strategies share, and `lib/ask` the helper that asks a host's model.
- `hooks/hooks.json` registers the Claude Code hook and `hooks/copilot.json` the Copilot CLI hook.
- `.claude-plugin/` holds the Claude Code manifest and marketplace, and `.github/plugin/` the Copilot CLI manifest.
- `test/` holds the Bats tests. The test and lint tools are npm development dependencies, apart from ShellCheck, which is installed on its own; the plugin itself never needs Node.js.

## Invariants

- Runtime code is Bash and jq only, plus Git and the GitHub CLI for the strategies that use them, with no build step; plugins run straight from a clone. Node.js is for development tools only.
- A hook never fails the user's prompt: on any error it prints nothing and exits 0.
- Never rename a session that already has a name.
- Configuration comes from the config file, not the environment, apart from `AGENT_BABY_NAMES_CONFIG`.
- Keep the version identical in `bin/agent-baby-names` and the three manifests; a test checks it.
- Tests must not use the network, a real model, or the user's configuration.
- End help text, errors, and other messages with a period.
- Do not weaken lint settings or add broad exceptions; scope any exception narrowly with a reason.

## Validation

Run all of these and fix what they report before every commit and push:

```sh
npm test
npm run lint
npm run package
```

Keep line coverage of the scripts close to complete; measure it with `npm run coverage`, which needs Docker.

## Conventions

- Branch as `dblock/<topic>`, keep one commit per PR, stack dependent PRs and register them with `gh stack link`, and use rebase merges only. Never force-push `master`; update your own PR branches with `--force-with-lease`.
- Add a linked CHANGELOG line under the Next section for each change; predict the PR number from the repository's latest issue or PR and verify it after opening the PR.
- Use Title Case for Markdown headings and workflow, job, and step names; keep Markdown paragraphs on one line.
- Prefer current stable releases of tools and GitHub Actions.
- Include an AI co-author trailer in AI-assisted commits, and disclose AI authorship in PR descriptions and comments.
- Never push tags, create releases, or change repository settings without explicit maintainer authorization. See [RELEASING](RELEASING.md).
