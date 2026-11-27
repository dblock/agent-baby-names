# GitHub Repos

`github-repos` names a session `<emoji> <repo>` after one of your GitHub repositories, including forks and repositories you have not cloned, such as `🧪 testlanes` for "speed up the testlanes CI", or `<emoji> <topic>` otherwise. It needs the [GitHub CLI](https://cli.github.com/), logged in with `gh auth login`.

## Repositories

The strategy lists your repositories with `gh repo list`, adding those of the accounts in `owners`, and caches the list for a day. A repository named in the prompt wins over the Git checkout the session runs in, and names shorter than three characters are ignored. Otherwise, the host's small model writes a short topic from the prompt. Listing hundreds of repositories takes a few seconds, once a day. If `gh` is missing or fails, the strategy keeps the list it has. Emojis work as in [`git-clones`](git-clones.md#emojis).

## Options

```json
{
  "strategy": "github-repos",
  "strategies": {
    "github-repos": { "owners": ["mongoid"] }
  }
}
```

| Option   | Default | Description                                                   |
| -------- | ------- | ------------------------------------------------------------- |
| `owners` | none    | Organizations or users whose repositories to add to your own. |

It takes the `pins`, `cache`, `ask`, `claude_model`, and `copilot_model` options of [`git-clones`](git-clones.md#options).
