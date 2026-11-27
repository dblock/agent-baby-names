# GitHub Repos

`github-repos` names a session after one of your GitHub repositories that the prompt mentions, including forks and repositories you have not cloned, such as `testlanes` for "speed up the testlanes CI", or else the Git checkout it runs in. It needs the [GitHub CLI](https://cli.github.com/), logged in with `gh auth login`. Combine it with [`topic`](topic.md) and [`emoji`](emoji.md) as with [`git-clones`](git-clones.md).

```json
{
  "strategy": ["github-repos", "topic", "emoji"],
  "strategies": {
    "github-repos": { "owners": ["mongoid"] }
  }
}
```

## Repositories

The strategy lists your repositories with `gh repo list`, adding those of the accounts in `owners`, and caches the list for a day. A repository named in the prompt wins over the checkout the session runs in, and names shorter than three characters are ignored. Listing hundreds of repositories takes a few seconds, once a day. If `gh` is missing or fails, the strategy keeps the list it has. A session that an earlier strategy named is left alone, without calling `gh`.

## Options

| Option   | Default                     | Description                                                   |
| -------- | --------------------------- | ------------------------------------------------------------- |
| `owners` | none                        | Organizations or users whose repositories to add to your own. |
| `cache`  | `~/.cache/agent-baby-names` | Where the repository list is kept.                            |
