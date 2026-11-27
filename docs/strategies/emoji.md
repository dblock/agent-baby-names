# Emoji

`emoji` puts an emoji before the name that the strategies before it gave, such as `🧪 testlanes`, so put it last:

```json
{
  "strategy": ["repo", "emoji"],
  "strategies": {
    "emoji": { "pins": "~/.config/agent-baby-names/emojis.txt" }
  }
}
```

Pins choose an emoji yourself: a file of `<name> <emoji>` lines, using the lowercase-hyphenated name, such as `mongoid-fulltext 🍃`. The bundled [`emojis.txt`](../../strategies/emoji/emojis.txt) pins `🏠` for `dotfiles`. For other names, the host's small model picks an emoji once, and it is remembered in the cache. Without a pin or an answer from the model, the emoji is 💬. Without a name, `emoji` names nothing.

## Options

| Option          | Default                                           | Description                                                                                                                                               |
| --------------- | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pins`          | [`emojis.txt`](../../strategies/emoji/emojis.txt) | A file of `<name> <emoji>` lines that choose a name's emoji.                                                                                              |
| `cache`         | `~/.cache/agent-baby-names`                       | Where the emojis the model picked are kept.                                                                                                               |
| `ask`           | `auto`                                            | The model to ask: `auto` for the host's small model, `none` to ask nothing, or a command that reads the question on standard input and prints the answer. |
| `claude_model`  | `haiku`                                           | The model that `auto` asks in Claude Code.                                                                                                                |
| `copilot_model` | `claude-haiku-4.5`                                | The model that `auto` asks in Copilot CLI.                                                                                                                |
