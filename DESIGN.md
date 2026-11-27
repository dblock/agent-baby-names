# Design

Agent Baby Names is a plugin for Claude Code and GitHub Copilot CLI that names a new session on its first prompt. It is written in Bash and uses jq, because a plugin is installed by cloning its repository and running its hook commands directly, with no build step, and both hosts already hand hooks JSON.

## Layers

- **Host adapters** (`hosts/claude`, `hosts/copilot`) are the hooks each host runs. They read the host's hook input, leave sessions that already have a name alone, ask the core for a name, and reply in the host's format.
- **The core** (`bin/agent-baby-names`) reads the configuration, checks every configured strategy, runs them in order, and prints the name they leave.
- **Strategies** (`strategies/<name>`) decide the name. A strategy is any executable that reads `{"prompt", "cwd", "host", "name"}` JSON on standard input, where `name` is the name so far, receives its own options as JSON in `AGENT_BABY_NAMES_OPTIONS`, and prints a new name, or nothing to keep the name so far. `repo`, the default, uses the name of the Git repository the session runs in, with no model, cache, or options, so a new install works anywhere without sending prompts to a model. `git-clone` and `github-repo` find a repository that the prompt mentions and share `lib/repos`; `topic` asks a model for a topic; `prompt` asks a model a question that the user writes as a template; `emoji` puts an emoji before the name; `directory` is a minimal example that uses the folder name. The bundled strategies that read options source `lib/strategy`.

## Combining Strategies

`strategy` is one strategy or a list, run as a pipeline: each strategy gets the name the ones before it left. Strategies that find a name, such as `repo`, `git-clone`, `github-repo`, `topic`, and `directory`, keep a name they are given, so a list tries them in order until one finds a name; a strategy that decorates a name, such as `emoji`, changes it. One rule covers both kinds, so finding a name and adding an emoji are separate strategies that you can replace one at a time, rather than every repository strategy also asking for topics and emojis. The core checks every strategy before running any, so a typo in the list fails before a model is asked, and the first failing strategy leaves the session unnamed.

## Configuration

Configuration lives in `~/.config/agent-baby-names/config.json`, under `XDG_CONFIG_HOME` when it is set, and `AGENT_BABY_NAMES_CONFIG` points to another file. A missing file means defaults. It is a file rather than environment variables because Claude Code sessions dispatched from its agent view do not inherit the shell environment.

```json
{
  "strategy": ["git-clone", "topic", "emoji"],
  "strategies": {
    "git-clone": { "root": "~/source" },
    "topic": { "ask": "auto" }
  }
}
```

Each strategy is a bundled strategy name or a path to an executable, and its options are under that name in `strategies`. With `"ask": "auto"`, a strategy that needs a model asks the host that ran the hook, using its small model; `"none"` turns that off, and any other value is run as a command that reads the question on standard input.

## Plugin Manifests

Claude Code reads `.claude-plugin/plugin.json`. The repository declares no marketplace of its own; the `dblock` marketplace in [dblock/agent-marketplace](https://github.com/dblock/agent-marketplace) lists it from GitHub, so one marketplace can hold several plugins without their names colliding. GitHub Copilot CLI reads `.github/plugin/plugin.json`, which it finds before `.claude-plugin/plugin.json`, so each host gets its own hook format.

## Hosts

Claude Code passes `session_title` in the hook input, so its adapter names a session only while that is empty, and replies with `sessionTitle`. Copilot CLI passes no name and its hooks cannot set one, so its adapter remembers each session ID it has seen in `~/.copilot/agent-baby-names/sessions`, forgetting them after 90 days, and on a session's first prompt replies with `additionalContext` asking the agent to call `rename_session`.

Each host finds its hook through the plugin root. Claude Code expands `${CLAUDE_PLUGIN_ROOT}` in the hook command. Copilot CLI runs hooks in the plugin root but expands `${PLUGIN_ROOT}` only in a hook's `env`, so the registration maps it to `AGENT_BABY_NAMES_PLUGIN_ROOT`. Copilot CLI loads plugin hooks only in trusted folders. Both hosts read that marketplace and install the plugin from this repository's default branch.

## Failure

A hook never fails a prompt. The core reports configuration and strategy errors on standard error with a non-zero status, so they show when it runs by hand, and the adapters discard them, print nothing, and exit 0.

## Asking a Model

`lib/ask` asks the host's small model in a subprocess: `claude -p` with hooks, tools, and session saving turned off, or `copilot -p` in a throwaway `COPILOT_HOME` with no tools. It runs in the cache folder with `AGENT_BABY_NAMES_NESTED` set, and the core names nothing while that is set, so the nested session never names itself or recurses.

## Repository Strategies

`git-clone` and `github-repo` differ only in where their list of repository names comes from; `lib/repos` matches the prompt against the list and falls back to the checkout that holds the working directory. A checkout is named after its `origin` remote, else `upstream`, else its folder, so the clones, forks, and worktrees of one repository share a name without guessing from folder names. `git-clone` reads Git configuration and never uses the network, and rebuilds its list when the root folder changes or after a day. `github-repo` asks `gh`, which takes seconds for hundreds of repositories, so its list is cached for a day, keyed by `owners`, and a failed listing keeps the old one. `emoji` asks for a name's emoji once and caches it by the lowercase-hyphenated name; pins override the cache.
