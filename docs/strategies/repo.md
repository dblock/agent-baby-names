# Repo

`repo`, the default strategy, names a session after the Git repository it runs in, such as `hello-world` for a session in `~/source/hello-world/master/lib`. It asks no model, keeps no cache, and has no options.

```json
{
  "strategy": "repo"
}
```

The name is the last part of the checkout's `origin` remote URL, else its `upstream` remote URL, so checkouts and worktrees of a repository share its name whatever their folders are called. A checkout without a remote is named after its top folder, and a folder outside a checkout after itself. A session that already has a name is left alone.

## Examples

The prompt does not matter to `repo`, only the folder the session runs in.

| Working folder                                     | Name          |
| -------------------------------------------------- | ------------- |
| `~/source/hello-world/master/lib`                  | `hello-world` |
| `~/source/hello-world/implementation`, a worktree  | `hello-world` |
| `~/source/hello-world/octocat-hello-world`, a fork | `hello-world` |
| `~/source/notes`, a checkout without a remote      | `notes`       |
| `~/Downloads`, not a checkout                      | `Downloads`   |
| `/` or the home folder                             | none          |
