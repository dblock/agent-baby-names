# Topic

`topic` names a session after a short topic that the host's small model writes from the prompt, such as `loud-laptop-fan` for "why is my laptop fan loud". It leaves a session that an earlier strategy named alone, so put it after the strategies that find a repository:

```json
{
  "strategy": ["git-clones", "topic", "emoji"]
}
```

The topic is two to four lowercase words joined by hyphens, from the first 1000 characters of the prompt. An empty prompt, or a model that gives no answer, leaves the session unnamed.

## Options

| Option          | Default                     | Description                                                                                                                                               |
| --------------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ask`           | `auto`                      | The model to ask: `auto` for the host's small model, `none` to ask nothing, or a command that reads the question on standard input and prints the answer. |
| `claude_model`  | `haiku`                     | The model that `auto` asks in Claude Code.                                                                                                                |
| `copilot_model` | `claude-haiku-4.5`          | The model that `auto` asks in Copilot CLI.                                                                                                                |
| `cache`         | `~/.cache/agent-baby-names` | The folder that the model runs in.                                                                                                                        |
