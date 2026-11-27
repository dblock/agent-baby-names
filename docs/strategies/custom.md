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

It reads `{"prompt", "cwd", "host"}` JSON on standard input, where `host` is `claude` or `copilot`, receives its options as JSON in `AGENT_BABY_NAMES_OPTIONS`, and prints a name, or nothing to leave the session unnamed. Only the first line counts. A non-zero exit status leaves the session unnamed.

```sh
#!/bin/bash
# Names a session after the first three words of its prompt.
jq -r '.prompt' | tr -s '[:space:]' ' ' | cut -d' ' -f1-3
```

See the [directory strategy](../../strategies/directory/strategy.sh) for an example that reads its options.
