# Directory

`directory` names a session after the folder it runs in, such as `my-project` for `~/source/my-project`. It asks no model, and leaves a session that runs in `/` unnamed.

## Examples

`directory` uses the folder's own name, so checkouts and worktrees of one repository get different names.

| Working folder                        | `"directory"`    | With `"prefix": "📁 "` |
| ------------------------------------- | ---------------- | ---------------------- |
| `~/source/my-project`                 | `my-project`     | `📁 my-project`        |
| `~/source/hello-world/master`         | `master`         | `📁 master`            |
| `~/source/hello-world/implementation` | `implementation` | `📁 implementation`    |
| `/`                                   | none             | none                   |

## Options

```json
{
  "strategy": "directory",
  "strategies": {
    "directory": { "prefix": "📁 " }
  }
}
```

| Option   | Default | Description                  |
| -------- | ------- | ---------------------------- |
| `prefix` | none    | Text to put before the name. |

Its [source](../../strategies/directory/strategy.sh) is a short example for [writing your own strategy](custom.md).
