# Git Clones

`git-clones` names a session `<emoji> <repo>` after a Git checkout, such as `🧪 testlanes` for "speed up the testlanes CI", or `<emoji> <topic>` otherwise, such as `🔊 loud-laptop-fan` for "why is my laptop fan loud".

## Repositories

The strategy finds the Git checkouts in the root folder, up to three folders deep, and names each after its `origin` remote, else its `upstream` remote, else its folder. So `~/source/testlanes/master`, a fork checkout in `~/source/testlanes/dblock-testlanes`, and a worktree in `~/source/testlanes/implementation` are all `testlanes`. A repository named in the prompt wins over the checkout the session runs in, which may be anywhere, and names shorter than three characters are ignored. Outside a checkout, the host's small model writes a short topic from the prompt. The list is cached, and rebuilt when the root folder changes or after a day.

## Emojis

The host's small model picks a repository's emoji once, and it is remembered in the cache. Pins choose an emoji yourself; the bundled [`emojis.txt`](../../lib/emojis.txt) pins `🏠` for `dotfiles`.

## Options

```json
{
  "strategy": "git-clones",
  "strategies": {
    "git-clones": { "root": "~/code", "pins": "~/.config/agent-baby-names/emojis.txt" }
  }
}
```

| Option          | Default                              | Description                                                                                                                                               |
| --------------- | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `root`          | `~/source`                           | Where checkouts live.                                                                                                                                     |
| `pins`          | [`emojis.txt`](../../lib/emojis.txt) | A file of `<repo> <emoji>` lines that choose a repository's emoji.                                                                                        |
| `cache`         | `~/.cache/agent-baby-names`          | Where the repository list and the emojis the model picked are kept.                                                                                       |
| `ask`           | `auto`                               | The model to ask: `auto` for the host's small model, `none` to ask nothing, or a command that reads the question on standard input and prints the answer. |
| `claude_model`  | `haiku`                              | The model that `auto` asks in Claude Code.                                                                                                                |
| `copilot_model` | `claude-haiku-4.5`                   | The model that `auto` asks in Copilot CLI.                                                                                                                |

With `"ask": "none"`, repositories get the 🗂️ emoji unless they are pinned, and other sessions are not named.
