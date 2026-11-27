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

With the default `repo` strategy, a session is named after the Git repository it runs in, such as `hello-world` for a session in `~/source/hello-world/master`. Combine other strategies for names such as `👋 hello-world` or `🔊 loud-laptop-fan` that a model helps choose.

### Examples

<https://github.com/user-attachments/assets/a650ddbc-4070-443d-9946-073782ed6852>

<sub>Claude Code with `["git-clone", "topic", "emoji"]`: each prompt names a checkout, which becomes the session's name with an emoji.</sub>

<https://github.com/user-attachments/assets/18a7e7e6-b3e5-4364-b250-1a5111a56ed8>

<sub>Copilot CLI with `["git-clone", "topic", "emoji"]`: each new session renames itself, then starts on its prompt.</sub>

## Configuration

Configuration is optional and lives in `~/.config/agent-baby-names/config.json`, or under `XDG_CONFIG_HOME` when it is set. Set `AGENT_BABY_NAMES_CONFIG` to use another file.

```json
{
  "strategy": ["git-clone", "topic", "emoji"],
  "strategies": {
    "git-clone": { "root": "~/code" }
  }
}
```

`strategy` is a strategy or a list of strategies, each the name of a built-in strategy below or the path to [your own strategy](docs/strategies/custom.md), any executable that prints a name. The strategies run in order, and each one gets the name so far and keeps it or changes it, so this example names a session after a checkout, else a topic, and then puts an emoji before the name. `strategies` holds each strategy's options under its name.

### Built-in Strategies

- [`repo`](docs/strategies/repo.md), the default, names a session after the Git repository it runs in.
- [`git-clone`](docs/strategies/git-clone.md) names a session after a Git checkout that the prompt mentions or that it runs in.
- [`github-repo`](docs/strategies/github-repo.md) names a session after one of your GitHub repositories that the prompt mentions, or the checkout it runs in.
- [`topic`](docs/strategies/topic.md) names a session after a short topic that a model writes from the prompt.
- [`prompt`](docs/strategies/prompt.md) names a session after a model's answer to a question that you write, which can change the name so far.
- [`emoji`](docs/strategies/emoji.md) puts an emoji before or after the name, such as `👋 hello-world`.
- [`directory`](docs/strategies/directory.md) names a session after the folder it runs in.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md), [DESIGN](DESIGN.md), [RELEASING](RELEASING.md), [CHANGELOG](CHANGELOG.md), and [AGENTS](AGENTS.md).

## License

MIT, see the [license](LICENSE).
