# Emoji

`emoji` puts an emoji before the name a session already has, such as `👋 hello-world` for `hello-world`. It names nothing on its own, so list it after a strategy that gives a name, as described in [Configuration](../../README.md#configuration).

```json
{
  "strategies": {
    "emoji": { "pins": "~/.config/agent-baby-names/emojis.txt" }
  }
}
```

Pins choose an emoji yourself: a file of `<name> <emoji>` lines, using the lowercase-hyphenated name, such as `acme-widgets 🧩`. The bundled [`emojis.txt`](../../strategies/emoji/emojis.txt) pins `🏠` for `dotfiles`. For other names, the host's small model picks an emoji once, and it is remembered in the cache. Without a pin or an answer from the model, the emoji is 💬. Without a name, `emoji` names nothing.

## Examples

The model picks each emoji once, so yours may differ, apart from the pinned 🏠 for `dotfiles`.

| Name so far        | Name                 |
| ------------------ | -------------------- |
| `hello-world`      | `👋 hello-world`     |
| `dotfiles`, pinned | `🏠 dotfiles`        |
| `acme-widgets`     | `🧩 acme-widgets`    |
| `loud-laptop-fan`  | `🔊 loud-laptop-fan` |
| `Downloads`        | `📥 Downloads`       |
| none               | none                 |

With `"ask": "none"`, every name without a pin gets 💬, such as `💬 hello-world`.

## Options

| Option          | Default                                           | Description                                                                                                                                                                                                                                                               |
| --------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pins`          | [`emojis.txt`](../../strategies/emoji/emojis.txt) | A file of `<name> <emoji>` lines that choose a name's emoji.                                                                                                                                                                                                              |
| `cache`         | `~/.cache/agent-baby-names`                       | The folder for `emojis.txt`, the emojis the model picked, one `<name> <emoji>` line each, which can be shared with other strategies. The model also runs in this folder. Picks never expire; delete a line, or the file, for a new pick, or pin an emoji to override one. |
| `ask`           | `auto`                                            | The model to ask: `auto` for the host's small model, `none` to ask nothing, or a command that reads the question on standard input and prints the answer.                                                                                                                 |
| `claude_model`  | `haiku`                                           | The model that `auto` asks in Claude Code.                                                                                                                                                                                                                                |
| `copilot_model` | `claude-haiku-4.5`                                | The model that `auto` asks in Copilot CLI.                                                                                                                                                                                                                                |
