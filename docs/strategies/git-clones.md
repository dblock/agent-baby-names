# Git Clones

`git-clones` names a session after a Git checkout that the prompt mentions, such as `hello-world` for "speed up the hello-world CI", or else the checkout it runs in.

```json
{
  "strategy": "git-clones",
  "strategies": {
    "git-clones": { "root": "~/code" }
  }
}
```

## Repositories

The strategy finds the Git checkouts in the root folder, up to three folders deep, and names each after its `origin` remote, else its `upstream` remote, else its folder. So `~/source/hello-world/master`, a fork checkout in `~/source/hello-world/octocat-hello-world`, and a worktree in `~/source/hello-world/implementation` are all `hello-world`. A repository named in the prompt wins over the checkout the session runs in, which may be anywhere, and names shorter than three characters are ignored. Names are lowercase words joined by hyphens, such as `acme-widgets`. The list is cached, and rebuilt when the root folder changes or after a day. Outside a checkout, a prompt that names no repository leaves the session unnamed. A session that already has a name is left alone.

## Examples

With checkouts of `hello-world`, `dotfiles`, and `acme_widgets` in `~/source`:

| Prompt                        | Working folder                    | Name           |
| ----------------------------- | --------------------------------- | -------------- |
| "speed up the hello-world CI" | `~`                               | `hello-world`  |
| "add an alias to my dotfiles" | `~/source/hello-world/master`     | `dotfiles`     |
| "fix the build"               | `~/source/hello-world/master/lib` | `hello-world`  |
| "release acme_widgets"        | `~`                               | `acme-widgets` |
| "why is my laptop fan loud"   | `~`                               | none           |

## Options

| Option  | Default                     | Description                                                                                                                                                                                                                        |
| ------- | --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `root`  | `~/source`                  | Where checkouts live.                                                                                                                                                                                                              |
| `cache` | `~/.cache/agent-baby-names` | The folder for `git-clones.txt`, the list of checkouts, which can be shared with other strategies. The list is rebuilt after a day, or sooner when a folder is added to or removed from `root`; delete the file to rebuild it now. |
