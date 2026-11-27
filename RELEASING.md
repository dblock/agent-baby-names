# Releasing

Plugins install from this repository, so a release is a Git tag and a GitHub Release, not a registry upload. The manually run [Release](.github/workflows/release.yml) workflow makes both with [npm-package-release](https://github.com/dblock/npm-package-release), configured in `npr.config.js` to release without a registry. Releasing requires explicit maintainer authorization, and so does each setup step below.

## Setup

These are repository settings, made once by an administrator:

1. In **Settings → Environments**, create `release` and allow deployments only from `master`.
2. Let the workflow push to `master`: remove the pull request requirement from the `master` ruleset, keeping its force-push and deletion protections and no bypass actors. This lets every writer push to `master` directly, but ordinary changes still go through pull requests.

The workflow needs no npm account, token, or trusted publisher.

## Release

1. Make sure `master` is green and the `## <version> (Next)` section of the changelog describes the release.
2. Run the workflow from `master`, optionally with a numeric `version` other than the checked-in one:

   ```sh
   gh workflow run release.yml --repo dblock/agent-baby-names --ref master
   gh run list --repo dblock/agent-baby-names --workflow release.yml --limit 5
   ```

3. The workflow runs `npm test` and `npm run lint`, sets the version in `package.json`, `package-lock.json`, `bin/agent-baby-names`, and both plugin manifests, dates the changelog section, and pushes the `Prepare release <version>` commit and the `v<version>` tag to `master`. It then creates the GitHub Release with the changelog section and a zip of the plugin's files built by `npm run build`, checks that the plugin in the zip prints the released version, and pushes `Prepare next development iteration, <next version>` with the next patch version and a new Next section.
4. Check the run summary, the tag, and the GitHub Release.
5. Point the `agent-baby-names` plugin's `ref` in [dblock/agent-marketplace](https://github.com/dblock/agent-marketplace) at the new tag.
6. Install the tagged plugin in both hosts and confirm it names a new session.

The zip records the release's files, as a check of what was released; its files have no executable bits, so the hosts install the plugin from the tag instead.

## Recovery

Do not blindly rerun a failed release. Inspect the run's `npr-release` artifact and the tag, release, and `master` on GitHub, then follow npm-package-release's [recovery guide](https://github.com/dblock/npm-package-release/blob/v0.4.0/docs/usage.md#recovery). A rerun with the same inputs reuses what the failed run already pushed, and tags are never moved.
