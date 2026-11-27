# Design

Agent Baby Names is a plugin for Claude Code and GitHub Copilot CLI that names a new session on its first prompt. It is written in Bash and uses jq, because a plugin is installed by cloning its repository and running its hook commands directly, with no build step, and both hosts already hand hooks JSON.

## Layers

- **Host adapters** (`hosts/claude`, `hosts/copilot`) are the hooks each host runs. They read the host's hook input, leave sessions that already have a name alone, ask the core for a name, and reply in the host's format.
- **The core** (`bin/agent-baby-names`) reads the configuration, runs the selected strategy, and prints the name it returns.
- **Strategies** (`strategies/<name>`) decide the name. A strategy is any executable that reads `{"prompt", "cwd", "host"}` JSON on standard input, receives its own options as JSON in `AGENT_BABY_NAMES_OPTIONS`, and prints one name, or nothing to leave the session unnamed. `project-emoji`, the default, names a session `<emoji> <project>`; `directory` is a minimal example that uses the folder name.

## Configuration

Configuration lives in `~/.config/agent-baby-names/config.json`, under `XDG_CONFIG_HOME` when it is set, and `AGENT_BABY_NAMES_CONFIG` points to another file. A missing file means defaults. It is a file rather than environment variables because Claude Code sessions dispatched from its agent view do not inherit the shell environment.

```json
{
  "strategy": "project-emoji",
  "strategies": {
    "project-emoji": { "root": "~/source", "ask": "auto" }
  }
}
```

`strategy` is a bundled strategy name or a path to an executable. With `"ask": "auto"`, a strategy that needs a model asks the host that ran the hook, using its small model; `"none"` turns that off, and any other value is run as a command that reads the question on standard input.

## Plugin Manifests

Claude Code reads `.claude-plugin/plugin.json`, and `.claude-plugin/marketplace.json` makes the repository its own one-plugin marketplace. GitHub Copilot CLI reads `.github/plugin/plugin.json`, which it finds before `.claude-plugin/plugin.json`, so each host gets its own hook format.

## Status

This is the scaffold: the manifests, the core's `--version` and `--help`, tests, and lint. The adapters, strategies, and configuration above are not implemented yet.
