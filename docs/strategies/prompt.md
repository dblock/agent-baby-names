# Prompt

`prompt` asks the host's small model a question that you write, and names the session after its answer. List it after other strategies to change the name they give, or on its own to name a session from its prompt.

```json
{
  "strategy": "prompt",
  "strategies": {
    "prompt": { "template": "Write a short name for a session about: {prompt}. Output only the name." }
  }
}
```

The template's placeholders become the session's details: `{prompt}` is the first 1000 characters of its prompt, `{name}` the name so far, `{cwd}` the folder it runs in, and `{host}` `claude` or `copilot`. The name is the first line of the answer, without the spaces, quotes, or backticks around it, and at most 80 characters. Without a template, or without an answer, the name so far is kept, so a strategy listed before `prompt` still names the session. Unlike `topic`, `prompt` also runs when a session already has a name so far, so the template decides whether to keep it; a session already named in the host is still left alone.

## Options

| Option     | Default                                              | Description                                                                                                                                               |
| ---------- | ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `template` | none                                                 | The question to ask, with `{prompt}`, `{name}`, `{cwd}`, and `{host}` placeholders.                                                                       |
| `ask`      | `auto`                                               | The model to ask: `auto` for the host's small model, `none` to ask nothing, or a command that reads the question on standard input and prints the answer. |
| `model`    | `{"claude": "haiku", "copilot": "claude-haiku-4.5"}` | The model that `auto` asks for each host: `claude` in Claude Code and `copilot` in Copilot CLI. Set one host to keep the other's default.                 |
| `cache`    | `~/.cache/agent-baby-names`                          | The folder that the model runs in, which can be shared with other strategies. `prompt` stores nothing there, and every new session asks the model again.  |

## Examples

The model writes each answer, so yours may differ.

| Template                                                                                                       | Prompt                       | Name so far   | Name               |
| -------------------------------------------------------------------------------------------------------------- | ---------------------------- | ------------- | ------------------ |
| "Write a short name for a session about: {prompt}. Output only the name."                                      | "why is my laptop fan loud"  | none          | `Loud Laptop Fan`  |
| "If {prompt} mentions a ticket number, output {name} prefixed with it, such as 42-{name}; else output {name}." | "fix ticket 42 in the login" | `hello-world` | `42-hello-world`   |
| "Translate {name} to French. Output only the translation."                                                     | any                          | `hello-world` | `bonjour-le-monde` |
| "Output {name} in Title Case."                                                                                 | any                          | `hello-world` | `Hello World`      |
