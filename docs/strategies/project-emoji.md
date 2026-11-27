# Project Emoji

`project-emoji`, the default strategy, names a session `<emoji> <project>`, such as `🧪 testlanes` for "speed up the testlanes CI", or `<emoji> <topic>` outside a project, such as `🔊 loud-laptop-fan` for "why is my laptop fan loud".

## Projects

Projects are the folders in the root folder and in its organization folders, so `~/source/testlanes/master` and `~/source/mongoid/mongoid_fulltext` are the projects `testlanes` and `mongoid-fulltext`. A project named in the prompt wins over the one the session runs in, and names shorter than three characters are ignored. Outside a project, the host's small model writes a short topic from the prompt.

## Emojis

The host's small model picks a project's emoji once, and it is remembered in the cache. Pins choose an emoji yourself; the bundled [`emojis.txt`](../../strategies/project-emoji/emojis.txt) pins `🏠` for `dotfiles`.

## Options

```json
{
  "strategies": {
    "project-emoji": { "root": "~/code", "pins": "~/.config/agent-baby-names/emojis.txt" }
  }
}
```

| Option          | Default                                                   | Description                                                                                                                                               |
| --------------- | --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `root`          | `~/source`                                                | Where projects live.                                                                                                                                      |
| `pins`          | [`emojis.txt`](../../strategies/project-emoji/emojis.txt) | A file of `<project> <emoji>` lines that choose a project's emoji.                                                                                        |
| `cache`         | `~/.cache/agent-baby-names`                               | Where the project list and the emojis the model picked are kept.                                                                                          |
| `ask`           | `auto`                                                    | The model to ask: `auto` for the host's small model, `none` to ask nothing, or a command that reads the question on standard input and prints the answer. |
| `claude_model`  | `haiku`                                                   | The model that `auto` asks in Claude Code.                                                                                                                |
| `copilot_model` | `claude-haiku-4.5`                                        | The model that `auto` asks in Copilot CLI.                                                                                                                |

With `"ask": "none"`, projects get the 🗂️ emoji unless they are pinned, and other sessions are not named.
