# Agent Baby Names

[![Test](https://github.com/dblock/agent-baby-names/actions/workflows/test.yml/badge.svg)](https://github.com/dblock/agent-baby-names/actions/workflows/test.yml) [![Lint](https://github.com/dblock/agent-baby-names/actions/workflows/lint.yml/badge.svg)](https://github.com/dblock/agent-baby-names/actions/workflows/lint.yml) [![Package](https://github.com/dblock/agent-baby-names/actions/workflows/package.yml/badge.svg)](https://github.com/dblock/agent-baby-names/actions/workflows/package.yml)

A plugin for Claude Code and GitHub Copilot CLI that names each new session after the project it works on, such as `📧 gmail-toggle`, using a naming strategy you can choose or write yourself.

## Installation

The plugin needs Bash and [jq](https://jqlang.org/). The repository is its own plugin marketplace.

### Claude Code

```sh
claude plugin marketplace add dblock/agent-baby-names
claude plugin install agent-baby-names@agent-baby-names
```

Claude Code 2.1.275 and later can also install it in one step from a session with `/plugin install agent-baby-names --marketplace dblock/agent-baby-names`.

### GitHub Copilot CLI

```sh
copilot plugin marketplace add dblock/agent-baby-names
copilot plugin install agent-baby-names@agent-baby-names
```

Copilot CLI runs plugin hooks only in folders you have trusted.

## Usage

Start a session and send a prompt. The first prompt of a session without a name gives it one, and later prompts and sessions you have named yourself are left alone.

With the default `git-clones` strategy, a session that mentions a repository you have cloned under `~/source`, or runs in a checkout, is named after it, such as `🧪 testlanes` for "speed up the testlanes CI". Other sessions get a short topic, such as `🔊 loud-laptop-fan` for "why is my laptop fan loud". The host's small model picks the emoji and writes the topic.

## Configuration

Configuration is optional and lives in `~/.config/agent-baby-names/config.json`, or under `XDG_CONFIG_HOME` when it is set. Set `AGENT_BABY_NAMES_CONFIG` to use another file.

```json
{
  "strategy": "git-clones",
  "strategies": {
    "git-clones": { "root": "~/code", "ask": "none" }
  }
}
```

`strategy` is the name of a bundled strategy or the path to your own, and `strategies` holds each strategy's options under its name.

### Strategies

- [`git-clones`](docs/strategies/git-clones.md), the default, names a session `<emoji> <repo>` after a Git checkout, or `<emoji> <topic>` otherwise.
- [`github-repos`](docs/strategies/github-repos.md) names a session `<emoji> <repo>` after one of your GitHub repositories, or `<emoji> <topic>` otherwise.
- [`directory`](docs/strategies/directory.md) names a session after the folder it runs in.
- [Your own strategy](docs/strategies/custom.md) is any executable that prints a name.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md), [DESIGN](DESIGN.md), [RELEASING](RELEASING.md), [CHANGELOG](CHANGELOG.md), and [AGENTS](AGENTS.md).

## License

MIT, see the [license](LICENSE).
