# Topic

`topic` names a session after a short topic that the host's small model writes from the prompt, such as `loud-laptop-fan` for "why is my laptop fan loud".

```json
{
  "strategy": "topic"
}
```

The topic is two to four lowercase words joined by hyphens, from the first 1000 characters of the prompt. An empty prompt, or a model that gives no answer, leaves the session unnamed. A session that already has a name is left alone.

## Options

| Option  | Default                                              | Description                                                                                                                                               |
| ------- | ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ask`   | `auto`                                               | The model to ask: `auto` for the host's small model, `none` to ask nothing, or a command that reads the question on standard input and prints the answer. |
| `model` | `{"claude": "haiku", "copilot": "claude-haiku-4.5"}` | The model that `auto` asks for each host: `claude` in Claude Code and `copilot` in Copilot CLI. Set one host to keep the other's default.                 |
| `cache` | `~/.cache/agent-baby-names`                          | The folder that the model runs in, which can be shared with other strategies. `topic` stores nothing there, and every new session asks the model again.   |

## Examples

The model writes each topic, so yours may differ. The folder the session runs in does not matter.

| Prompt                      | Name                  |
| --------------------------- | --------------------- |
| "why is my laptop fan loud" | `loud-laptop-fan`     |
| "plan a weekend in Lisbon"  | `lisbon-weekend-trip` |
| "fix the flaky login test"  | `flaky-login-test`    |
| An empty prompt             | none                  |
