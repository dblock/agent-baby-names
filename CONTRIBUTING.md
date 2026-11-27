# Contributing

Read [DESIGN](DESIGN.md) for the intended behavior before changing it.

## Setup and Validation

The plugin itself needs only Bash, [jq](https://jqlang.org/), and Git. Development uses Node.js (the version in `.nvmrc`) for the test and lint tools, which install from `package-lock.json`, plus [ShellCheck](https://www.shellcheck.net/) on your `PATH` for the shell lint, such as from `brew install shellcheck`, and Claude Code to validate the plugin manifests:

```sh
npm ci
```

Run every check before committing and pushing:

```sh
npm test
npm run lint
npm run package
```

- `npm test` runs the [Bats](https://github.com/bats-core/bats-core) tests.
- `npm run lint` runs [ShellCheck](https://www.shellcheck.net/) on the scripts and tests, [CSpell](https://cspell.org/) for spelling in the scripts and tests, which ESLint cannot parse, and [ESLint](https://eslint.org/) on the Markdown: `@eslint/markdown` and `eslint-plugin-markdown-preferences` for style and Title Case headings, `eslint-plugin-markdown-preferences-paragraph` for one-line paragraphs, `eslint-plugin-markdown-links` for missing local paths and anchors, `eslint-plugin-markdown-links-unlinked` so every page is reachable from the README, and `eslint-plugin-prose-spellcheck` for spelling, with the reviewed vocabulary in `.spellcheck.txt`, which CSpell shares through `cspell.config.yaml`. Fix misspellings and add only legitimate terms. CI installs the ShellCheck release pinned in `lint.yml`; update it when ShellCheck releases.
- `npm run package` validates the plugin manifests with `claude plugin validate`.

Measure line coverage with `npm run coverage`. It runs the tests under [kcov](https://github.com/SimonKagstrom/kcov) in the kcov Docker image, because kcov needs a newer Bash than macOS ships, writes an HTML report and `coverage/cobertura.xml` to `coverage/`, and prints each file's coverage. kcov reports continuation lines of multi-line commands and lines of embedded awk programs as missed. kcov cannot run on Windows, so it also reports the lines that run only in Git Bash as missed; in Git Bash, `npm run coverage:windows` runs the tests with Bash tracing and fails unless they run every line in an `if [[ "$OSTYPE" == msys* ...` block, and the Windows test job runs it instead of `npm test`.

`@eslint/markdown` stays on 8.x because `eslint-plugin-markdown-preferences` and `eslint-plugin-markdown-links` do not support 9.x yet.

## Tests

Tests live in `test/` and run with Bats against the real scripts in subprocesses. Add tests for new behavior, including errors and edge cases, and keep coverage close to complete. Tests must not reach the network, call a real model, or read your own configuration: `test/test_helper.bash` gives every test a temporary home, configuration, and cache, and puts stub `claude` and `copilot` commands first on `PATH`. To try the plugin in a real host, run `claude --plugin-dir .` or `copilot --plugin-dir .` in a trusted folder.

## Pull Requests

- Branch as `<github-login>/<topic>`, keep one commit per PR, and stack dependent PRs. Merges are rebase merges only.
- Update your own PR branches with `git push --force-with-lease`; never force-push `master`.
- Update the documentation the change affects and add a line under the Next section of the changelog for features, improvements, and fixes, in the form ``- [#123](https://github.com/dblock/agent-baby-names/pull/123): Description - [@login](https://github.com/login).``
- Use Title Case for Markdown headings and for workflow, job, and step names, and keep Markdown paragraphs on one line.
- Keep `Test` (Bats on Ubuntu, macOS, and Windows in Git Bash), `Lint`, and `Package` as separate workflows, with explicit `matrix.entry` combinations, least-privilege permissions, and a `concurrency` group that cancels a pull request's superseded runs but never `master`'s.

See [RELEASING](RELEASING.md) for releases.
