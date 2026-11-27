# Git Clones

`git-clones` names a session after a Git checkout that the prompt mentions, such as `testlanes` for "speed up the testlanes CI", or else the checkout it runs in. Outside a checkout it leaves the session for the next strategy, such as [`topic`](topic.md), and [`emoji`](emoji.md) adds an emoji:

```json
{
  "strategy": ["git-clones", "topic", "emoji"],
  "strategies": {
    "git-clones": { "root": "~/code" }
  }
}
```

## Repositories

The strategy finds the Git checkouts in the root folder, up to three folders deep, and names each after its `origin` remote, else its `upstream` remote, else its folder. So `~/source/testlanes/master`, a fork checkout in `~/source/testlanes/dblock-testlanes`, and a worktree in `~/source/testlanes/implementation` are all `testlanes`. A repository named in the prompt wins over the checkout the session runs in, which may be anywhere, and names shorter than three characters are ignored. Names are lowercase words joined by hyphens, such as `mongoid-fulltext`. The list is cached, and rebuilt when the root folder changes or after a day. A session that an earlier strategy named is left alone.

## Options

| Option  | Default                     | Description                        |
| ------- | --------------------------- | ---------------------------------- |
| `root`  | `~/source`                  | Where checkouts live.              |
| `cache` | `~/.cache/agent-baby-names` | Where the repository list is kept. |
