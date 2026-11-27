# GitHub Repo

`github-repo` names a session after one of your GitHub repositories that the prompt mentions, including forks and repositories you have not cloned, such as `hello-world` for "speed up the hello-world CI", or else the Git checkout it runs in. It needs the [GitHub CLI](https://cli.github.com/), logged in with `gh auth login`.

```json
{
  "strategy": "github-repo",
  "strategies": {
    "github-repo": { "owners": ["acme"] }
  }
}
```

## Repositories

The strategy lists your repositories with `gh repo list`, adding those of the accounts in `owners`, and caches the list for a day. A repository named in the prompt wins over the checkout the session runs in, and names shorter than three characters are ignored. Listing hundreds of repositories takes a few seconds, once a day. If `gh` is missing or fails, the strategy keeps the list it has. Outside a checkout, a prompt that names no repository leaves the session unnamed. A session that already has a name is left alone, without calling `gh`.

## Examples

With `"owners": ["acme"]`, where you own `hello-world` and a fork of `spoon-knife`, and `acme` owns `acme_widgets`, none of them cloned:

| Prompt                        | Working folder                | Name           |
| ----------------------------- | ----------------------------- | -------------- |
| "speed up the hello-world CI" | `~`                           | `hello-world`  |
| "rebase my spoon-knife fork"  | `~`                           | `spoon-knife`  |
| "release acme_widgets"        | `~`                           | `acme-widgets` |
| "fix the build"               | `~/source/hello-world/master` | `hello-world`  |
| "why is my laptop fan loud"   | `~`                           | none           |

## Options

| Option   | Default                     | Description                                                                                                                                                                                                                                                                       |
| -------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `owners` | none                        | Organizations or users whose repositories to add to your own.                                                                                                                                                                                                                     |
| `cache`  | `~/.cache/agent-baby-names` | The folder for `github-repo.txt`, the list of repositories, which can be shared with other strategies. With `owners`, the file is named after them, such as `github-repo-acme.txt`. The list is rebuilt after a day, and kept when `gh` fails; delete the file to rebuild it now. |
