# Your Own Strategy

A strategy is any executable. Point `strategy` to its path, and put its options under the same path in `strategies`:

```json
{
  "strategy": "~/bin/name-session",
  "strategies": {
    "~/bin/name-session": { "style": "short" }
  }
}
```

It reads `{"prompt", "cwd", "host", "name"}` JSON on standard input, where `host` is `claude` or `copilot` and `name` is the name that the strategies before it in the list gave, or empty. It receives its options as JSON in `AGENT_BABY_NAMES_OPTIONS`, and prints a new name, or nothing to keep that one. Only the first line counts. A non-zero exit status leaves the session unnamed. A strategy that finds a name usually leaves an existing one alone, and one that decorates a name, like [`emoji`](emoji.md), changes it.

```sh
#!/bin/bash
# Names a session after the first three words of its prompt, unless it already has a name.
jq -r 'select(.name == "") | .prompt' | tr -s '[:space:]' ' ' | cut -d' ' -f1-3
```

See the [directory strategy](../../strategies/directory/strategy.sh) for an example that reads its options.
