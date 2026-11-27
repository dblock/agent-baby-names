# Git Clone

`git-clone` names a session after a Git checkout that the prompt mentions, such as `hello-world` for "speed up the hello-world CI", or else the checkout it runs in.

```json
{
  "strategy": "git-clone",
  "strategies": {
    "git-clone": { "root": "~/code" }
  }
}
```

With a `root`, the strategy finds the Git checkouts in that folder, up to three folders deep, and names each after its `origin` remote, else its `upstream` remote, else its folder. So `~/source/hello-world/master`, a fork checkout in `~/source/hello-world/octocat-hello-world`, and a worktree in `~/source/hello-world/implementation` are all `hello-world`. A repository named in the prompt wins over the checkout the session runs in, which may be anywhere, and names shorter than three characters are ignored. Names are lowercase words joined by hyphens, such as `acme-widgets`. The list is cached, and rebuilt when the root folder changes or after a day. Without a `root`, only the checkout the session runs in counts, and no list is kept. Outside a checkout, a prompt that names no repository leaves the session unnamed. A session that already has a name is left alone.

## Options

| Option  | Default                     | Description                                                                                                                                                                                                                       |
| ------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `root`  | none                        | Where checkouts live; without it, only the working directory's checkout counts.                                                                                                                                                   |
| `cache` | `~/.cache/agent-baby-names` | The folder for `git-clone.txt`, the list of checkouts, which can be shared with other strategies. The list is rebuilt after a day, or sooner when a folder is added to or removed from `root`; delete the file to rebuild it now. |

## Examples

With `root` set to `~/source` and checkouts of `hello-world`, `dotfiles`, and `acme_widgets` in it:

| Prompt                        | Working folder                    | Name           |
| ----------------------------- | --------------------------------- | -------------- |
| "speed up the hello-world CI" | `~`                               | `hello-world`  |
| "add an alias to my dotfiles" | `~/source/hello-world/master`     | `dotfiles`     |
| "fix the build"               | `~/source/hello-world/master/lib` | `hello-world`  |
| "release acme_widgets"        | `~`                               | `acme-widgets` |
| "why is my laptop fan loud"   | `~`                               | none           |
