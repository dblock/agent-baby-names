# Repo

`repo`, the default strategy, names a session after the Git repository it runs in, such as `testlanes` for a session in `~/source/testlanes/master/lib`. It asks no model, keeps no cache, and has no options.

| Working folder                                | Name        |
| --------------------------------------------- | ----------- |
| `~/source/testlanes/master/lib`               | `testlanes` |
| `~/source/testlanes/dblock-testlanes`         | `testlanes` |
| `~/source/notes`, a checkout without a remote | `notes`     |
| `~/Downloads`, not a checkout                 | `Downloads` |
| `/` or the home folder                        | none        |

The name is the last part of the checkout's `origin` remote URL, else its `upstream` remote URL, so checkouts and worktrees of a repository share its name whatever their folders are called. A checkout without a remote is named after its top folder, and a folder outside a checkout after itself.

To name a session after the folder only, use [`directory`](directory.md). For emojis, and for repositories that the prompt mentions, use [`git-clones`](git-clones.md) or [`github-repos`](github-repos.md).
